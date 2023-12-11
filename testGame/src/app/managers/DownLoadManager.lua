local singleBase = require("app.base.SingleBase");
local _M = class("DownLoadManager",singleBase)
function _M:ctor()
    self.serverZipVersionCfg = nil;
    self.downLoadProgramMap = {};
    self.downLoadOrder = 999;
end
function _M:getDownLoadCfg(versionFileName)
    local versionTypeList = string.split(versionFileName,".zip");
    local obj = {};
    if(#versionTypeList == 2)then
        local versionList = string.split(versionTypeList[1],"_");
        if(versionList[2])then
            obj.version = versionList[2];
        end
        obj.fileName = versionList[1]..".zip";
        obj.dirName = versionList[1];
        if(versionList[1] == "game")then
            obj.destPath = versionList[1].."/";
        else
            obj.destPath = "downLoad/"..versionList[1].."/";
        end
        obj.unZipPath = versionTypeList[1].."_temp/";
        obj.url = versionList[1].."/"..versionFileName;
    end
    return obj;
end
function _M:getServerZipVersionCfg(versionFileName)
    local versionTypeList = string.split(versionFileName,".");
    local versionList = string.split(versionTypeList[1],"_");
    local fileName = versionList[1];
    return self.serverZipVersionCfg[fileName];
end
function _M:getDownLoader()
    if(not self.downLoader)then
        self.downLoader = cc.Donwloader:new({
            countOfMaxProcessingTasks = 32,
            timeoutInSecconds = 120
        })
        self:_addDownloadExEvents(self.downLoader)
    end
    return self.downLoader;
end
function _M:checkAndUnZipFile(versionFileName)
    local downLoadCfg = self:getDownLoadCfg(versionFileName);
    self:setDownLoadState(versionFileName,Constant.DONWLOAD_STATE.DECOMPRESSION)
    self:unZipFile(versionFileName);
    return true;
end
function _M:_addDownloadExEvents(downLoader)
    downLoader.setOnTaskProgress(function(task,bytesReceived,totalBytesReceived,totalBytesExpected)
        global.debugMgr:globalXpcall(function()
            local versionFileName = task.identifier;
            local programObj = self.downLoadProgramMap[versionFileName];
            programObj.progressData.totalBytesReceived = totalBytesReceived;
            programObj.progressData.bytesReceived = bytesReceived;
            programObj.progressData.totalBytesExpected = totalBytesExpected;
            self:runDownLoadFunc(versionFileName);
        end)
    end)
    downLoader:setOnFileTaskSuccess(function(task)
        global.debugMgr:globalXpcall(function()
            local versionFileName = task.identifier;
            if(not self:checkAndUnZipFile(versionFileName))then
                self:setDownLoadState(versionFileName,Constant.DONWLOAD_STATE.COMPRESSION_END);
                self:runDownLoadFunc(versionFileName);
            end
        end)
    end)
    downLoader:setOnTaskError(function(task,errorCode,errorCodeInternal,errorStr)
        global.debugMgr:globalXpcall(function()
            local versionFileName = task.identifier;
            local programObj = self.downLoadProgramMap[versionFileName];
            programObj.retryTimes = programObj.retryTimes - 1;
            if(programObj.retryTimes<0)then
                self:setDownLoadState(versionFileName,Constant.DONWLOAD_STATE.DOWN_LOAD_FAIL)
                self:runDownLoadFunc(versionFileName);
            else
                global.scheduleMgr:scheduleOnce(function()
                    self:startDownLoad(versionFileName);
                end,1)
            end        
        end)
    end)
end
function _M:compareVersion(version1,version2)
    local localList = string.split(version1,".");
    local serverList = string.split(version2,".");
    for i = 1,#serverList do
        if(localList[i]~=serverList[i])then
            return localList[i] < serverList[i];
        end
    end
end
function _M:getDownLoadVersionNameList(fileName)
    local cfg = self:getServerZipVersionCfg(fileName);
    if(cfg)then
       local localVersion = self:getLocalDownLoadVersion(fileName); 
        if(not localVersion)then
            self:setLocalDownLoadVersion(fileName,cfg.versionList[#cfg.versionList]);
        end
        local downLoadVersionNameList = {};
        table.sort(cfg.versionList,function(a,b)
            return self:compareVersion(a,b);
        end)
        for i = 1, #cfg.versionList do
            if(self:compareVersion(localVersion,cfg.versionList[i]))then
                for j = i,#cfg.versionList do
                    local fileNameList = string.split(fileName,".");
                    table.insert(downLoadVersionNameList,fileNameList[1].."_"..cfg.versionList[j]..".zip")
                end
                break;
            end
        end
        return downLoadVersionNameList;
    else
        return {};
    end
end
function _M:checkAndCleanStroge(fileName)
    local cleanStrogeFunc = function(_fileName)
        local writablePath = global.fileMgr:getWritablePath();
        local dirPath = writablePath.. _fileName.."/";
        global.fileMgr:removeDirectory(dirPath);
    end
    local baseVersion = Game:getBaseVersion();
    local strogeVersion = self:getLocalDownLoadVersion(fileName);
    if(not strogeVersion or not  self:compareVersion(baseVersion,strogeVersion))then
        cleanStrogeFunc(fileName);
        self:setLocalDownLoadVersion(fileName,baseVersion);
    end
end
function _M:downLoadRes(fileName,parameter,downLoadOrder)
    self:checkAndCleanStroge(fileName);
    local fileList = self:getDownLoadVersionNameList(fileName);
    local progressCallFunc = function()
        if(parameter.progressFunc)then
            parameter.progressFunc();
        end
    end
    local completeCallFunc = function()
        global.fileMgr:insertSearchPaths(fileName);
        if(parameter.completeFunc)then
            parameter.completeFunc();
        end
    end
    local index = 0;
    local downLoadFunc = nil;
    downLoadFunc = function()
        index = index + 1;
        local versionFileName = fileList[index];
        if(not versionFileName)then
          completeCallFunc();  
          return;
        end
        local downLoadCfg = self:getDownLoadCfg(versionFileName);
        local downLoadState = nil;
        downLoadState = self:getDownLoadState(versionFileName);
        if(not self.downLoadProgramMap[versionFileName])then
            self.downLoadProgramMap[versionFileName] = {
                state = tonumber(downLoadState),
                progressList = {};
                completeList = {};
                failList = {},
                progressData = {
                    bytesReceived = 0,
                    totalBytesReceived = 0,
                    totalBytesExpected = 0
                },
                downLoadOrder = downLoadOrder,
                retryTimes = parameter.retryTimes or 1;
            }
        end
        table.insert(self.downLoadProgramMap[versionFileName].progressList,progressCallFunc);
        table.insert(self.downLoadProgramMap[versionFileName].completeList,downLoadFunc);
        table.insert(self.downLoadProgramMap[versionFileName].failList,parameter.failFunc);
        self:downLoadByOrder();
        self:runDownLoadFunc(versionFileName,true)
    end
    downLoadFunc();
end
function _M:setLocalDownLoadVersion(versionFileName,version)
    local fileName = nil;
    if(version)then
        fileName = versionFileName;
    else
        local downLoadCfg = self:getDownLoadCfg(versionFileName);
        fileName = downLoadCfg.dirName;
        version = downLoadCfg.version;
    end

    if(self.downLoadProgramMap[versionFileName])then
        self.downLoadProgramMap[versionFileName].localVersion = version;
    end
    global.userStrogeMgr:setVersionItem(fileName.."_version",version);
end
function _M:getLocalDownLoadVersion(fileName)
    local localVersion = global.userStrogeMgr:getVersionItem(fileName.."_version")
    return localVersion;
end
function _M:setDownLoadState(versionFileName,state)
    if(self.downLoadProgramMap[versionFileName])then
        self.downLoadProgramMap[versionFileName].state  = state;
        local downLoadCfg = self:getDownLoadCfg(versionFileName);
        global.userStrogeMgr:setVersionItem(downLocalCfg.dirName.."_state",state);
    end
end
function _M:downLoadByOrder()
    local downOrderMap = {};
    for k , v in pairs(self.downLoadProgramMap)do
        if(v.state ~= Constant.DONWLOAD_STATE.COMPRESSION_END)then
            downOrderMap[v.downLoadOrder] = downOrderMap[v.downLoadOrder] or {};
            v.fileName = k;
            table.insert(downOrderMap[v.downLoadOrder],v);
        end
    end
    for i = 1, 100 do
        if(downOrderMap[i])then
            if(i<self.downLoadOrder)then
                if(downOrderMap[self.downLoadOrder])then
                    for j = 1, #downOrderMap[self.downLoadOrder] do
                        self:stopDownLoad(downOrderMap[self.downLoadOrder][j].fileName);
                    end
                end
                self.downLoadOrder = i;
                for j = 1,#downOrderMap[i] do
                    self:startDownLoad(downOrderMap[i][j].fileName);
                end
            end
        end
    end
end
function _M:unZipFile(versionFileName)
    local downLoadCfg = self:getDownLoadCfg(versionFileName);
    local fileName = downLoadCfg.fileName;
    local writeablePath = global.fileMgr:getWritablePath();
    local zipPath = writeablePath..versionFileName;
    local unZipPath = writeablePath..downLoadCfg.unZipPath;
    local destPath = writeablePath..downLoadCfg.destPath;
    Game:unZip(zipPath,unZipPath,destPath,function()
        self:setDownLoadState(versionFileName,Constant.DONWLOAD_STATE.COMPRESSION_END)
        self:runDownLoadFunc(versionFileName);
    end,function()
    
    end);
end
function _M:startDownLoad(versionFileName)
    local programObj = self.downLoadProgramMap[versionFileName];
    if(programObj.state == Constant.DONWLOAD_STATE.DECOMPRESSION)then
        self:unZipFile(versionFileName);
    else
        local downLoader = self:getDownLoader();
        local downLocalCfg = self:getDownLoadCfg(versionFileName);
        local fullUrl = global.define.downLoadUrl..downLoadCfg.url;
        local downLoadSavePath = global.fileMgr:getWritablePath()..versionFileName;
        downLoader:createDownloadFileTask(fullUrl,downLoadSavePath,versionFileName);
        self:setDownLoadState(versionFileName,Constant.DONWLOAD_STATE.DOWN_LOAD);
        self:runDownLoadFunc(versionFileName);
    end
end
function _M:stopDownLoad(versionFileName)
end
function _M:runDownLoadFunc(versionFileName,isRunLastFunc)
    local downLoadCfg = self:getDownLoadCfg(versionFileName);
    local obj = self.downLoadProgramMap[versionFileName];
    local progressList = obj.progressList;
    local completeList = obj.completeList;
    local failList = obj.failList;
    local startIndex = 1;
    if(isRunLastFunc)then
        startIndex = #progressList;
    end
    if(obj.state == Constant.DONWLOAD_STATE.DOWN_LOAD)then
        for i = startIndex,#progressList do
            local callFunc = progressList[i];
            local progressData = obj.progressData;
            local progress = (progressData.bytesReceived/progressData.totalBytesReceived)-0.1;
            callFunc(progress,progressData.bytesReceived,progressData.totalBytesReceived)
        end
    elseif(obj.state == Constant.DONWLOAD_STATE.COMPRESSION_END)then
        for i = startIndex,#progressList do
            local callFunc = progressList[i];
            callFunc(1);
        end
        for i = startIndex,#completeList do
            local callFunc = completeList[i];
            callFunc();
        end
        self:setLocalDownLoadVersion(versionFileName);
    elseif(obj.state == Constant.DONWLOAD_STATE.DOWN_LOAD_FAIL)then
        for i = startIndex , #failList do
            local callFunc = failList[i];
            callFunc();
        end
    end
end
return _M;