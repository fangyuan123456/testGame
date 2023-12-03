local PanelBase = require("app.base.PanelBase")
local _M = class("LoadingPanel",PanelBase);
local LOAD_CFG = {
    [1] = {
        funcName = "checkVersion",
        value = 0.1,
        title = "checkVersion",
        time = 0.5
    },
    [2] = {
        funcName = "downLoadZip",
        value = 0.1,
        title = "downLoadZip",
        time = 1
    },
    [3] = {
        funcName = "changeScene",
        value = 0.1,
        title = "changeScene",
        time = 0.1
    }
}
function _M:onStart()
    _M.super.onStart(self)
    self.loadCfg = clone(LOAD_CFG);
    self.totalProgressNum = 0;
    self.progressNum = 0;
    for k , v in pairs(self.loadCfg) do
        self.totalProgressNum = self.totalProgressNum + v.value;
    end
    self:startRun();
end
function _M:startRun()
    local cfg = table.remove(self.loadCfg,1);
    if(cfg)then
        self:initTitle(cfg)
        if(self[cfg.funcName])then
            self[cfg.funcName](self,cfg)
        end
    end
end
function _M:checkVersion(cfg)
    local nextStepCallBack = self:runProgressWithTime(cfg);
    global.httpMgr:sendReq({
        msgHead = "getZipVersion"
    },function(data)
        global.downLoadMgr.serverZipVersionCfg = data;
        nextStepCallBack();
    end)
end
function _M:downLoadZip(cfg)
    local nextStepCallBack = self:runProgressWithTime(cfg);
    global.downLoadMgr:downLoadRes("game",{
        progressFunc = function(progress,size,totalSize)
        end,
        completeFunc = function(isUpdate)
            if(isUpdate)then
                global:reInit();
            end
            nextStepCallBack();
        end,
        failFunc = function()
        end
    },1)
end
function _M:runProgressWithTime(cfg)
    local startProgressNum = self.progressNum;
    local callFunc = function()
        self.progressNum = startProgressNum + cfg.value;
        self.node.loadBar:stopAllActions();
        self:updateProgress();
        self:startRun();
    end
    if(cfg.time)then
        self.node.loadBar:runAction(cc.ActionFloat:create(cfg.time,0,cfg.value,function(value)
            self.progressNum = startProgressNum + value;
            self:updateProgress();
        end))
    end
    return callFunc;
end
function _M:changeScene(cfg)
    local nextStepCallBack = self:runProgressWithTime(cfg);
    self.node:scheduleOnce(function()
        local MainScene = require("app.views.scene.MainScene")
        local mainScene = MainScene:create();
        display.runScene(mainScene);
    end,0)
end
function _M:updateProgress(progressStr)
    local progressNum = self.progressNum/self.totalProgressNum;
    progressStr = progressStr or math.ceil(progressNum*100).."%";
    self.node.loadBar.bar:setPercent(progressNum*100);
    self.node.loadBar.num:setString(progressStr);
end
function _M:initTitle(cfg)
    self.node.loadBar.title:setString(cfg.title);
end
return _M