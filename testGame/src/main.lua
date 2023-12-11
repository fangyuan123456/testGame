
cc.FileUtils:getInstance():setPopupNotify(false)
require "app.init"

local function main()
    global.init();
    global.debugMgr:registerDebugBlock();
    local LoadScene = require("app.views.scene.LoadScene");
    local loadScene = LoadScene:create();
    display.runScene(loadScene);
end
global.debugMgr:globalXpcall(main);