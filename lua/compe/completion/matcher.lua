local Character = require'compe.completion.character'

local Matcher = {}

Matcher.WORD_BOUNDALY_ORDER_FACTOR = 1000

--- match
Matcher.match = function(context, source, history)
  local input = context:get_input(source:get_start_offset())

  -- filter
  local matches = {}
  for _, item in ipairs(source:get_items()) do
    local word = item.filter_text or item.original_word
    item.score = 0
    if #word >= #input then
      item.score = Matcher.score(input, word)
      item.exact = word == input
      if item.score >= 1 or #input == 0 then
        table.insert(matches, item)
      end
    end
  end

  -- sort
  if source:get_metadata().sort then
    table.sort(matches, function(item1, item2)
      return Matcher.compare(item1, item2, history)
    end)
  end

  return matches
end

--- score
--
-- ### The score
--
--   The `score` is `matched char count` generally.
--
--   But compe will fix the score with some of the below points so the actual score is not `matched char count`.
--
--   1. Word boundarly order
--
--     compe prefers the match that near by word-beggining.
--
--   2. Strict case
--
--     compe prefers strict match than ignorecase match.
--
--
-- ### Matching specs.
--
--   1. Prefix matching per word boundaly
--
--     `bora`     -> `border-radius` # imaginary score: 4
--      ^^~~          ^^     ~~
--
--   2. Try sequencial match first
--
--     `woroff`   -> `word_offset`   # imaginary score: 6
--      ^^^~~~        ^^^  ~~~
--
--     * The `woroff`'s second `o` should not match `word_offset`'s first `o`
--
--   3. Prefer early word boundaly
--
--     `call`     -> `call`          # imaginary score: 4.1
--      ^^^^          ^^^^
--     `call`     -> `condition_all` # imaginary score: 4
--      ^~~~          ^         ~~~
--
--   4. Prefer strict match
--
--     `Buffer`   -> `Buffer`        # imaginary score: 6.1
--      ^^^^^^        ^^^^^^
--     `buffer`   -> `Buffer`        # imaginary score: 6
--      ^^^^^^        ^^^^^^
--
--   5. Use remaining char for fuzzy match
--
--     `fmofy`    -> `fnamemodify`   # imaginary score: 1
--      ^~~~~         ^    ~~  ~~
--
Matcher.score = function(input, word)
  -- Empty input
  if #input == 0 or #input > #word then
    return 1
  end

  -- Check first char matching (special check for completion)
  if not Character.match(string.byte(input, 1), string.byte(word, 1)) then
    return 0
  end

  local input_bytes = { string.byte(input, 1, -1) }
  local word_bytes = { string.byte(word, 1, -1) }

  --- Gather matched regions
  local matches = {}
  local input_start_index = 0
  local input_end_index = 1
  local word_index = 1
  while input_end_index <= #input_bytes and word_index <= #word_bytes do
    local match = Matcher.find_match_region(input_bytes, input_start_index, input_end_index, word_bytes, word_index)
    if match then
      input_start_index = match.input_match_start
      input_end_index = match.input_match_end + 1
      word_index = Matcher.get_next_semantic_index(word_bytes, match.word_match_end)
      table.insert(matches, match)
    else
      word_index = Matcher.get_next_semantic_index(word_bytes, word_index)
    end
  end

  if #matches == 0 then
    return 0
  end

  -- Compute prefix match score
  local score = 0
  local input_char_map = {}
  for i, match in ipairs(matches) do
    local s = 0
    for i = match.input_match_start, match.input_match_end do
      if not input_char_map[i] then
        s = s + 1
        input_char_map[i] = true
      end
    end
    if s > 0 then
      score = score + (s * (1 + math.max(0, Matcher.WORD_BOUNDALY_ORDER_FACTOR - i) / Matcher.WORD_BOUNDALY_ORDER_FACTOR))
      score = score + (match.strict_match and 0.1 or 0)
    end
  end

  -- Check the word contains the remaining input. if not, it does not match.
  local last_match = matches[#matches]
  if last_match.input_match_end < #input_bytes then

    -- If input is remaining but all word consumed, it does not match.
    if last_match.word_match_end >= #word_bytes then
      return 0
    end

    for word_index = last_match.word_match_end + 1, #word_bytes do
      local word_offset = 0
      local input_index = last_match.input_match_end + 1
      while word_offset + word_index <= #word_bytes and input_index <= #input_bytes do
        if Character.match(word_bytes[word_index + word_offset], input_bytes[input_index]) then
          input_index = input_index + 1
        end
        word_offset = word_offset + 1
      end
      if input_index - 1 == #input_bytes then
        return score
      end
    end
    return 0
  end

  return score
end

--- find_match_region
Matcher.find_match_region = function(input_bytes, input_start_index, input_end_index, word_bytes, word_index)
  -- Datermine input position ( woroff -> word_offset )
  while input_start_index < input_end_index do
    if Character.match(input_bytes[input_end_index], word_bytes[word_index]) then
      break
    end
    input_end_index = input_end_index - 1
  end

  -- Can't datermine input position
  if input_start_index == input_end_index then
    return nil
  end

  local strict_match_count = 0
  local input_match_start = -1
  local input_index = input_end_index
  local word_offset = 0
  while input_index <= #input_bytes and word_index + word_offset <= #word_bytes do
    if Character.match(input_bytes[input_index], word_bytes[word_index + word_offset]) then
      -- Match start.
      if input_match_start == -1 then
        input_match_start = input_index
      end

      -- Increase strict_match_count
      if input_bytes[input_index] == word_bytes[word_index + word_offset] then
        strict_match_count = strict_match_count + 1
      end

      word_offset = word_offset + 1
    elseif input_match_start ~= -1 then
      -- Match end (partial region)
      return {
        input_match_start = input_match_start;
        input_match_end = input_index - 1;
        word_match_start = word_index;
        word_match_end = word_index + word_offset - 1;
        strict_match = strict_match_count == input_index - input_match_start;
      }
    end
    input_index = input_index + 1
  end

  -- Match end (whole region)
  if input_match_start ~= -1 then
    return {
      input_match_start = input_match_start;
      input_match_end = input_index - 1;
      word_match_start = word_index;
      word_match_end = word_index + word_offset - 1;
      strict_match = strict_match_count == input_index - input_match_start;
    }
  end

  return nil
end

--- get_next_semantic_index
Matcher.get_next_semantic_index = function(bytes, current_index)
  for i = current_index + 1, #bytes do
    if Matcher.is_semantic_index(bytes, i) then
      return i
    end
  end
  return #bytes + 1
end

--- is_semantic_index
Matcher.is_semantic_index = function(bytes, index)
  if index <= 1 then
    return true
  end
  if not Character.is_upper(bytes[index - 1]) and Character.is_upper(bytes[index]) then
    return true
  end
  if not Character.is_alpha(bytes[index - 1]) and Character.is_alpha(bytes[index]) then
    return true
  end
  return false
end

--- compare
Matcher.compare = function(item1, item2, history)
  if item1.priority ~= item2.priority then
    if item1.priority == nil then
      return false
    elseif item2.priority == nil then
      return true
    end
    return item1.priority > item2.priority
  end

  if item1.preselect ~= item2.preselect then
    return item1.preselect
  end

  if item1.asis ~= item2.asis then
    return item2.asis
  end

  if math.abs(item1.score - item2.score) ~= 0 then
    return item1.score > item2.score
  end

  local history_score1 = history[item1.abbr] or 0
  local history_score2 = history[item2.abbr] or 0
  if history_score1 ~= history_score2 then
    return history_score1 > history_score2
  end

  if item1.sort_text ~= nil and item2.sort_text ~= nil then
    if item1.sort_text ~= item2.sort_text then
      return item1.sort_text < item2.sort_text
    end
  end

  return nil
end

--- logger
Matcher.logger = function(word, expected)
  return function(value)
    if word == expected then
      print(vim.inspect(value))
    end
  end
end

--- bytes2string
Matcher.bytes2string = function(bytes)
  local s = ''
  for i = 1, #bytes do
    s = s .. string.char(bytes[i])
  end
  return s
end

return Matcher

