function List(input)
    assert(type(input) == 'table', "Attempt to create list from non-table value " .. tostring(input) .. ' <' .. type(input) ..'>')

    local methods = {
        iterator = function(self)
            local i = 0;
            return function()
                i = i + 1;
                return self[i]
            end
        end,
        
        insert = function(self, elem, position)
            if position == nil then
                table.insert(self, elem)
            else
                table.insert(self, position, elem)
            end
        end,
        
        remove = function(self, position)
            table.remove(self, position)
        end,
        
        size = function(self)
            return #self
        end,
        
        indexOf = function(self, elem)
            for i, value in ipairs(self) do
                if elem == value then
                    return i
                end
            end
            return nil
        end,
        
        contains = function(self, elem)
            return self:indexOf(elem) ~= nil
        end,
        
        filter = function(self, predicate)
            local newList = List{}
            for value in self:iterator() do
                if predicate(value) then
                    newList:insert(value)
                end
            end
            return newList
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
            local newList = List{}
            for value in self:iterator() do
                newList:insert(mapper(value))
            end
            return newList
        end,
        
        flatMap = function(self, mapper)
            local newList = List{}
            for value in self:iterator() do
                local sublist = mapper(value)
                for elem in sublist:iterator() do 
                    newList:insert(elem)
                end
            end
            return newList
        end,

        forEach = function(self, action)
            for value in self:iterator() do
                action(value)
            end
            return self
        end
    }
    
    local self = {}
    for i, v in ipairs(input) do
        self[i] = v
    end

    self = setmetatable(self, {
        __tostring = function(self)            
            local str = '('
            for value in self:iterator() do
                str = str .. tostring(value) .. ', '
            end
            return string.sub(str, 1, string.len(str) - 2) .. ')'
        end,
        __index = methods,
        __newindex = function (self, k, v)
            assert(not methods[k], "Attempt to override '" .. k .. "' method")
            rawset(self, k, v)
        end
    })

    return self
end