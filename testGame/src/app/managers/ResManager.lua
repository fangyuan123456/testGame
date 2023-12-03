local POOLTYPE = {
    WIDGET = 1,
    SPINE = 2
}
local singleBase = require("app.base.SingleBase");
local _M = class("ResManager",singleBase)
function _M:ctor()
    self.nodePool = {
        [POOLTYPE.WIDGET] = {},
        [POOLTYPE.SPINE] = {}
    }
end
function _M:_cacheNode(filePath,createFunc,poolType)
    local nodePool = self.nodePool[poolType];
    local widget = createFunc(filePath);
    widget:retain();
    nodePool[filePath] = widget;
end
function _M:_getOrCreateNode(filePath,createFunc,poolType,isNeedCache)
    local nodePool = self.nodePool[poolType];
    local widget = nil;
    if(nodePool[filePath])then
        widget = nodePool[filePath];
    else
        widget = createFunc(filePath);
        if(isNeedCache)then
            widget:enableNodeEvents();
            local onCleanupFunc = widget.onCleanup_;
            widget.onCleanup_ = function()
                widget:retain();
                nodePool[filePath] = widget;
                if(onCleanupFunc)then
                    onCleanupFunc(widget);
                end
            end
        end
    end
    return widget;
end
function _M:_removeCache(filePath,poolType)
    local nodePool = self.nodePool[poolType];
    if(nodePool[filePath])then
        nodePool[filePath]:release();
        nodePool[filePath] = nil;
    end
end
function _M:getOrCreateWidget(filePath,isNeedCache)
    return self:_getOrCreateNode(filePath,function()
        return cc.CSLoader:createNode(filePath..".csb");
    end,POOLTYPE.WIDGET,isNeedCache)
end
function _M:getOrCreateSpineAni(filePath,isNeedCache)
    return self:_getOrCreateNode(filePath,function()
        return sp.SkeletonAnimation:create(filePath..".json",filePath..".atlas");
    end,POOLTYPE.SPINE,isNeedCache)
end
function _M:cacheWidget(filePath)
    self:_cacheNode(filePath,function()
        cc.CSLoader:createNode(filePath..".csb");
    end,POOLTYPE.WIDGET)
end
function _M:cacheSpinAni(filePath)
    self:_cacheNode(filePath,function()
        return sp.SkeletonAnimation:create(filePath..".json",filePath..".atlas");
    end,POOLTYPE.SPINE)
end
function _M:removeWidgetCache(filePath)
    self:_removeCache(filePath,POOLTYPE.WIDGET);
end
function _M:removeAllWidgetCache()
    for _filePath,v in pairs(self.nodePool[POOLTYPE.WIDGET])do
        self:removeWidgetCache(_filePath);
    end
end
function _M:removeSpineAniCache(filePath)
    self:_removeCache(filePath,POOLTYPE.SPINE)
end
function _M:removeAllSpineAniCache()
    for _filePath,v in pairs(self.nodePool[POOLTYPE.SPINE])do
        self:removeSpineAniCache(_filePath);
    end
end
return _M;