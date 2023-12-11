#include "UnZipManager.h"
#include "lua_CustomRegister.h"
#include "Game.h"
#include "./../../../cocos2d-x/cocos/scripting/lua-bindings/manual/LuaBasicConversions.h"
int tolua_UnZipManager_unZip(lua_State* tolua_S)
{
	int argc = 0;
	bool ok = true;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertable(tolua_S, 1, "Game", 0, &tolua_err)) goto tolua_lerror;
#endif

	argc = lua_gettop(tolua_S) - 1;

	do {
		if (argc == 5)
		{
			std::string arg0;
			ok &= luaval_to_std_string(tolua_S, 2, &arg0, "UnZipManager:unZip");
			if (!ok) {break;}
			std::string arg1;
			ok &= luaval_to_std_string(tolua_S, 3, &arg1, "UnZipManager:unZip");
			if (!ok) { break; }
			std::string arg2;
			ok &= luaval_to_std_string(tolua_S, 4, &arg2, "UnZipManager:unZip");
			if (!ok) { break; }
			LUA_FUNCTION unzipCompleteFunc = toluafix_ref_function(tolua_S, 5, 0);
			LUA_FUNCTION unzipFailFunc = toluafix_ref_function(tolua_S, 6, 0);
			UnZipManager::getInstance()->unZip(arg0, arg1, arg2, [=]() {
				LuaStack* stack = LuaEngine::getInstance()->getLuaStack();
				stack->executeFunctionByHandler(unzipCompleteFunc, 0);
			}, [=]() {
				LuaStack* stack = LuaEngine::getInstance()->getLuaStack();
				stack->executeFunctionByHandler(unzipFailFunc, 0);
			});
			lua_settop(tolua_S, 1);
			return 1;
		}
	} while (0);
#if COCOS2D_DEBUG >= 1
	tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'tolua_UnZipManager_unZip'.", &tolua_err);
#endif
	return 0;
}
int tolua_Game_getBaseVersion(lua_State* tolua_S)
{
	int argc = 0;
	bool ok = true;

#if COCOS2D_DEBUG >= 1
	tolua_Error tolua_err;
#endif


#if COCOS2D_DEBUG >= 1
	if (!tolua_isusertable(tolua_S, 1, "Game", 0, &tolua_err)) goto tolua_lerror;
#endif

	argc = lua_gettop(tolua_S) - 1;
	{
		{
			argc = lua_gettop(tolua_S) - 1;
			string baseVersion = Game::getBaseVersion();
			tolua_pushstring(tolua_S, baseVersion.c_str());
			return 1;
		}
	}
	return 0;
#if COCOS2D_DEBUG >= 1
	tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'tolua_GamBaseVersion'.", &tolua_err);
#endif
	return 0;
}
int tolua_Game_setConsolePrintColor(lua_State * tolua_S)
{
#if(CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
	int argc = 0;
	bool ok = true;
#if COCOS2D_DEBUG >=1 
	tolua_Error tolua_err;
#endif
	WORD color = (WORD)luaL_checknumber(tolua_S, -1);
	SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), color);
	return 0;
#if COCOS2D_DEBUG >= 1
	tolua_lerror:
	tolua_error(tolua_S, "#ferror in function 'tolua_Game_setConsolePrintColor'.", &tolua_err);
#endif
#endif
	return 0;
}
int register_custom_module(lua_State * tolua_S) {
	tolua_usertype(tolua_S, "Game");
	tolua_cclass(tolua_S, "Game", "Game", "cc.Ref", nullptr);
	tolua_beginmodule(tolua_S, "Game");
		tolua_function(tolua_S, "unZip", tolua_UnZipManager_unZip);
		tolua_function(tolua_S, "getBaseVersion", tolua_Game_getBaseVersion);
		tolua_function(tolua_S, "setPrintColor", tolua_Game_setConsolePrintColor);
	tolua_endmodule(tolua_S);
	return 1;
}
TOLUA_API int lua_custom_module_register(lua_State * tolua_S)
{
	tolua_open(tolua_S);
	tolua_module(tolua_S, nullptr, 0);
	tolua_beginmodule(tolua_S, nullptr);
	register_custom_module(tolua_S);
	tolua_endmodule(tolua_S);
	return 1;
}
