local singleBase = require("app.base.SingleBase");
local _M = class("SystemManager",singleBase)
function _M:ctor()
    self.systemMap = {}
end
function _M:addSystem(sysName,filePath)
    if(self.systemMap[sysName])then
        return;
    end
    self.systemMap[sysName] = {};
    self.systemMap[sysName].filePath = filePath;
    self.systemMap[sysName].data = global.utilsMgr:checkAndRequire(filePath..".data");
    global.panelMgr:insertPanelUrlList(filePath..".panelCfg");
    global[sysName.."Data"] = self.systemMap[sysName].data;
end
function _M:removeSystem(sysName)
    if(self.systemMap[sysName])then
        global.panelMgr:removePanelUrlList(self.systemMap[sysName].filePath..".panelCfg")
        self.systemMap[sysName] = nil;
    end
end
return _M;