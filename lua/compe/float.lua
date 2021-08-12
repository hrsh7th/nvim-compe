local Config = require("compe.config")

local M = {}

M.win = nil

function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
  end
  M.win = nil
end

function M.get_options(contents, opts)
  local config = Config.get()
  local pum = vim.fn.pum_getpos()
  if pum and not vim.tbl_isempty(pum) then
    -- check space on the right
    local right_col = pum.col + pum.width + (pum.scrollbar and 1 or 0) + 1
    local right_space = vim.o.columns - right_col - 1

    -- check space on the left
    local left_space = pum.col - 1

    local max_width = config.documentation.max_width
    local max_height = config.documentation.max_height

    local right = true
    if right_space >= config.documentation.min_width then
      -- place on the right
      max_width = math.min(max_width, right_space)
    elseif left_space >= config.documentation.min_width then
      -- place on the left
      max_width = math.min(max_width, left_space)
      right = false
    else
      -- not enough space, so close the float
      return
    end

    local width, height = vim.lsp.util._make_floating_popup_size(contents, {
      max_width = max_width,
      max_height = max_height,
      border = opts.border,
    })

    if height < config.documentation.min_height then
      height = config.documentation.min_height
    end

    local col = right and right_col - 1 or (pum.col - width - 3)
    return {
      relative = "editor",
      style = "minimal",
      width = width,
      height = height,
      row = pum.row,
      col = col,
      border = opts.border,
    }
  end
end

function M.scroll(delta)
  delta = delta or 4
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    local info = vim.fn.getwininfo(M.win)[1] or {}
    local buf = vim.api.nvim_win_get_buf(M.win)
    local top = info.topline or 1
    top = top + delta
    top = math.max(top, 1)
    top = math.min(top, vim.api.nvim_buf_line_count(buf) - info.height + 1)

    vim.defer_fn(function()
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("norm! " .. top .. "zt")
      end)
    end, 0)
  end
end

---@param contents string|table string ot list of lines
function M.show(contents, opts)
  local config = Config.get()
  opts = opts or {}
  opts.border = config.documentation.border
  opts.max_width = config.documentation.max_width
  opts.max_height = config.documentation.max_height

  contents = contents or {}
  if type(contents) == "table" then
    contents = table.concat(contents, "\n")
  end
  if contents == '' then
    return M.close()
  end
  contents = vim.split(contents, "\n", true)
  -- Clean up input: trim empty lines from the end, pad
  contents = vim.lsp.util._trim(contents, opts)

  -- close if nothing to display
  if #contents == 0 then
    return M.close()
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  -- applies the syntax and sets the lines to the buffer
  contents = vim.lsp.util.stylize_markdown(buf, contents, opts)

  local float_options = M.get_options(contents, opts)
  if not float_options then
    return
  end

  -- reuse existing window, or create a new one
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_set_buf(M.win, buf)
    vim.api.nvim_win_set_config(M.win, float_options)
  else
    M.win = vim.api.nvim_open_win(buf, false, float_options)
  end

  -- conceal
  vim.api.nvim_win_set_option(M.win, "conceallevel", 2)
  vim.api.nvim_win_set_option(M.win, "concealcursor", "n")
  vim.api.nvim_win_set_option(M.win, "winhighlight", config.documentation.winhighlight)

  -- disable folding
  vim.api.nvim_win_set_option(M.win, "foldenable", false)

  -- soft wrapping
  vim.api.nvim_win_set_option(M.win, "wrap", true)
  vim.api.nvim_win_set_option(M.win, "scrolloff", 0)

  return buf, M.win
end

return M
