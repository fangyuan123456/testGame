local ComponentBase = require("app.base.ComponentBase")
local _M = class("GmEventListener",ComponentBase);
function _M:onStart()
    _M.super.onStart(self);
end
function _M:onEnter()
    self:addKeyBoardListener();
end
function _M:onKeyPressed()
    package.loaded["app.gm.ReLoadCmd"] = nil;
    require("app.gm.ReLoadCmd")
end
function _M:onKeyReleased()

end
function _M:addKeyBoardListener()
    local node = self.node;
    if(device.platform == "windows")then
        local listener = cc.EventListenerKeyboard:create()
        listener:registerScriptHandler(self.onKeyPressed,cc.Handler.EVENT_KEYBOARD_PRESSED);
        listener:registerScriptHandler(self.onKeyReleased,cc.Handler.EVENT_KEYBOARD_RELEASED);
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener,node);
    end
end
return _M;