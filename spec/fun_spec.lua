local test_env = require("spec.util.test_env")

describe("#fun #unit tests", function()
   local fun = require("luarocks.fun")

   describe("concat", function()
      
      local cases = {
         { {}, {}, {} },
         { {}, {1}, {1} },
         { {}, {1,2}, {1,2} },
         { {3}, {}, {3} },
         { {3}, {1}, {3,1} },
         { {3}, {1,2}, {3,1,2} },
         { {3,4}, {}, {3,4} },
         { {3,4}, {1}, {3,4,1} },
         { {3,4}, {1,2}, {3,4,1,2} },
      }

      for i, case in ipairs(cases) do
         local l1, l2, l3 = #case[1], #case[2], #case[3]
         local msg = ("%d: case #%d #%d -> #%d"):format(i, l1, l2, l3)
         it(msg, function() 
            local xs = fun.concat(case[1], case[2])
            assert.same(xs, case[3], msg)
            assert.same(l1, #case[1], msg .. " - list 1 is unchanged")
            assert.same(l2, #case[2], msg .. " - list 2 is unchanged")
         end)
      end
   end)
   
   describe("concat_in", function()
      
      local cases = {
         { {}, {}, {} },
         { {}, {1}, {1} },
         { {}, {1,2}, {1,2} },
         { {3}, {}, {3} },
         { {3}, {1}, {3,1} },
         { {3}, {1,2}, {3,1,2} },
         { {3,4}, {}, {3,4} },
         { {3,4}, {1}, {3,4,1} },
         { {3,4}, {1,2}, {3,4,1,2} },
      }
      
      for i, case in ipairs(cases) do
         local msg = ("%d: case #%d #%d -> #%d"):format(i, #case[1], #case[2], #case[3])
         it(msg, function()
            fun.concat_in(case[1], case[2])
            assert.same(case[3], case[1], msg)
         end)
      end
   end)
end)

