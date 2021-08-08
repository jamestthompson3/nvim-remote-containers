local utils = require("utils")
local api = vim.api
local fn = vim.fn

local M = {}

function M.parseConfig()
	if not (fn.executable("docker")) then
		error("must install docker for this functionality")
	end
	if not (utils.exists("devcontainer.json")) then
		-- TODO interactive creation of config
		print("no configuration file found")
		return
	end
	local parsedConfig = fn.json_decode(fn.join(fn.readfile("devcontainer.json")))
	if not parsedConfig.image then
		if not parsedConfig.dockerFile then
			error("must either specify an image or a Dockerfile")
			return
		end
	end
	if parsedConfig.image then
		local image = parsedConfig.image
		local imageExists = fn.system("docker image ls"):find(image)
		if not imageExists then
			print("image not found, installing now...")
			utils.spawn("docker", {
				args = { "pull", image },
			}, function()
				print("Image Pulled Successfully")
			end)
		end
	end
	return parsedConfig
end

local function parseWorkspaceFolder(config)
	local workspace
	if config.workspaceMount:find("localWorkspaceFolder") then
		workspace = api.nvim_exec("pwd", true)
	else
		workspace = config.workspaceMount
	end
	return workspace
end

local function getDockerArgs(imageId)
	local parsedConfig = M.parseConfig()
	local workspace = parseWorkspaceFolder(parsedConfig)
	local cmd = ""
	local portBindings = {}
	local args = {}
	if parsedConfig.runArgs then
		cmd = parsedConfig.runArgs
	else
		cmd = "/bin/sh"
	end
	local mountFolder = string.format("%s:%s", workspace, parsedConfig.workspaceFolder)
	local initialArgs = { "run", "-id", "-v", mountFolder, "--rm" }
	if not parsedConfig.forwardPorts or fn.len(parsedConfig.forwardPorts) == 0 then
		args = fn.extend(initialArgs, { imageId, cmd })
	else
		for _, port in pairs(parsedConfig.forwardPorts) do
			vim.list_extend(portBindings, { "-p", string.format("%d:%d", port, port) })
		end
		args = fn.extend(initialArgs, portBindings)
	end
	return vim.list_extend(args, { imageId })
end

local function runContainer(name)
	local args = getDockerArgs(name.image)
	local dockerId
	utils.spawn("docker", {
		args = args,
		stderr = function(err, id)
			if err then
				print(err)
			else
				if id then
					dockerId = id
				end
			end
		end,
	}, function()
		print("%s started successfully", name.name)
		vim.schedule_wrap(function()
			while dockerId == nil do
				-- Hang out while we get the dockerId
				-- Not ideal, but it works for now...
			end
			vim.g.currentContainer =
				fn.system(
					string.format("docker ps -af id='%s' --format '{{.Names}}'", dockerId)
				):gsub("/", "")
		end)
	end)
end

local function startContainer(name)
	utils.spawn("docker", {
		args = { "start", name.name },
	}, function()
		print(string.format("Container %s started succesfully", name.name))
		vim.g.currentContainer = name.name
	end)
end

local function buildFromImage()
	local foundImages
	local images = {}
	foundImages = fn.systemlist("docker image ls -a --format '{{.Repository}}:{{.Tag}} {{.ID}}'")
	if tonumber(fn.len(foundImages)) then
		M.buildImage(buildFromImage)
		return
	end
	for i, image in pairs(foundImages) do
		print(string.format("%d. %s", i, image))
		local repo = vim.split(image, "%s")
		table.insert(images, { name = repo[1], image = repo[2] })
	end
	local selected = tonumber(fn.input("No Containers found, choose an image to build: "))
	if not selected then
		return
	end
	runContainer(images[selected])
end

function M.startImage()
	local images = {}
	local foundImages = fn.systemlist("docker image ls -a --format '{{.Repository}} {{.Tag}} {{.ID}}'")
	if fn.len(foundImages) == 0 then
		buildFromImage()
		return
	end
	for i, img in pairs(foundImages) do
		print(string.format("%d. %s", i, img))
		local name = vim.split(img, "%s")
		table.insert(images, { name = name[1], tag = name[2], id = name[3] })
	end
	local selected = tonumber(fn.input("Select image number: "))
	if not selected then
		return
	end
	M.runImage(images[selected].id)
end

function M.runImage(imageId)
	local args = getDockerArgs(imageId)
	local dockerId
	utils.spawn("docker", {
		args = args,
		-- docker outputs id to stderr
		stderr = function(err, id)
			if err then
				print(err)
			else
				if id then
					dockerId = id
				end
			end
		end,
	}, function()
		print("%s started successfully", imageId)
		vim.schedule_wrap(function()
			while dockerId == nil do
				-- Hang out while we get the dockerId
				-- Not ideal, but it works for now...
			end
			vim.g.currentContainer =
				fn.system(
					string.format("docker ps -af id='%s' --format '{{.Names}}'", dockerId)
				):gsub("/", "")
		end)
	end)
end

function M.attachToContainer()
	local containers = {}
	local foundContainers = fn.systemlist("docker container ls -a --format '{{.Names}} {{.Image}}'")
	if fn.len(foundContainers) == 0 then
		buildFromImage()
		return
	end
	for i, container in pairs(foundContainers) do
		print(string.format("%d. %s", i, container))
		local name = vim.split(container, "%s")
		table.insert(containers, { image = name[2], name = name[1] })
	end
	local selected = tonumber(fn.input("Select container number: "))
	if not selected then
		return
	end
	local containerName = containers[selected]
	local containerIsRunning = fn.system("docker container ps --format '{{.Names}}'"):find(containerName.name)
	if not containerIsRunning then
		local containerIsCreated = fn.system("docker container ps -a --format '{{.Names}}'"):find(containerName.name)
		if not containerIsCreated then
			runContainer(containerName)
		else
			startContainer(containerName)
		end
	end
end

function M.buildImage(floating)
	local parsedConfig = M.parseConfig()
	print("Creating image from: ", parsedConfig.dockerFile)
	if floating == "true" then
		utils.floatingWindow()
	else
		api.nvim_command("copen")
	end
	local tag = fn.system("git rev-parse --show-toplevel")
	if string.find(tag, "fatal") ~= nil then
		local dirs
		local cwd
		cwd = api.nvim_exec("pwd", true)
		dirs = vim.split(cwd, "/")
		tag = dirs[#dirs]:gsub("\n", "")
	else
		local dirs
		dirs = vim.split(tag, "/")
		tag = dirs[#dirs]:gsub("\n", "")
	end
	api.nvim_command(
		string.format(
			"term docker build -f %s %s -t %s",
			parsedConfig.dockerFile,
			parseWorkspaceFolder(parsedConfig),
			tag
		)
	)
	api.nvim_input("<esc>")
end

return M
