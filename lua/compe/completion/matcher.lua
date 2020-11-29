local Character = require'compe.completion.character'

local Matcher = {}

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
-- The score is `matched char count` (How we score remaining chars match?)
--
-- 1. Prefix matching per word boundaly
--
--   `bora`     -> `border-radius` # score: 4
--    ^^~~          ^^     ~~
--
-- 2. Datermine the matched input index by recently match_end_index
--
--   `woroff`   -> `word_offset`   # score: 5
--    ^^^~~~        ^^^  ~~
--
-- 3. Prefer strict match
--
--   `Buffer`   -> `Buffer`       # score: 6.1
--    ^^^^^^        ^^^^^^
--   `buffer`   -> `Buffer`       # score: 6
--    ^^^^^^        ^^^^^^
--
-- 3. Use remaining char as substring match
--
--   `fmodify`  -> `fnamemodify`    # score: 1 ? (not implemented yet)
--    ^~~~~~~       ^    ~~~~~~
--
Matcher.score = function(input, word)
  local input_bytes = { string.byte(input, 1, -1) }
  local word_bytes = { string.byte(word, 1, -1) }

  -- Empty input
  if #input_bytes == 0 then
    return 1
  end

  -- First char
  if not Character.match(input_bytes[1], word_bytes[1]) then
    return 0
  end

  --- Gather matched regions
  local matches = {}
  local input_start_index = 0
  local input_end_index = #input_bytes
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
  for _, match in ipairs(matches) do
    local s = 0
    for i = match.input_match_start, match.input_match_end do
      if not input_char_map[i] then
        s = s + 1
        input_char_map[i] = true
      end
    end
    if s > 0 then
      score = score + s
      score = score + (match.strict_match and 0.1 or 0)
    end
  end

  -- If remaining chars exists, it would not be match (TODO: We should check it as substring matching)
  for i = 1, #input_bytes do
    if not input_char_map[i] then
      return 0
    end
  end

  return score
end

--- find_match_region
Matcher.find_match_region = function(input_bytes, input_start_index, input_end_index, word_bytes, word_index)
  local input_match_start = -1
  local strict_match_count = 0

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

  if vim.g.compe_prefer_exact_item then
    if item1.exact ~= item2.exact then
      return item1.exact
    end
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

return Matcher

