local Character = require'compe.utils.character'
local Config = require'compe.config'

local Matcher = {}

Matcher.WORD_BOUNDALY_ORDER_FACTOR = 5

--- match
Matcher.match = function(context, source)
  local input = context:get_input(source:get_start_offset())

  -- filter
  local matches = {}
  for i, item in ipairs(source.items) do
    local word = item.original_word
    if item.filter_text and Character.match(string.byte(input, 1, 1), string.byte(item.filter_text, 1, 1)) then
      word = item.filter_text
    end
    item.index = i
    item.score = 0
    item.fuzzy = false
    if #word >= #input then
      print(vim.inspect({
        input = input,
        word = word,
      }))
      local score, fuzzy = Matcher.score(input, word)
      item.score = score
      item.fuzzy = fuzzy
      if item.score >= 1 or #input == 0 then
        table.insert(matches, item)
      end
      print('pass')
      print('')
    end
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
--     `bora`         -> `border-radius` # imaginary score: 4
--      ^^~~              ^^     ~~
--
--   2. Try sequencial match first
--
--     `woroff`       -> `word_offset`   # imaginary score: 6
--      ^^^~~~            ^^^  ~~~
--
--     * The `woroff`'s second `o` should not match `word_offset`'s first `o`
--
--   3. Prefer early word boundaly
--
--     `call`         -> `call`          # imaginary score: 4.1
--      ^^^^              ^^^^
--     `call`         -> `condition_all` # imaginary score: 4
--      ^~~~              ^         ~~~
--
--   4. Prefer strict match
--
--     `Buffer`       -> `Buffer`        # imaginary score: 6.1
--      ^^^^^^            ^^^^^^
--     `buffer`       -> `Buffer`        # imaginary score: 6
--      ^^^^^^            ^^^^^^
--
--   5. Use remaining char for fuzzy match
--
--     `fmofy`        -> `fnamemodify`   # imaginary score: 1
--      ^~~~~             ^    ~~  ~~
--
--   6. Avoid unexpected match detection
--
--     `candlesingle` -> candle#accept#single
--      ^^^^^^~~~~~~     ^^^^^^        ~~~~~~
--
--      * The `accept`'s `a` should not match to `candle`'s `a`
--
Matcher.score = function(input, word)
  -- Empty input
  if #input == 0 then
    return 1, false
  end

  -- Ignore if input is long than word
  if #input > #word then
    return 0, false
  end

  -- Check first char matching (special check for completion)
  if not Config.get().allow_prefix_unmatch then
    if not Character.match(string.byte(input, 1), string.byte(word, 1)) then
      return 0, false
    end
  end

  local input_bytes = { string.byte(input, 1, -1) }
  local word_bytes = { string.byte(word, 1, -1) }

  --- Gather matched regions
  local matches = {}
  local input_start_index = 0
  local input_end_index = 1
  local word_index = 1
  local word_bound_index = 1
  while input_end_index <= #input_bytes and word_index <= #word_bytes do
    local match = Matcher.find_match_region(input_bytes, input_start_index, input_end_index, word_bytes, word_index)
    if match and input_end_index <= match.input_match_end then
      match.index = word_bound_index
      input_start_index = match.input_match_start
      input_end_index = match.input_match_end + 1
      word_index = Matcher.get_next_semantic_index(word_bytes, match.word_match_end)
      table.insert(matches, match)
    else
      word_index = Matcher.get_next_semantic_index(word_bytes, word_index)
    end
    word_bound_index = word_bound_index + 1
  end

  if #matches == 0 then
    return 0, false
  end

  -- Compute prefix match score
  local score = 0
  local input_char_map = {}
  for _, match in ipairs(matches) do
    local s = 0
    for i = match.input_match_start, match.input_match_end do
      if not input_char_map[i] then
        s = s + 1
        input_char_map[i] = true
      end
    end
    if s > 0 then
      score = score + (s * (1 + math.max(0, Matcher.WORD_BOUNDALY_ORDER_FACTOR - match.index) / Matcher.WORD_BOUNDALY_ORDER_FACTOR))
      score = score + (match.strict_match and 0.1 or 0)
    end
  end

  -- Check the word contains the remaining input. if not, it does not match.
  local last_match = matches[#matches]
  if last_match.input_match_end < #input_bytes then

    -- If input is remaining but all word consumed, it does not match.
    if last_match.word_match_end >= #word_bytes then
      return 0, false
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
        return score, true
      end
    end
    return 0, false
  end

  return score, false
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
  if item1.fuzzy ~= item2.fuzzy then
    if item1.fuzzy then
      return false
    end
    if item2.fuzzy then
      return true
    end
  end

  if item1.priority ~= item2.priority then
    if not item1.priority then
      return false
    elseif not item2.priority then
      return true
    end
    return item1.priority > item2.priority
  end

  if item1.preselect ~= item2.preselect then
    return item1.preselect
  end

  if item1.sort or item2.sort then
    if item1.score ~= item2.score then
      return item1.score > item2.score
    end

    local history_score1 = history[item1.abbr] or 0
    local history_score2 = history[item2.abbr] or 0
    if history_score1 ~= history_score2 then
      return history_score1 > history_score2
    end

    if item1.sort_text and item2.sort_text then
      if item1.sort_text ~= item2.sort_text then
        return item1.sort_text < item2.sort_text
      end
    end

    if #item1.word ~= #item2.word then
      return #item1.word < #item2.word
    end
  end


  return item1.index < item2.index
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

