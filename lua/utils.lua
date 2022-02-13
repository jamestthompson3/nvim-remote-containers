local M = {}
local uv = vim.loop
local message = {}

function M.systemChecks()
	if not (vim.fn.executable("docker")) then
		error("must install docker for this functionality")
	end
	if not (M.exists(".devcontainer")) then
		error("Could not find .devcontainer folder")
	end
	if not (M.exists(".devcontainer/devcontainer.json")) then
		error("Could not find .devcontainer/devcontainer.json")
	end
end

function M.parseConfig(configType)
	M.systemChecks()

	-- TODO: Check current directory and the devcontainer
	local parsedConfig = vim.fn.json_decode(vim.fn.join(vim.fn.readfile(".devcontainer/devcontainer.json")))
	if not parsedConfig.image and not parsedConfig.dockerComposeFile and not parsedConfig.dockerFile then
		error("must have an image, dockerfile, or docker-compose file")
		return
	end

	if not parsedConfig[configType] then
		error("Must have " .. configType .. " defined in the devcontainer.json")
		return
	end
	return parsedConfig
end

local function safe_close(handle)
	if not uv.is_closing(handle) then
		uv.close(handle)
	end
end

local function fmt(data)
	local vars = vim.split(data, "\n")
	for _, d in pairs(vars) do
		table.insert(message, d)
	end
end

local function onread(err, data)
	if err then
		fmt(err)
	end
	if data then
		fmt(data)
	end
end

local function showError()
	local buf = M.floatingWindow()
	vim.api.nvim_buf_set_lines(buf, 0, -1, true, message)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

function M.spawn(cmd, opts, onexit)
	local inpt = { stdout = opts.stdout or function() end, stderr = onread or opts.stderr or function() end }
	local handle
	local stdout = uv.new_pipe(false)
	local stderr = uv.new_pipe(false)

	handle, _ = uv.spawn(
		cmd,
		vim.tbl_extend("force", opts, { stdio = { nil, stdout, stderr } }),
		vim.schedule_wrap(function(code, signal)
			uv.read_stop(stdout)
			uv.read_stop(stderr)
			safe_close(handle)
			safe_close(stdout)
			safe_close(stderr)

			print(code, signal)
			if code == 1 then
				showError()
			end
			if type(onexit) == "function" then
				onexit()
			end
		end)
	)
	uv.read_start(stdout, inpt.stdout)
	uv.read_start(stderr, inpt.stderr)
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
		vim.api.nvim_open_win(buf, true, opts)
		return buf
	end
end

return M
