local PanelBase = require("app.base.PanelBase")
local _M = class("TestPanel",PanelBase);
function _M:onStart()
    _M.super.onStart(self)
    self:addFntNode();    
end
function _M:addFntNode()
    local fntNode = ccui.TextBMFont:create("","fnt/common_font_withe.fnt")
    self.node:addChild(fntNode);
    fntNode:setString(global.downLoadMgr:getLocalDownLoadVersion("game"));
    fntNode:setPosition(self.node:getCenterPos());
end
return _M;