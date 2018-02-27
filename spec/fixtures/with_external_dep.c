#ifdef NODEPS
#define FOO 123
#else
#include <foo/foo.h>
#endif
#include <lua.h>
#include <lauxlib.h>

int luaopen_with_external_dep(lua_State* L) {
   lua_newtable(L);
   lua_pushinteger(L, FOO);
   lua_setfield(L, -2, "foo");
   return 1;
}
