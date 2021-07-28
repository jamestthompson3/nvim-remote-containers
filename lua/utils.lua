local M = {}
local loop = vim.loop

local function safe_close(handle)
  if not loop.is_closing(handle) then
    loop.close(handle)
  end
end

function M.spawn(cmd, opts, input, onexit)
  local inpt = input or { stdout = function()
  end, stderr = function()
end }
local handle
local stdout = loop.new_pipe(false)
local stderr = loop.new_pipe(false)
handle, _ = loop.spawn(cmd, vim.tbl_extend("force", opts, { stdio = { stdout, stderr } }), function(code, signal)
  if type(onexit) == "function" then
    onexit(code, signal)
  end
  loop.read_stop(stdout)
  loop.read_stop(stderr)
  safe_close(handle)
  safe_close(stdout)
  safe_close(stderr)
end)
loop.read_start(stdout, inpt.stdout)
loop.read_start(stderr, inpt.stderr)
end

--- Check if a file or directory exists in this path
function M.exists(file)
  local ok, err, code = os.rename(file, file)
  if not ok then
    if code == 13 then
      -- Permission denied, but it exists
      return true
    end
  end
  return ok, err
end

-- better debugging
function M.log(item)
  print(vim.inspect(item))
end

function M.floatingWindow()
  -- get the editor's max width and height
  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")

  -- create a new, scratch buffer, for fzf
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")

  -- if the editor is big enough
  if width > 150 or height > 35 then
    -- fzf's window height is 3/4 of the max height, but not more than 30
    local win_height = math.min(math.ceil(height * 3 / 4), 30)
    local win_width

    -- if the width is small
    if width < 150 then
      -- just subtract 8 from the editor's width
      win_width = math.ceil(width - 8)
    else
      -- use 90% of the editor's width
      win_width = math.ceil(width * 0.9)
    end

    -- settings for the fzf window
    local opts = {
      relative = "editor",
      width = win_width,
      height = win_height,
      row = math.ceil((height - win_height) / 2),
      col = math.ceil((width - win_width) / 2),
      style = "minimal",
    }

    -- create a new floating window, centered in the editor
    local win = vim.api.nvim_open_win(buf, true, opts)
  end
end

return M
