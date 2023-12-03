local ComponentBase = require("app.base.ComponentBase")
local _M = class("PanelBase",ComponentBase)
_M.isPanelBase = true;
function _M:ctor(parameter,panelType)
    _M.super.ctor(self);
    self.parameter = parameter or {};
    self.panelType = panelType or Constant.PANEL_TYPE.PANEL;
end
function _M:onStart()
    _M.super.onStart(self);
    self:setPanelPath(3);
    local node = self.node;
    local metatable = tolua.getpeer(node);
    setmetatable(metatable,{
        __index = function(t,key)
            return self[key]
        end
    })
    self:configUITree(self.node);
end
function _M:closeSelf()
    global.panelMgr:closePanel(self);
end
function _M:onExit()
    _M.super.onExit(self);
    if(self.parameter.closePanelCallBack)then
        self.parameter.closePanelCallBack(self);
    end
end
function _M:configUITree(node)
    local children = node:getChildren();
    for k , v in pairs(children) do
        node[v:getName()] = v;
        self:configUITree(v);
    end
end
function _M:reloadPanel()
    self.node:reLoadAllComponent();
end
function _M:_playClosePanel(callBack)
    if(callBack)then
        callBack();
    end
end
function _M:closePanel()
    global.panelMgr:closePanel(self);
end
return _M;