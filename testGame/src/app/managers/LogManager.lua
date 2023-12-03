local singleBase = require("app.base.SingleBase");
local _M = class("LogManager",singleBase)
local DEBUG_LEVEL = {
    ERROR = 1,
    WARNING = 2,
    LOG = 3
}
local DEBUG_COLOR = {
    [DEBUG_LEVEL.ERROR] = 0X0004,
    [DEBUG_LEVEL.WARNING] = 0X0006,
    [DEBUG_LEVEL.LOG] = 0X0007
}
function _M:ctor()
    self.debugLevel = DEBUG_LEVEL.LOG
end
function _M:log(str,...)
    self:echo(string.format(str,...),DEBUG_LEVEL.LOG);
end
function _M:err(str,...)
    self:echo(string.format(str,...),DEBUG_LEVEL.ERROR);
end
function _M:echo(msgStr,debugLevel)
    if(self.debugLevel>=debugLevel)then
        local color = DEBUG_COLOR[debugLevel];
        Game:setPrintColor(color);
        print("msg:"..msgStr);
        Game:setPrintColor(DEBUG_COLOR[DEBUG_LEVEL.LOG])
    end
end
return _M;