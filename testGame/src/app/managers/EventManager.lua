local singleBase = require("app.base.SingleBase");
local _M = class("EventManager",singleBase)
function _M:ctor()
    self.eventMap = {};
    self.eventIdIndex = 1; 
end
function _M:addEvent(eventName,callFunc,target,eventParameter)
    target = target or -1;
    self.eventMap[eventName] = self.eventMap[eventName] or {};
    table.insert(self.eventMap[eventName],{
        target = target,
        eventParameter = eventParameter,
        callFunc = callFunc,
        eventId = self.eventIdIndex
    })
    self.eventIdIndex = self.eventIdIndex + 1;
    return self.eventIdIndex;
end 
function _M:removeAllEventByTarget(target)
    for _eventName,eventList in pairs(self.eventMap)do
        for i = 1 , #eventList do
            if(eventList[i].target == target)then
                table.remove(eventList,i);
            end
        end
    end
end
function _M:removeEventByName(eventName)
    self.eventMap[eventName] = nil;
end
function _M:removeEvent(eventId)
    for _eventName,eventList in pairs(self.eventMap)do
        for i = 1 , #eventList do
            table.remove(eventList,i);
            break;
        end
    end
end
function _M:dispatchEvent(eventName)
    local eventList = self.eventMap[eventName];
    for i = #eventList ,1,-1 do
        local eventObj = eventList[i];
        if(eventObj.target == -1 or not tolua.isnull(eventObj.target))then
            if(eventObj.callFunc)then
                eventObj.callFunc(eventObj.eventParameter);
            end
        else
            table.remove(eventList,i);
        end
    end
end
return _M;