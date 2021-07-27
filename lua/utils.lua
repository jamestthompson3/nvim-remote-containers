-- Taken from https://github.com/norcalli/nvim_utils/
local M = {}
function M.clean_handles()
  local n = 1
  while n <= #HANDLES do
    if HANDLES[n]:is_closing() then
      table.remove(HANDLES, n)
    else
      n = n + 1
    end
  end
end

HANDLES = {}

function M.spawn(cmd, params, onexit)
  local handle, pid
  handle, pid = vim.loop.spawn(cmd, params, function(code, signal)
    if type(onexit) == 'function' then onexit(code, signal) end
    handle:close()
    M.clean_handles()
  end)
  table.insert(HANDLES, handle)
  return handle, pid
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
