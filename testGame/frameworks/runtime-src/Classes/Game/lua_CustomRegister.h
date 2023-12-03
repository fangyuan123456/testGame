#pragma once 
#include "cocos2d.h"
#include "CCLuaEngine.h"
#include "tolua++.h"
#include "tolua_fix.h"
USING_NS_CC;
TOLUA_API int lua_custom_module_register(lua_State* tolua_S);