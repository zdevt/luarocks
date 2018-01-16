local test_env = require("spec.util.test_env")

test_env.unload_luarocks()
local is_win = test_env.TEST_TARGET_OS == "windows"

describe("Luarocks fs test #whitebox #w_fs", function()
   describe("fs:Q", function()
      local fs
      
      setup(function()
         local cfg = require("luarocks.core.cfg")
         local fs_init = require("luarocks.fs_init")
         fs = fs_init.new(cfg.platforms, false, cfg.fs_use_modules)
         package.loaded["luarocks.fs"] = fs
      end)
   
      it("simple argument", function()
         assert.are.same(is_win and '"foo"' or "'foo'", fs:Q("foo"))
      end)

      it("argument with quotes", function()
         assert.are.same(is_win and [["it's \"quoting\""]] or [['it'\''s "quoting"']], fs:Q([[it's "quoting"]]))
      end)

      it("argument with special characters", function()
         assert.are.same(is_win and [["\\"%" \\\\" \\\\\\"]] or [['\% \\" \\\']], fs:Q([[\% \\" \\\]]))
      end)
   end)
end)
