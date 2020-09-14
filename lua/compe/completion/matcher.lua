local Character = require'compe.completion.character'
local Matcher = {}
local Factor = 100 -- max word bound detection count

-- match
function Matcher.match(context, source)
  local input = context:get_input(source:get_start_offset())

  local matches = {}
  for _, item in ipairs(source:get_items()) do
    local word = item.filter_text or item.word
    item.score = 0
    if #item.word >= #input then
      item.score = Matcher.score(input, word)
      item.exact = word == input
    end

    if item.score >= 1 or #input == 0 then
      table.insert(matches, item)
    end
  end

  if source:get_metadata().sort then
    table.sort(matches, Matcher.sort)
  end

  local limited = {}
  for i = 1, 80 do
    table.insert(limited, matches[i])
  end

  return limited
end

--- score
function Matcher.score(input, word)
  local matches = {}

  -- gather matches
  local words = Matcher.split(word)
  for i, w in ipairs(words) do
    local j = #w
    while j >= 1 do
      local s, e = string.find(string.lower(input), string.sub(string.lower(w), 1, j), 1, true)
      if s ~= nil then
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
  for i, match in ipairs(matches) do
    -- first prefix unmatch penalty
    if i == 1 and (match.i ~= 1 or match.s ~= 1) then
      score = score - 8
    end

    -- add new used char score
    local s = 0
    for j = match.s, match.e do
      if char_map[j] == true then
        s = s - 1
      end
      s = s + 1
      char_map[j] = true
    end
    score = score + s * (1 + math.max(1, Factor - match.i) / Factor)
    score = score + (match.exact and 0.1 or 0)
  end

  -- no used char penalty
  local i = 1
  while i <= #input do
    if char_map[i] ~= true then
      score = score - 6
    end
    i = i + 1
  end

  return score
end

--- sort
function Matcher.sort(item1, item2)
  if item1.exact ~= item2.exact then
    return item1.exact
  end

  if item1.priority ~= item2.priority then
    if item1.priority == nil then
      return false
    elseif item2.priority == nil then
      return true
    end
    return item1.priority > item2.priority
  end

  if item1.asis ~= item2.asis then
    return item2.asis
  end

  if math.abs(item1.score - item2.score) ~= 0 then
    return item1.score > item2.score
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

  -- kebab-case
  elseif prev == '-' and Character.is_alpha(curr) then
    return true

  -- snake-case
  elseif prev == '_' and Character.is_alpha(curr) then
    return true

  -- file ext
  elseif prev == '.' and Character.is_alpha(curr) then
    return true

  -- file path
  elseif prev == '/' and Character.is_alpha(curr) then
    return true

  end
  return false
end


return Matcher


