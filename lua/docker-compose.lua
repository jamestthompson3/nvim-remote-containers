local M = {}
local utils = require("utils")

function M.composeUp()
	local config = utils.parseConfig("dockerComposeFile")
	local compose = ".devcontainer/" .. config.dockerComposeFile
	utils.spawn("docker-compose", {
		args = { "-f", compose, "up", "-d" },
	}, function()
		print("Docker-compose successfully started")
	end)
end

function M.composeDown()
	local config = utils.parseConfig("dockerComposeFile")
	local compose = ".devcontainer/" .. config.dockerComposeFile
	utils.spawn("docker-compose", {
		args = { "-f", compose, "down" },
	}, function()
		print("Docker-compose down successfully")
	end)
end

function M.composeDestroy()
	local config = utils.parseConfig("dockerComposeFile")
	local compose = ".devcontainer/" .. config.dockerComposeFile
	utils.spawn("docker-compose", {
		args = { "-f", compose, "rm", "-fsv" },
	}, function()
		print("Docker-compose rm successfully")
	end)
end

return M
