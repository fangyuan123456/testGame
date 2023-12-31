local Global_vas = require("app.Global_vas");
global = {
    mgrMap = {};
};
setmetatable(global,{
    __index = function(t,key)
        local requireUrl = Global_vas[key];
        if(requireUrl)then
            local _instance = require(requireUrl):getInstance();
            rawset(t,key,_instance);
            return _instance;
        end
    end
})
function global.init()
end
function global.reInit()
    local checkIsGameScript = function(urlName)
        if(string.find(urlName,"app"))then
            return true;
        end
    end
    local loadedList = package.loaded;
    for k , v in pairs(loadedList) do
        if(checkIsGameScript(k))then
            package.loaded[k] = nil;
            require(k);
        end
    end
end
return global;