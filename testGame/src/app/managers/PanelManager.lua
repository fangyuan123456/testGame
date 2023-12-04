local singleBase = require("app.base.SingleBase");
local _M = class("PanelManager",singleBase)
function _M:ctor()
    self.PANEL_URL_LIST = {}
    self.OPENED_PANEL_LIST = {};
    self:insertPanelUrlList("app.config.panelCfg")
end
function _M:openPanel(panelName,parent,data)
    data = data or {};
    if(not self.PANEL_URL_LIST[panelName])then
        global.logMgr:log("%s path can't find!",panelName);
        return;
    end
    local nodeUrl = self.PANEL_URL_LIST[panelName].nodeUrl;
    local classUrl = self.PANEL_URL_LIST[panelName].classUrl;
    local compClass = require(classUrl);
    local comp = nil;
    if(compClass.isPanelBase)then
        local parent = parent or global.sceneMgr:getCurScene();
        local node = global.resMgr:getOrCreateWidget(nodeUrl,true)
        parent:addChild(node);
        comp = node:addComponent(compClass,data.ctorParameter);
        node.classUrl = classUrl;
        node.nodeUrl = nodeUrl;
        node.panelName = panelName;
        local size = parent:getContentSize();
        node:setAnchorPoint(0.5,0.5);
        node:setPosition(size.width/2,size.height/2);
        self.OPENED_PANEL_LIST[panelName] = self.OPENED_PANEL_LIST[panelName] or {};
        table.insert(self.OPENED_PANEL_LIST[panelName],node);
        return node;
    else
        global.logMgr.log("%s is not a panel component",classUrl)
    end
end
function _M:closePanel(panelName,parent)
    local panelName = panel.panelName;
    if(not self.OPENED_PANEL_LIST[panelName] or #self.OPENED_PANEL_LIST[panelName] == 0)then
        global.logMgr:log("%s is not opend!",panelName);
        return;
    end
    local node = nil;
    if(type(panelName) == "string")then
        node = self:getOpendPanel(panelName,parent);
    else
        node = panelName;
    end
    node:_playClosePanel(function()
        for i = 1, #self.OPENED_PANEL_LIST do
            if(self.OPENED_PANEL_LIST[i] == node)then
                node:removeFromParent(true);
                table.remove(self.OPENED_PANEL_LIST,i);
                break;
            end
        end
    end)
end
function _M:insertPanelUrlList(filePath)
    if(not self.panelUrlListMeta)then
        self.panelUrlListMeta = self.panelUrlListMeta or {};
        setmetatable(self.PANEL_URL_LIST,{
            __index = function(_t,key)
                for k , v in pairs(self.panelUrlListMeta) do
                    if(v[key])then
                        return v[key];
                    end
                end
            end
        })
    end
    self.panelUrlListMeta[filePath] = global.utilsMgr:checkAndRequire(filePath);
end
function _M:removePanelUrlList(filePath)
    if(self.panelUrlListMeta[filePath])then
        self.panelUrlListMeta[filePath] = nil;
    end
end
function _M:getOpendPanel(name,parent)
    local openPanelList = self.OPENED_PANEL_LIST[name];
    for i = 1 , #openPanelList do
        if(not parent or openPanelList[i]:getParent() == parent)then
            return openPanelList[i];
        end
    end
end
function _M:checkIsOpenPanel(name,parent)
    if(self:getOpendPanel(name,parent))then
        return true;
    else
        return false;
    end
end
return _M;