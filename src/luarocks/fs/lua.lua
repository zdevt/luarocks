
--- Native Lua implementation of filesystem and platform abstractions,
-- using LuaFileSystem, LZLib, MD5 and LuaCurl.
-- module("luarocks.fs.lua")
local fs_lua = {}

local cfg = require("luarocks.core.cfg")
local dir = require("luarocks.dir")

local patch = require("luarocks.tools.patch")

--- Test is file/dir is writable.
-- Warning: testing if a file/dir is writable does not guarantee
-- that it will remain writable and therefore it is no replacement
-- for checking the result of subsequent operations.
-- @param file string: filename to test
-- @return boolean: true if file exists, false otherwise.
function fs_lua:is_writable(file)
   assert(file)
   file = dir.normalize(file)
   local result
   if self:is_dir(file) then
      local file2 = dir.path(file, '.tmpluarockstestwritable')
      local fh = io.open(file2, 'wb')
      result = fh ~= nil
      if fh then fh:close() end
      os.remove(file2)
   else
      local fh = io.open(file, 'r+b')
      result = fh ~= nil
      if fh then fh:close() end
   end
   return result
end

local function quote_args(self, command, ...)
   local out = { command }
   for _, arg in ipairs({...}) do
      assert(type(arg) == "string")
      out[#out+1] = self:Q(arg)
   end
   return table.concat(out, " ")
end

--- Run the given command, quoting its arguments.
-- The command is executed in the current directory in the dir stack.
-- @param command string: The command to be executed. No quoting/escaping
-- is applied.
-- @param ... Strings containing additional arguments, which are quoted.
-- @return boolean: true if command succeeds (status code 0), false
-- otherwise.
function fs_lua:execute(command, ...)
   assert(type(command) == "string")
   return self:execute_string(quote_args(self, command, ...))
end

--- Run the given command, quoting its arguments, silencing its output.
-- The command is executed in the current directory in the dir stack.
-- Silencing is omitted if 'verbose' mode is enabled.
-- @param command string: The command to be executed. No quoting/escaping
-- is applied.
-- @param ... Strings containing additional arguments, which will be quoted.
-- @return boolean: true if command succeeds (status code 0), false
-- otherwise.
function fs_lua:execute_quiet(command, ...)
   assert(type(command) == "string")
   if self.verbose then -- omit silencing output
      return self:execute_string(quote_args(self, command, ...))
   else
      return self:execute_string(self:quiet(quote_args(self, command, ...)))
   end
end

--- Checks if the given tool is available.
-- The tool is executed using a flag, usually just to ask its version.
-- @param tool_cmd string: The command to be used to check the tool's presence (e.g. hg in case of Mercurial)
-- @param tool_name string: The actual name of the tool (e.g. Mercurial)
-- @param arg string: The flag to pass to the tool. '--version' by default.
function fs_lua:is_tool_available(tool_cmd, tool_name, arg)
   assert(type(tool_cmd) == "string")
   assert(type(tool_name) == "string")

   arg = arg or "--version"
   assert(type(arg) == "string")

   if not self:execute_quiet(self:Q(tool_cmd), arg) then
      local msg = "'%s' program not found. Make sure %s is installed and is available in your PATH " ..
                  "(or you may want to edit the 'variables.%s' value in file '%s')"
      return nil, msg:format(tool_cmd, tool_name, tool_name:upper(), cfg.which_config().nearest)
   else
      return true
   end
end

--- Check the MD5 checksum for a file.
-- @param file string: The file to be checked.
-- @param md5sum string: The string with the expected MD5 checksum.
-- @return boolean: true if the MD5 checksum for 'file' equals 'md5sum', false + msg if not
-- or if it could not perform the check for any reason.
function fs_lua:check_md5(file, md5sum)
   file = dir.normalize(file)
   local computed, msg = self:get_md5(file)
   if not computed then
      return false, msg
   end
   if computed:match("^"..md5sum) then
      return true
   else
      return false, "Mismatch MD5 hash for file "..file
   end
end

--- List the contents of a directory.
-- @param at string or nil: directory to list (will be the current
-- directory if none is given).
-- @return table: an array of strings with the filenames representing
-- the contents of a directory.
function fs_lua:list_dir(at)
   local result = {}
   for file in self:dir(at) do
      result[#result+1] = file
   end
   return result
end

--- Iterate over the contents of a directory.
-- @param at string or nil: directory to list (will be the current
-- directory if none is given).
-- @return function: an iterator function suitable for use with
-- the for statement.
function fs_lua:dir(at)
   if not at then
      at = self:current_dir()
   end
   at = dir.normalize(at)
   if not self:is_dir(at) then
      return function() end
   end
   return coroutine.wrap(function() self:dir_iterator(at) end)
end

--- Apply a patch.
-- @param patchname string: The filename of the patch.
-- @param patchdata string or nil: The actual patch as a string.
-- @param create_delete boolean: Support creating and deleting files in a patch.
function fs_lua:apply_patch(patchname, patchdata, create_delete)
   local p, all_ok = patch.read_patch(patchname, patchdata)
   if not all_ok then
      return nil, "Failed reading patch "..patchname
   end
   if p then
      return patch.apply_patch(p, 1, create_delete)
   end
end

--- Move a file.
-- @param src string: Pathname of source
-- @param dest string: Pathname of destination
-- @param perms string or nil: Permissions for destination file,
-- or nil to use the source filename permissions.
-- @return boolean or (boolean, string): true on success, false on failure,
-- plus an error message.
function fs_lua:move(src, dest, perms)
   assert(src and dest)
   if self:exists(dest) and not self:is_dir(dest) then
      return false, "File already exists: "..dest
   end
   local ok, err = self:copy(src, dest, perms)
   if not ok then
      return false, err
   end
   self:delete(src)
   if self:exists(src) then
      return false, "Failed move: could not delete "..src.." after copy."
   end
   return true
end

--- Check whether a file is a Lua script
-- When the file can be succesfully compiled by the configured
-- Lua interpreter, it's considered to be a valid Lua file.
-- @param name filename of file to check
-- @return boolean true, if it is a Lua script, false otherwise
function fs_lua:is_lua(name)
  name = name:gsub([[%\]],"/")   -- normalize on fw slash to prevent escaping issues
  local lua = self:Q(dir.path(cfg.variables["LUA_BINDIR"], cfg.lua_interpreter))  -- get lua interpreter configured
  -- execute on configured interpreter, might not be the same as the interpreter LR is run on
  local result = self:execute_string(lua..[[ -e "if loadfile(']]..name..[[') then os.exit() else os.exit(1) end"]])
  return (result == true) 
end

return fs_lua
