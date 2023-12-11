local singleBase = require("app.base.SingleBase");
local userDefault = cc.UserDefault:getInstance();
local fileUtils = cc.FileUtils:getInstance();
local _M = class("UserStrogeManager",singleBase)
function _M:ctor()
    
end
function _M:setStroge(key,value)
    userDefault:setStringForKeys(key,value);
end
function _M:getStroge(key,defaultValue)
    local stroge = userDefault:getStringForKeys(key);
    if(stroge == "")then
        stroge = defaultValue;
    end
    return stroge;
end
function _M:getVersionPath()
    return global.fileMgr:getWritablePath().."version.txt";
end
function _M:getVersionItem(key)
    local path = self:getVersionPath();
    local readStr = io.readfile(path);
    local data = nil;
    if(readStr and readStr~="")then
        local status,msg = xpcall(function()
            data = json.decode(readStr)
        end,__G__TRACKBACK__)
        if(not status)then
            global.log.err("io.readFile fail:%",path);
        else
            if(key)then
                return data[key]
            else
                return data;
            end
        end
    end
end
function _M:setVersionItem(key,value)
    local path = self:getVersionPath();
    local strogeData = self:getVersionItem();
    if(strogeData)then
        strogeData[key] = value;
    else
        strogeData = {};
        strogeData[key] = value;
    end
    local writeStr = json.encode(strogeData);
    local isOk = io.writefile(path,writeStr,"w+");
    if(not isOk)then
        global.logMgr.err("io.writeFile Fail!:%s,%s",writeStr,path)
        return false
    end
    return true;
end
function _M:clearVersionFile()
    local path = self:getVersionPath();
    fileUtils:removeFile(path);
end
return _M;