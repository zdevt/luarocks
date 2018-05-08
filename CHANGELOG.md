
What's new in LuaRocks 3.0
==========================

* `luarocks path` now exports versioned variables `LUA_PATH_5_x` and
  `LUA_CPATH_5_x` instead of `LUA_PATH` and `LUA_CPATH`
  when those are in use in your system.
* Package paths are sanitized to only reference the current Lua version.
  For example, if you have `/some/dir/lua/5.1/` in your `$LUA_PATH` and
  you are running Lua 5.2, `luarocks.loader` and the `luarocks` command-line
  tool will convert it to `/some/dir/lua/5.2/`.
* New flag `--temp-key` for `luarocks upload`, allowing you to easily
  upload rocks into an alternate account without disrupting the
  stored configuration of your main account.
* New flag `--dev`, for enabling development-branch sub-repositories.
  This adds support for easily requesting `dev` modules from LuaRocks.org, as in:
  `luarocks install --dev luafilesystem`. The list of URLs configured
  in `rocks_servers` is prepended with a list containing "/dev" in their paths.
* Wrappers installed using `--tree` now prepend the tree's prefix to their
  package paths.

Rockspec 3.0
------------

These features are only enabled if `rockspec_format = "3.0"` is set in the rockspec:

* `build.macosx_deployment_target = "10.9"` is supported in Mac platforms,
  and adjusts `$(CC)` and `$(LD)` variables to export the corresponding
  environment variable.
* LuaJIT can be detected in dependencies and uses version reported by the
  running interpreter: e.g. `"luajit >= 2.1"`.
* Auto-detection of `source.dir` is improved: when the tarball contains
  only one directory at the root, assume that is where the sources are.
* New `description` fields:
  * `labels`, an array of strings;
  * `issues_url`, URL to the project's bug tracker.
* `cmake` build type now supports `build.build_pass` and `build_install_pass`
  to disable `make` passes.
* `git` fetch type fetches submodules by default.
* Patches added in `patches` can create and delete files, following standard
  patch rules.

Internal changes
----------------

* Modules needed by `luarocks.loader` were moved into the `luarocks.core` namespace.
  Modules in `luarocks.core` only depend on other `luarocks.core` modules.
  (Notably, `luarocks.core` does not use `luarocks.fs`.)
* Modules representing `luarocks` commands were moved into the `luarocks.cmd` namespace.
* Modules representing `luarocks-admin` commands were moved into the `luarocks.admin.cmd` namespace.
