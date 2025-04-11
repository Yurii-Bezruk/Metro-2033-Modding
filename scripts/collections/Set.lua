require("scripts.collections.List")

function Set(input)    
    assert(type(input) == 'table', "Attempt to create set from non-table value " .. tostring(input) .. ' <' .. type(input) ..'>')

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
        
        filter = function(self, predicate)
            local newSet = Set{}
            for value in self:iterator() do
                if predicate(value) then
                    newSet:put(value)
                end
            end
            return newSet
        end,

        findFirst = function(self, predicate)
            for value in self:iterator() do
                if predicate(value) then
                    return value
                end
            end
        end,

        anyMatch = function(self, predicate)
            return self:findFirst(predicate) ~= nil
        end,

        allMatch = function(self, predicate)
            for value in self:iterator() do
                if not predicate(value) then
                    return false
                end
            end
            return true
        end,
        
        map = function(self, mapper)
            local newSet = Set{}
            for value in self:iterator() do
                newSet:put(mapper(value))
            end
            return newSet
        end,
        
        flatMap = function(self, mapper)
            local newSet = Set{}
            for value in self:iterator() do
                local subset = mapper(value)
                for elem in subset:iterator() do 
                    newSet:put(elem)
                end
            end
            return newSet
        end,

        forEach = function(self, action)
            for value in self:iterator() do
                action(value)
            end
            return self
        end,

        toList = function (self)
            local list = List{}
            for value in self:iterator() do
                list:insert(value)
            end
            return list
        end
    }

    local self = {}
    for i, v in ipairs(input) do
        self[v] = true
    end

    self = setmetatable(self, {
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