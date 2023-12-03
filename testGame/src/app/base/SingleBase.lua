local _M = class("SingleBase")
function _M:ctor()
    
end
function _M:getInstance()
    if(not self._instance)then
        self._instance = self:new();
    end
    return self._instance;
end
return _M;