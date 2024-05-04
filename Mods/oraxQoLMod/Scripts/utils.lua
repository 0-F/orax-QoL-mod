function isFileExists(filename)
  local file = io.open(filename, "r")
  if file ~= nil then
    io.close(file)
    return true
  else
    return false
  end
end

function getCurrentDirectory()
  return debug.getinfo(2, "S").source:match("@?(.+)\\")
end

function __FILE__()
  return debug.getinfo(2, 'S').source
end

function __LINE__()
  return debug.getinfo(2, 'l').currentline
end

function __NAME__()
  return debug.getinfo(2, "n").name
end

function printf(...)
  print(string.format(...))
end

function err(msg)
  print(debug.traceback(msg, 2))
end

function dbg(msg)
  local info = debug.getinfo(2, "lnS")
  local file = info.short_src:gsub(".+\\Mods\\", "")
  local line = string.format("%s %s() %d", file, info.name, info.currentline)

  if msg ~= nil then
    line = line .. ": " .. msg
  end

  print(line)
end
