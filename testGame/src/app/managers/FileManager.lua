local fileUtils = cc.FileUtils:getInstance();
local singleBase = require("app.base.SingleBase");
local _M = class("FileManager",singleBase)
function _M:ctor()
    
end
function _M:getWritablePath()
    return fileUtils:getWritablePath();
end
function _M:isDirectoryExist(dirPath)
    return fileUtils:isDirectoryExist(dirPath);
end
function _M:removeDirectory(dirPath)
    if(self:isDirectoryExist(dirPath))then
        fileUtils:removeDirectory(dirPath);
    end
end
function _M:insertSearchPaths(fileName)
    local insertList = {
        fileName.."res/",
        fileName.."src/"
    }
    local searchList = fileUtils:getSearchPaths();
    local newSearchList = {};
    for i = 1 , #insertList do
        table.insert(newSearchList,self:getWritablePath()..insertList[i]);
    end
    dump(newSearchList)
    fileUtils:setSearchPaths(newSearchList);
end
return _M;