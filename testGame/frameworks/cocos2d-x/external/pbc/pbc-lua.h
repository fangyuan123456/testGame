#ifndef _PBC_LUA_H
#define _PBC_LUA_H

#if defined(_USRDLL)
#define CC_DLL111     __declspec(dllexport)
#else         /* use a DLL library */
#define CC_DLL111
#endif

#ifdef __cplusplus
extern "C" {
#endif


	int CC_DLL111 luaopen_protobuf_c(lua_State* L);

#ifdef __cplusplus
}
#endif 
#endif 
