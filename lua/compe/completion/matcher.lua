local Debug = require'compe.debug'
local Matcher = {}

-- match
function Matcher.match(context, start_offset, items)
  local input = string.sub(context.before_line, start_offset)
  local input_lower = string.lower(input)

  local matches = {}
  for _, item in ipairs(items) do
    local word = Matcher.create_word(context, start_offset, item)
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
            score = score + 1
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
            score = score - 1.75
          else
            score = score - 1.25
          end
          sequential = 0
        end
        j = j + 1
      end

      -- user_data bonus.
      score = score + (item.user_data ~= nil and item.user_data ~= '' and 0.25 or 0)

      if score >= 1 or #input == 0 then
        item.score = score
        table.insert(matches, vim.tbl_extend('keep', { word = word; }, item))
      end
    end
  end

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
  return matches
end

function Matcher.create_word(context, start_offset, item)
  local word = item.word

  -- fix complete position gap for prefix over
  local pre_over_spos, pre_over_epos, pre_over = string.find(word, '^([%w%-_]*.)')
  if pre_over_spos ~= nil then
    if string.sub(context.before_line, start_offset - #pre_over, start_offset - 1) == pre_over then
      word = string.sub(word, pre_over_epos + 1, #word)
    end
  end

  -- fix complete position gap for postfix over
  local post_over_spos, _, post_over = string.find(word, '(.[%w%-_]*)$')
  if post_over_spos ~= nil then
    if string.sub(context.after_line, 1, #post_over) == post_over then
      word = string.sub(word, 1, #word - #post_over)
    end
  end

  if word ~= item.word then
    Debug:log(vim.inspect({
      pre_over = pre_over;
      post_over = post_over;
      fixed_word = word;
      item_word = item.word;
    }))
  end
  return word
end

return Matcher

