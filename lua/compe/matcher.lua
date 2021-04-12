local Character = require'compe.utils.character'

local Matcher = {}

Matcher.WORD_BOUNDALY_ORDER_FACTOR = 5

--- match
Matcher.match = function(context, source, items)
  -- filter
  local input = context:get_input(source:get_start_offset())
  local matches = {}
  for i, item in ipairs(items) do
    item.index = i

    local word = item.original_word
    if #input > 0 then
      if item.filter_text and #item.filter_text > 0 then
        if Character.match(string.byte(input, 1), string.byte(item.filter_text, 1)) then
          word = item.filter_text
        end
      end
    end

    if #word >= #input then
      item.match = Matcher.analyze(input, word, item.match or {})
      item.match.exact = input == item.original_abbr
      if item.match.score >= 1 then
        table.insert(matches, item)
      end
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
--   1. Word boundary order
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
--   1. Prefix matching per word boundary
--
--     `bora`         -> `border-radius` # imaginary score: 4
--      ^^~~              ^^     ~~
--
--   2. Try sequential match first
--
--     `woroff`       -> `word_offset`   # imaginary score: 6
--      ^^^~~~            ^^^  ~~~
--
--     * The `woroff`'s second `o` should not match `word_offset`'s first `o`
--
--   3. Prefer early word boundary
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
--   5. Use remaining characters for substring match
--
--     `fmodify`        -> `fnamemodify`   # imaginary score: 1
--      ^~~~~~~             ^    ~~~~~~
--
--   6. Avoid unexpected match detection
--
--     `candlesingle` -> candle#accept#single
--      ^^^^^^~~~~~~     ^^^^^^        ~~~~~~
--
--      * The `accept`'s `a` should not match to `candle`'s `a`
--
Matcher.analyze = function(input, word, match)
  -- Exact
  if input == word then
    match.prefix = true
    match.fuzzy = false
    match.score = 1
    return match
  end

  -- Empty input
  if #input == 0 then
    match.prefix = true
    match.fuzzy = false
    match.score = 1
    return match
  end

  -- Ignore if input is long than word
  if #input > #word then
    match.prefix = false
    match.fuzzy = false
    match.score = 0
    return match
  end

  --- Gather matched regions
  local matches = {}
  local input_start_index = 0
  local input_end_index = 1
  local word_index = 1
  local word_bound_index = 1
  while input_end_index <= #input and word_index <= #word do
    local match = Matcher.find_match_region(input, input_start_index, input_end_index, word, word_index)
    if match and input_end_index <= match.input_match_end then
      match.index = word_bound_index
      input_start_index = match.input_match_start
      input_end_index = match.input_match_end + 1
      word_index = Character.get_next_semantic_index(word, match.word_match_end)
      table.insert(matches, match)
    else
      word_index = Character.get_next_semantic_index(word, word_index)
    end
    word_bound_index = word_bound_index + 1
  end

  if #matches == 0 then
    match.prefix = false
    match.fuzzy = false
    match.score = 0
    return match
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

  local prefix = matches[1].input_match_start == 1 and matches[1].word_match_start == 1

  -- Check the word contains the remaining input. if not, it does not match.
  local last_match = matches[#matches]
  if last_match.input_match_end < #input then

    -- If input is remaining but all word consumed, it does not match.
    if last_match.word_match_end >= #word then
      match.prefix = prefix
      match.fuzzy = false
      match.score = 0
      return match
    end

    for word_index = last_match.word_match_end + 1, #word do
      local word_offset = 0
      local input_index = last_match.input_match_end + 1
      local matched = false
      while word_offset + word_index <= #word and input_index <= #input do
        if Character.match(string.byte(word, word_index + word_offset), string.byte(input, input_index)) then
          matched = true
          input_index = input_index + 1
        elseif matched then
          break
        end
        word_offset = word_offset + 1
      end
      if input_index - 1 == #input then
        match.prefix = prefix
        match.fuzzy = true
        match.score = score
        return match
      end
    end
    match.prefix = prefix
    match.fuzzy = false
    match.score = 0
    return match
  end

  match.prefix = prefix
  match.fuzzy = false
  match.score = score
  return match
end

--- find_match_region
Matcher.find_match_region = function(input, input_start_index, input_end_index, word, word_index)
  -- determine input position ( woroff -> word_offset )
  while input_start_index < input_end_index do
    if Character.match(string.byte(input, input_end_index), string.byte(word, word_index)) then
      break
    end
    input_end_index = input_end_index - 1
  end

  -- Can't determine input position
  if input_start_index == input_end_index then
    return nil
  end

  local strict_match_count = 0
  local input_match_start = -1
  local input_index = input_end_index
  local word_offset = 0
  while input_index <= #input and word_index + word_offset <= #word do
    if Character.match(string.byte(input, input_index), string.byte(word, word_index + word_offset)) then
      -- Match start.
      if input_match_start == -1 then
        input_match_start = input_index
      end

      -- Increase strict_match_count
      if string.byte(input, input_index) == string.byte(word, word_index + word_offset) then
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

--- compare
Matcher.compare = function(item1, item2, history)
  if item1.match.exact ~= item2.match.exact then
    return item1.match.exact
  end
  if item1.match.prefix ~= item2.match.prefix then
    return item1.match.prefix
  end

  if item1.match.fuzzy ~= item2.match.fuzzy then
    return item2.match.fuzzy
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
    if item1.match.score ~= item2.match.score then
      return item1.match.score > item2.match.score
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

    local upper1 = Character.is_upper(string.byte(item1.abbr, 1))
    local upper2 = Character.is_upper(string.byte(item2.abbr, 1))
    if upper1 ~= upper2 then
      return not upper1
    end
    return item1.abbr < item2.abbr
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

return Matcher

