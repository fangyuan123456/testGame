local singleBase = require("app.base.SingleBase");
local _M = class("ScheduleManager",singleBase)
local scheduler = cc.Director:getInstance():getScheduler();
function _M:scheduleOnce(callBack,delayTime,target)
    local scheduleId = nil;
    scheduleId = scheduler:scheduleScriptFunc(function()
        if(not target or not tolua.isnull(target))then
            callBack(target)
        end
        self:unScedule(scheduleId)
    end,delayTime or 0,false);
    if(target)then
        target.scheduleIdMap = target.scheduleIdMap or {};
        table.insert(target.scheduleIdMap,scheduleId)
    end
    return scheduleId
end
function _M:schedule(callBack,delayTime,target)
    local scheduleId = nil;
    scheduleId = scheduler:scheduleScriptFunc(function()
        if(not target or not tolua.isnull(target))then
            callBack(target);
        else
            self:unSchedule(scheduleId)
        end
    end,delayTime or 0,false)
    if(target)then
        target.scheduleIdMap = target.scheduleIdMap or {};
        table.insert(target.scheduleIdMap,scheduleId)
    end
    return scheduleId
end
function _M:unSchedule(scheduleId)
    if(scheduleId)then
        scheduler:unscheduleScriptEntry(scheduleId)
    end
end
function _M:unScheduleAll(target)
    target.scheduleIdMap = target.scheduleIdMap or {};
    for i = 1,#target.scheduleIdMap do
        self:unSchedule(target.scheduleIdMap[i])
    end
    target.scheduleIdMap = {}
end
return _M;