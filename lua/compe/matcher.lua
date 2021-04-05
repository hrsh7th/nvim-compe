local Character = require'compe.utils.character'

local Matcher = {}

Matcher.WORD_BOUNDALY_ORDER_FACTOR = 5

--- match
Matcher.match = function(context, source, entries)
  -- filter
  local input = context:get_input(source:get_start_offset())
  local matches = {}
  for i, entry in ipairs(entries) do
    local word = entry.lsp.label
    if #input > 0 then
      if entry.lsp.filterText and #entry.lsp.filterText > 0 then
        if Character.match(string.byte(input, 1), string.byte(entry.lsp.filterText, 1)) then
          word = entry.lsp.filterText
        end
      end
    end

    if #word >= #input then
      entry.match = Matcher.analyze(input, word, entry.match or {})
      entry.match.index = i
      if entry.match.score >= 1 or #input == 0 then
        table.insert(matches, entry)
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
    match.exact = true
    match.prefix = true
    match.fuzzy = false
    match.score = 1
    return match
  end

  -- Empty input
  if #input == 0 then
    match.exact = false
    match.prefix = true
    match.fuzzy = false
    match.score = 1
    return match
  end

  -- Ignore if input is long than word
  if #input > #word then
    match.exact = false
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
    match.exact = false
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
      match.exact = false
      match.exact = prefix
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
        match.exact = false
        match.exact = prefix
        match.fuzzy = true
        match.score = score
        return match
      end
    end
    match.exact = false
    match.exact = prefix
    match.fuzzy = false
    match.score = 0
    return match
  end

  match.exact = false
  match.exact = prefix
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
Matcher.compare = function(entry1, entry2, history)
  if entry1.match.exact ~= entry2.match.exact then
    return entry1.match.exact
  end
  if entry1.match.prefix ~= entry2.match.prefix then
    return entry1.match.prefix
  end

  if entry1.match.fuzzy ~= entry2.match.fuzzy then
    return entry2.match.fuzzy
  end

  if entry1.priority ~= entry2.priority then
    if not entry1.priority then
      return false
    elseif not entry2.priority then
      return true
    end
    return entry1.priority > entry2.priority
  end

  if entry1.lsp.preselect ~= entry2.lsp.preselect then
    return entry1.preselect
  end

  if entry1.sort or entry2.sort then
    if entry1.match.score ~= entry2.match.score then
      return entry1.match.score > entry2.match.score
    end

    local history_score1 = history[entry1.lsp.label] or 0
    local history_score2 = history[entry2.lsp.label] or 0
    if history_score1 ~= history_score2 then
      return history_score1 > history_score2
    end

    if entry1.lsp.sortText and entry2.lsp.sortText then
      if entry1.lsp.sortText ~= entry2.lsp.sortText then
        return entry1.lsp.sortText < entry2.lsp.sortText
      end
    end

    local upper1 = Character.is_upper(string.byte(entry1.lsp.label, 1))
    local upper2 = Character.is_upper(string.byte(entry2.lsp.label, 1))
    if upper1 ~= upper2 then
      return not upper1
    end
    return entry1.lsp.label < entry2.lsp.label
  end

  return entry1.match.index < entry2.match.index
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

