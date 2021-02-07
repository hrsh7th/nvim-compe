local compe = require'compe'
local api = vim.api
local fn = vim.fn
--

local function json_decode(data)
  local status, result = pcall(vim.fn.json_decode, data)
  if status then
    return result
  else
    return nil, result
  end
end

-- locate the binary here, as expand is relative to the calling script name
local binary = nil
if fn.has("mac") == 1 then
	binary = fn.expand("<sfile>:p:h:h:h") .. "/binaries/TabNine_Darwin"
elseif fn.has('unix') == 1 then
	binary = fn.expand("<sfile>:p:h:h:h") .. "/binaries/TabNine_Linux"
else
	binary = fn.expand("<sfile>:p:h:h:h") .. "/binaries/TabNine_Windows"
end


local Source = {
	items = {};
	max_lines = 1000;
	max_num_results = 20;
	last_initiated = 0;
	last_finished = 0;
}

--- get_metadata
function Source.get_metadata(_)
	return {
		priority = 5000;
		dup = 0;
		menu = '[TN]';
	}
end

--- determine
function Source.determine(_, context)
  return compe.helper.determine(context)
end


Source._do_complete = function()
	if Source.job == 0 then
		return
	end

	Source.last_initiated = Source.last_initiated + 1
	Source.items = {}

	local cursor=api.nvim_win_get_cursor(0)
	local cur_line = api.nvim_get_current_line()
	local cur_line_before = string.sub(cur_line, 0, cursor[2])
	local cur_line_after = string.sub(cur_line, cursor[2]+1) -- include current character

	local region_includes_beginning = false
	local region_includes_end = false
	if cursor[1] - Source.max_lines <= 1 then region_includes_beginning = true end
	if cursor[1] + Source.max_lines >= fn['line']('$') then region_includes_end = true end

	local lines_before = api.nvim_buf_get_lines(0, cursor[1] - Source.max_lines , cursor[1]-1, false)
	table.insert(lines_before, cur_line_before)
	local before = fn.join(lines_before, "\n")

	local lines_after = api.nvim_buf_get_lines(0, cursor[1], cursor[1] + Source.max_lines, false)
	table.insert(lines_after, 1, cur_line_after)
	local after = fn.join(lines_after, "\n")

	local req = {}
	req.version = "2.0.0"
	req.request = {
		Autocomplete = {
			before = before,
			after = after,
			region_includes_beginning = region_includes_beginning,
			region_includes_end = region_includes_end,
			filename = fn["expand"]("%:p"),
			max_num_results = Source.max_num_results
		}
	}

	fn.chansend(Source.job, fn.json_encode(req) .. "\n")
end

--- complete
function Source.complete(self, args)
	-- print(Source.last_initiated, Source.last_finished, Source.items)
	if Source.last_initiated >= Source.last_finished + 10 then
		-- restart
		Source._on_exit(0, 0)
	end

	-- for _, result in ipairs(Source.items) do
	-- 	print('tn:', result)
	-- end
	--- check processing
	if Source.last_initiated < Source.last_finished then
		args.callback({
			items = {};
			incomplete = true;
		})
	elseif next(Source.items) == nil then
		-- we have no items, and no pending comp event. initiate one
		Source._do_complete()
		args.callback({
			items = {};
			incomplete = true;
		})
	else
		local items = Source.items
		Source.items = {}
		args.callback({
			items = items;
			incomplete = false;
		})
	end
end

Source._on_err = function(_, data, _)
end

Source._on_exit = function(_, code)
	-- restart..
	if code == 143 then
		-- nvim is exiting. do not restart
		return
	end
	Source.items = {}
	Source.last_initiated = 0
	Source.last_finished = 0

	Source.job = fn.jobstart({binary}, {
		on_stderr = Source._on_stderr;
		on_exit = Source._on_exit;
		on_stdout = Source._on_stdout;
	})
end

Source._on_stdout = function(_, data, _)
      -- {
      --   "old_prefix": "wo",
      --   "results": [
      --     {
      --       "new_prefix": "world",
      --       "old_suffix": "",
      --       "new_suffix": "",
      --       "detail": "64%"
      --     }
      --   ],
      --   "user_message": [],
      --   "docs": []
      -- }
      local response = json_decode(data)
      if response == nil then
	      Source._on_exit(0,0)
	      -- print('TabNine: json decode error')
	      return
      end
      local results = response.results
      if results == nil then
	      return
      end

      for _, result in ipairs(results) do
	      table.insert(Source.items, result.new_prefix)
      end
      Source.last_finished = Source.last_finished + 1
end

Source._on_exit(0, 0)


return Source
