local Character = require'compe.completion.character'
local Matcher = {}

-- match
function Matcher.match(context, start_offset, source)
  local input = string.sub(context.before_line, start_offset)
  local input_lower = string.lower(input)

  local matches = {}
  for _, item in ipairs(source:get_items()) do
    local score = 0
    if #item.word >= #input then
      if source.incomplete then
        score = 1.1
      else
        score = Matcher.score(input, input_lower, item)
      end
    end

    if score > 1 or #input == 0 then
      item.score = score
      table.insert(matches, item)
    end
  end

  if source:get_metadata().sort and source.incomplete ~= true then
    table.sort(matches, Matcher.sort)
  end

  local limited = {}
  for i = 1, 80 do
    table.insert(limited, matches[i])
  end

  return limited
end

--- score
function Matcher.score(input, input_lower, item)
  local word = item.word
  local word_lower = string.lower(item.word)

  local score = 0
  local i = 1
  local j = 1
  local sequential = 0
  while i <= #input and j <= #word do
    local is_semantic_index = Matcher.is_semantic_index(word, j)

    -- match.
    if string.byte(input_lower, i) == string.byte(word_lower, j) then
      sequential = sequential + 1

      -- first char bonus
      if i == 1 and j == 1 then
        score = score + 5
      elseif is_semantic_index then
        score = score + 4
      end

      -- strict match bonus
      if string.byte(input, i) == string.byte(word, j) then
        score = score + 1
      else
        score = score + 0.75
      end

      -- sequencial match bonus
      score = score + sequential * sequential * 0.5
      i = i + 1

      -- does not match.
    else
      if i == 1 and j == 1 then
        score = score - 7
      elseif is_semantic_index then
        score = score - 6
      elseif sequential > 0 then
        score = score - sequential * sequential * 2
      else
        score = score - 3
      end
      sequential = 0
    end
    j = j + 1
  end

  return score
end

--- sort
function Matcher.sort(item1, item2)
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

  if item1.sort_text ~= nil and item2.sort_text ~= nil then
    if item1.sort_text ~= item2.sort_text then
      return item1.sort_text < item2.sort_text
    end
  end

  if item1.score > item2.score then
    return true
  elseif item1.score < item2.score then
    return false
  end

  if #item1.word < #item2.word then
    return true
  end
  return false
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
  end
  return false
end


return Matcher

