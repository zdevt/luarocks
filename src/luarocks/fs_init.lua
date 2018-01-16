
--- Module for filesystem and platform abstractions.
-- All code using "fs" code should use an object produced by
-- fs.new(), and not the various platform-specific implementations.
-- However, see the documentation of the implementation
-- for the API reference.

local pairs = pairs

local fs = {}

local pack = table.pack or function(...) return { n = select("#", ...), ... } end
local unpack = table.unpack or unpack -- luacheck: ignore

function fs.new(platforms, verbose, use_modules)
  local self = {}

  self.dir_stack = {}
  self.verbose = verbose

  if verbose then
    self.io_popen = function(one, two)
      if two == nil then
        print("\nio.popen: ", one)
      else
        print("\nio.popen: ", one, "Mode:", two)
      end
      return io.popen(one, two)
    end

    self.os_execute = function(cmd) -- luacheck: ignore
      -- redact api keys if present
      print("\nos.execute: ", (cmd:gsub("(/api/[^/]+/)([^/]+)/", function(cap) return cap.."<redacted>/" end)) )
      local code = pack(os.execute(cmd))
      print("Results: "..tostring(code.n))
      for i = 1,code.n do
        print("  "..tostring(i).." ("..type(code[i]).."): "..tostring(code[i]))
      end
      return unpack(code, 1, code.n)    
    end
  else
    self.io_popen = io.popen
    self.os_execute = os.execute
  end

  local function load_fns(fs_table)
     for name, fn in pairs(fs_table) do
        if not self[name] then
           self[name] = fn
        end
     end
  end
  
  -- Load platform-specific functions
  local loaded_platform = nil
  for _, platform in ipairs(platforms) do
     local ok, fs_plat = pcall(require, "luarocks.fs."..platform)
     if ok and fs_plat then
        loaded_platform = platform
        load_fns(fs_plat)
        break
     end
  end

  if use_modules then
    -- Load third-party-module functionality
    local fs_mods = require("luarocks.fs.mods")
    load_fns(fs_mods)
  end

  -- Load platform-independent pure-Lua functionality
  local fs_lua = require("luarocks.fs.lua")
  load_fns(fs_lua)
  
  -- Load platform-specific fallbacks for missing Lua modules
  local ok, fs_plat_tools = pcall(require, "luarocks.fs."..loaded_platform..".tools")
  if ok and fs_plat_tools then
     load_fns(fs_plat_tools)
     load_fns(require("luarocks.fs.tools"))
  end
  
  return self
end

return fs
