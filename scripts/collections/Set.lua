function Set()
    local methods = {
        iterator = function(self)
            local keys = {}
            for key, value in pairs(self) do
                if value then
                    table.insert(keys, key)
                end
            end
            local i = 0;
            return function()
                i = i + 1;
                return keys[i]
            end
        end,

        put = function(self, elem)
            if rawget(self, elem) then
                return
            end
            rawset(self, elem, true)
        end,

        putAll = function(self, arr)
            for i, elem in ipairs(arr) do
                self:put(elem)
            end
        end,

        remove = function(self, elem)
            if rawget(self, elem) then
                rawset(self, elem, false)
            end
        end,

        removeAll = function(self, arr)
            for i, elem in ipairs(arr) do
                self:remove(elem)
            end
        end,

        contains = function(self, elem)
            return rawget(self, elem) == true
        end,

        size = function(self)            
            local size = 0
            for _ in self:iterator() do
                size = size + 1
            end
            return size
        end,
        
        getValues = function (self)
            local values = {}
            for value in self:iterator() do
                table.insert(values, value)
            end
            return values
        end
    }

    local self = setmetatable({}, {
        __tostring = function(self)
            local str = 'Set['
            for elem in self:iterator() do
                str = str .. tostring(elem) .. ', '
            end
            if string.len(str) == 4 then
                return str .. ']'
            end
            return string.sub(str, 1, string.len(str) - 2) .. ']'
        end,
        __index = methods,
        __newindex = function (self, k, v) end
    })

    return self
end