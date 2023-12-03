local SceneBase = require("app.base.SceneBase")
local _M = class("LoadScene",SceneBase)
function _M:ctor()
    _M.super.ctor(self);
    local LoadingPanel = global.panelMgr:openPanel("LoadingPanel");
end
return _M;