local M = {}
local utils = require("utils")

function prepareComposeFiles(composeFiles)
	local resultingParams = {}
	if type(composeFiles) == "table" then
		for _, composeFilePath in pairs(composeFiles) do
			resultingParams[#resultingParams+1] = "-f"
			resultingParams[#resultingParams+1] = ".devcontainer/" .. composeFilePath
		end
	else 
		resultingParams[#resultingParams+1] = "-f"
		resultingParams[#resultingParams+1] = ".devcontainer/" .. composeFiles
	end

	return resultingParams
end

function M.composeUp()
	local config = utils.parseConfig("dockerComposeFile")
	local args = prepareComposeFiles(config.dockerComposeFile)
	args[#args+1] = "up"
	args[#args+1] = "-d"
	utils.spawn("docker-compose", {
		args = args, 
	}, function()
		print("Docker-compose successfully started")
	end)
end

function M.composeDown()
	local config = utils.parseConfig("dockerComposeFile")
	local args = prepareComposeFiles(config.dockerComposeFile)
	args[#args+1] = "down"
	utils.spawn("docker-compose", {
		args = args,
	}, function()
		print("Docker-compose down successfully")
	end)
end

function M.composeDestroy()
	local config = utils.parseConfig("dockerComposeFile")
	local args = prepareComposeFiles(config.dockerComposeFile)
	args[#args+1] = "rm"
	args[#args+1] = "-fsv"
	utils.spawn("docker-compose", {
		args = args,
	}, function()
		print("Docker-compose rm successfully")
	end)
end

return M
