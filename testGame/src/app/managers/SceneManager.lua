local singleBase = require("app.base.SingleBase");
local _M = class("SceneManager",singleBase)
function _M:setCurScene(scene)
    self.currentScene = scene;
end
function _M:getCurScene()
    return self.currentScene;
end
return _M;