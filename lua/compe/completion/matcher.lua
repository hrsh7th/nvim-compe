local Character = require'compe.completion.character'
local Matcher = {}

-- match
function Matcher.match(context, start_offset, source)
  local input = string.sub(context.before_line, start_offset)

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
  local score = 0

  local prev_s = 0
  local prev_e = #input
  local words = Matcher.split(word)
  for i, w in ipairs(words) do
    w = string.lower(w)

    local j = #w
    while j >= 1 do
      local s, e = string.find(string.lower(input), string.sub(w, 1, j), 1, true)
      if s ~= nil then
        score = score + (e - s) + 1 -- match length score
        score = score - math.max(0, s - (prev_e + 1)) * 4 -- ignore chars penalty
        score = score - math.max(0, prev_s - s) -- reuse charas penalty
        prev_s = s
        prev_e = e
        break
      end
      j = j - 1
    end
    if i == 1 and prev_s ~= 1 then
      score = score - 8 -- first prefix unmatch penalty
    end
  end

  return score - (#input - prev_e) * 4 -- remaining chars penalty
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

  if math.abs(item1.score - item2.score) > 2 then
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
  while i <= #word do
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


