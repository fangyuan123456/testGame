local SceneBase = require("app.base.SceneBase")
local TestPanel = require("app.views.panel.TestPanel")
local _M = class("LoadScene",SceneBase)
function _M:ctor()
    _M.super.ctor(self);
    global.panelMgr:openPanel("TestPanel");
end
return _M;