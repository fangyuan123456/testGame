local _M = class("SceneBase",cc.Scene)
function _M:ctor()
    global.sceneMgr:setCurScene(self);
    self:enableNodeEvents();
end
return _M;