local utils = require 'utils'
local api = vim.api
local fn = vim.fn
local loop = vim.loop

local M = {}

local dockerId = ""
local function onread(err, data)
  if err then
    print('ERROR: ', err)
    -- TODO handle err
  end
  if data then
    dockerId = data
  end
end

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
      utils.spawn('docker', {
        args = {'pull', image}
      },function()
        print("Image Pulled Successfully")
      end)
    end
  end
  return parsedConfig
end

local function parseWorkspaceFolder(config)
  local workspace
  if config.workspaceMount:find("localWorkspaceFolder") then
    workspace = api.nvim_exec('pwd', true)
  else
    workspace = config.workspaceMount
  end
  return workspace
end

local function runContainer(name)
  local parsedConfig = M.parseConfig()
  local stdout = loop.new_pipe(false)
  local stderr = loop.new_pipe(false)
  local workspace = parseWorkspaceFolder(parsedConfig)
  local cmd
  if parsedConfig.runArgs then
    cmd = parsedConfig.runArgs
  else
    cmd = '/bin/sh'
  end
  local mountFolder = string.format("%s:%s", workspace, parsedConfig.workspaceFolder)
  local initialArgs = {'run', '-id','-v', mountFolder}
  if not parsedConfig.forwardPorts or fn.len(parsedConfig.forwardPorts) == 0 then
    args = fn.extend(initialArgs, {name.image, cmd})
  else
    portBindings = {}
    for _, port in pairs(parsedConfig.forwardPorts) do
      vim.list_extend(portBindings, {'-p', string.format("%d:%d", port, port)})
    end
    local finalArgs = fn.extend(initialArgs, portBindings)
    args = fn.extend(finalArgs, {name.image, cmd})
  end
  handle = loop.spawn('docker', {
    args = args,
    stdio = {stdout,stderr}
  }, vim.schedule_wrap(function()
    stdout:read_stop()
    stderr:read_stop()
    stdout:close()
    stderr:close()
    handle:close()
    print(string.format("Container %s running succesfully", name.name))
    vim.g.currentContainer = fn.system(string.format("docker inspect --format '{{.Name}}' %s", dockerId)):gsub("/", "")
  end))
  loop.read_start(stdout, onread)
  loop.read_start(stderr, onread)
end

local function startContainer(name)
  local parsedConfig = M.parseConfig()
  local stdout = loop.new_pipe(false)
  local stderr = loop.new_pipe(false)
  handle = loop.spawn('docker', {
    args = {'start', name.name },
    stdio = {stdout, stderr}
  }, function()
    stdout:read_stop()
    stderr:read_stop()
    stdout:close()
    stderr:close()
    handle:close()
    print(string.format("Container %s started succesfully", name.name))
  end)
  loop.read_start(stdout, onread)
  loop.read_start(stderr, onread)
end

local function buildFromImage()
  local images = {}
  foundImages = fn.systemlist("docker image ls -a --format '{{.Repository}}:{{.Tag}} {{.ID}}'")
  if tonumber(fn.len(foundImages)) then
    M.buildImage(buildFromImage)
    return
  end
  for i, image in pairs(foundImages) do
    print(string.format('%d. %s', i, image))
    local repo = vim.split(image, "%s")
    table.insert(images, {name = repo[1], image = repo[2]})
  end
  local selected = tonumber(fn.input("No Containers found, choose an image to build: "))
  if not selected then
    return
  end
  runContainer(images[selected])
end

-- TODO: Still need to correctly set the current container
-- via inspecting the container created when we run the image.
function M.runImage()
  local images = {}
  local foundImages = fn.systemlist("docker image ls -a --format '{{.Repository}} {{.Tag}} {{.ID}}'")
  if fn.len(foundImages) == 0 then
    buildFromImage()
    return
  end
  for i, img in pairs(foundImages) do
    print(string.format('%d. %s', i, img))
    local name = vim.split(img, "%s")
    table.insert(images,{image = name[2], name = name[1]})
  end
  local selected = tonumber(fn.input('Select image number: '))
  if not selected then
    return
  end
  runContainer(images[selected])
end

function M.attachToContainer()
  local containers = {}
  local foundContainers = fn.systemlist("docker container ls -a --format '{{.Names}} {{.Image}}'")
  if fn.len(foundContainers) == 0 then
    buildFromImage()
    return
  end
  for i, container in pairs(foundContainers) do
    print(string.format('%d. %s', i, container))
    local name = vim.split(container, "%s")
    table.insert(containers,{image = name[2], name = name[1]})
  end
  local selected = tonumber(fn.input('Select container number: '))
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

-- TODO some sort of callback to restart the process
-- using spawn currently spams the floating window :/
function M.buildImage(floating)
  local parsedConfig = M.parseConfig()
  print("Creating image from: ", parsedConfig.dockerFile)
  print(floating)
  if floating then
    utils.floatingWindow()
  else
    api.nvim_command('copen')
  end
  api.nvim_command(string.format("term docker build -f %s %s", parsedConfig.dockerFile, parseWorkspaceFolder(parsedConfig)))
  api.nvim_input('<esc>')
end

return M

