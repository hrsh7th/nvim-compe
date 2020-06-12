local Matcher = {}

-- match
function Matcher.match(context, start_offset, source)
  local input = string.sub(context.before_line, start_offset)
  local input_lower = string.lower(input)

  local matches = {}
  for _, item in ipairs(source:get_items()) do
    local word = item.word
    local word_lower = string.lower(word)

    if #word >= #input then
      local score = 0

      local i = 1
      local j = 1
      local sequential = 0
      while i <= #input and j <= #word  do

        -- match.
        if string.byte(input_lower, i) == string.byte(word_lower, j) then
          sequential = sequential + 1

          -- char match bonus
          score = score + 0.5

          -- first char bonus
          if i == 1 and j == 1 then
            score = score + 1.5
          end

          -- strict match bonus
          if string.byte(input, i) == string.byte(word, j) then
            score = score + 0.5
          end

          -- sequencial match bonus
          score = score + sequential * 0.25
          i = i + 1

        -- does not match.
        else
          if sequential > 0 then
            score = score - 2
          else
            score = score - 1.5
          end
          sequential = 0
        end
        j = j + 1
      end

      -- remaining chars cost.
      score = score - ((j - i + 1) * 0.5)

      -- user_data bonus.
      score = score + (item.user_data ~= nil and item.user_data ~= '' and 0.25 or 0)

      if score > 1 or #input == 0 then
        item.score = score
        table.insert(matches, item)
      end
    end
  end

  if source:get_metadata().sort then
    table.sort(matches, function(item1, item2)
      if item1.priority ~= item2.priority then
        if item1.priority == nil then
          return false
        elseif item2.priority == nil then
          return true
        end
        return item1.priority > item2.priority
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
    end)
  end

  return matches
end

return Matcher

