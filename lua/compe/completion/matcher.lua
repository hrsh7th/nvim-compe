local Character = require'compe.completion.character'
local Matcher = {}
local Factor = 100 -- max word bound detection count

--- match
-- This add special attributes for each items.
-- * score
-- * exact
function Matcher.match(context, source, history)
  local input = context:get_input(source:get_start_offset())
  local input_lower = string.lower(input)

  local matches = {}
  for _, item in ipairs(source:get_items()) do
    local word = item.original_word
    if item.filter_text and #input > 0 and (string.sub(item.filter_text, 1, 1) == string.sub(input, 1, 1)) then
      word = item.filter_text
    end

    item.score = 0
    if #word >= #input then
      item.score = Matcher.score(input, input_lower, word)
      item.exact = word == input
    end

    if item.score >= 1 or #input == 0 then
      table.insert(matches, item)
    end
  end

  if source:get_metadata().sort then
    table.sort(matches, function(item1, item2)
      return Matcher.compare(item1, item2, history)
    end)
  end

  local limited = {}
  for i = 1, 80 do
    table.insert(limited, matches[i])
  end

  return limited
end

--- score
function Matcher.score(input, input_lower, word)
  if string.lower(string.sub(input, 1, 1)) ~= string.lower(string.sub(word, 1, 1)) then
    return 0
  end

  local matches = {}

  -- gather matches
  local words = Matcher.split(word)
  local prev_match_end = 1
  for i, w in ipairs(words) do
    local w_lower = string.lower(w)

    local j = #w
    while j >= 1 do
      local s, e
      local curr_match_end = prev_match_end
      while curr_match_end >= 1 do
        s, e = string.find(input_lower, string.sub(w_lower, 1, j), curr_match_end, true)
        if s ~= nil then
          break
        end
        curr_match_end = curr_match_end - 1
      end
      if s ~= nil then
        prev_match_end = e + 1
        table.insert(matches, {
          exact = string.sub(input, s, e) == string.sub(w, 1, j);
          i = i;
          s = s;
          e = e;
          l = (e - s) + 1;
          w = w;
        })
        break
      end
      j = j - 1
    end
  end

  if #matches == 0 then
    return 0
  end

  -- compute score
  local char_map = {}
  local score = 0
  for _, match in ipairs(matches) do
    -- add new used char score
    local s = 0
    for j = match.s, match.e do
      if char_map[j] == true then
        s = s - 1
      end
      s = s + 1
      char_map[j] = true
    end
    s = s * 1.2 - 0.2
    score = score + s * (1 + math.max(0, Factor - match.i) / Factor)
    score = score + (match.exact and 0.1 or 0)
  end

  -- no used char penalty
  local i = 1
  while i <= #input do
    if char_map[i] ~= true then
      score = score - 8
    end
    i = i + 1
  end

  return score
end

--- compare
function Matcher.compare(item1, item2, history)
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

  return #item1.word < #item2.word
end

-- split
function Matcher.split(word)
  local words = {}
  local i = 1
  while i <= #word and i <= Factor do
    if Matcher.is_semantic_index(word, i) then
      table.insert(words, string.sub(word, i))
    end
    i = i + 1
  end
  return words
end

-- is_semantic_index
function Matcher.is_semantic_index(word, index)
  -- first-char
  if index <= 1 then
    return true
  end

  local curr = string.sub(word, index, index)
  local prev = string.sub(word, index - 1, index - 1)

  -- camel-case
  if Character.is_upper(prev) ~= true and Character.is_upper(curr) then
    return true

  -- boundaly
  elseif Character.is_alpha(prev) ~= true and Character.is_alpha(curr) then
    return true
  end
  return false
end

return Matcher

