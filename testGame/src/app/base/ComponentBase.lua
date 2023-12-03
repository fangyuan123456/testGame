local _M = class("ComponentBase")
_M.isComponent = true;
function _M:onStart()
    if(not self.isPanelBase)then
        self:setPanelPath(3);
    end
end
function _M:setPanelPath(_layer)
    local info = debug.getinfo(_layer,"S");
    self.panelPath = info.source:sub(3);
    global.logMgr:log(self.panelPath)
end
function _M:onEnter()
    print("onEnter:"..self.__cname);
end
function _M:onExit()
    print("onExit:"..self.__cname);
end
function _M:onDestory()
    print("onDestory:"..self.__cname);
end
return _M;