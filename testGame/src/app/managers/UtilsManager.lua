local singleBase = require("app.base.SingleBase");
local _M = class("UtilsManager",singleBase)
local fileUtils = cc.FileUtils:getInstance();
function _M:ctor()
    
end
function _M:checkAndRequire(path)
    path = string.gsub(path,"%.","/");
    local isFileExit = fileUtils:isFileExist(path..".luac") or fileUtils:isFileExist(path..".lua");
    if(isFileExit)then
        return require(path);
    end
end
return _M;