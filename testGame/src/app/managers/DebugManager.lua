local singleBase = require("app.base.SingleBase");
local _M = class("DebugManager",singleBase)
function _M:ctor()
    
end
function _M:registerDebugBlock()
    local breakSocketHandle,_ = require("LuaDebug")("localhost",5441);
    breakSocketHandle();
    if(self.luaBlockDebugTimer)then
        cc.Director:getInstance():unSchedule(self.luaBlockDebugTimer);
    end
    self.luaBlockDebugTimer = cc.Director:getInstance():getScheduler():scheduleScriptFunc(breakSocketHandle,0.3,false);
end
function _M:globalXpcall(fun,resultCb)
    local args = {xpcall(fun,__G__TRACKBACK__)}
    local status = args[1]
    if resultCb then
        resultCb(status);
    end
    if(not status)then
        local msg = args[2];
        global.logMgr.err(msg);
    else
        if(#args>1)then
            local ret = {}
            for i = 2 , #args do
                table.insert(ret,args[i]);
            end
            return unpack(ret);
        end
    end
end
return _M;