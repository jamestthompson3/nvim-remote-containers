-- Taken from https://github.com/norcalli/nvim_utils/
local function clean_handles()
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

function spawn(cmd, params, onexit)
  local handle, pid
  handle, pid = vim.loop.spawn(cmd, params, function(code, signal)
    if type(onexit) == 'function' then onexit(code, signal) end
    handle:close()
    clean_handles()
  end)
  table.insert(HANDLES, handle)
  return handle, pid
end

--- Check if a file or directory exists in this path
function exists(file)
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
function log(item)
  print(vim.inspect(item))
end
