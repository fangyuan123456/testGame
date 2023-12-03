local singleBase = require("app.base.SingleBase");
local _M = class("HttpManager",singleBase)
function _M:ctor()
end
function _M:sendReq(data,sucessCallBack,failCallBack,isShowLoadingState)
    if(isShowLoadingState)then
        self:showLoadingState(true);
    end
    local completeCallFunc = function()
        if(isShowLoadingState)then
            self:showLoadingState();
        end
    end
    local requestType = data.requestType or "POST";
    local retryTimes = data.retryTimes or 0;
    local serverUrl = global.define.httpServerUrl;
    if(requestType == "GET")then
        serverUrl = serverUrl .. data.getParamter;
    end
    local http = cc.XMLHttpRequest:new()
    http:setRequestHeader("Content-Type","application/json");
    http:setRequestHeader("charset","utf-8");
    http:open(requestType,serverUrl)
    local requestHeaderMap = data.reqHeadMap or {};
    for k , v in pairs(requestHeaderMap) do
        http:setRequestHeader(k,v);
    end
    http:registerScriptHandler(function()
        if(http.readyState == 4 and (http.status >= 200 and http.status < 207))then
            local data = http.response;
            if(sucessCallBack)then
                sucessCallBack(json.decode(data));
            end
            completeCallFunc();
        else
            if(retryTimes>0)then
                global.scheduleMgr:scheduleOnce(function()
                    data.retryTimes = data.retryTimes - 1;
                    self:sendReq(data,sucessCallBack,failCallBack,isShowLoadingState)
                end,1)
            else
                if(failCallBack)then
                    failCallBack();
                end
                completeCallFunc();
            end
        end
    end)
    if(requestType == "GET")then
        http:send();
    elseif(requestType == "POST")then
        local obj = {
            msgHead = data.msgHead,
            msgData = data.msgData
        }
        local sendData = json.encode(obj);
        http:send(sendData);
    end
end
function _M:showLoadingState(isShow)

end
return _M;