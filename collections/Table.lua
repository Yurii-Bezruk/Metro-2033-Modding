require 'collections.List'

Table = {}

Table.methods = {
    size = function(self)
        local size = 0
        for _ in pairs(self) do
            size = size + 1
        end
        return size
    end,
    
    keys = function(self)
        local keys = List{}
        for k in pairs(self) do
            keys:insert(k)
        end
        return keys
    end,
    
    values = function(self)
        local values = List{}
        for _, v in pairs(self) do
            values:insert(v)
        end
        return values
    end,
    
    pairs = function(self)
        local _pairs = List{}
        for k, v in pairs(self) do
            _pairs:insert(List{k, v})
        end
        return _pairs
    end,
    
    containsKey = function(self, key)
        return rawget(self, key) ~= nil
    end,
    
    containsValue = function(self, value)
        for _, v in pairs(self) do
            if v == value then
                return true
            end
        end
        return false
    end,
    
    containsPair = function(self, key, value)
        for k, v in pairs(self) do
            if k == key and v == value then
                return true
            end
        end
        return false
    end,
    
    filter = function(self, predicate)
        local newTable = Table{}
        for k, v in pairs(self) do
            if predicate(k, v) then
                newTable[k] = v
            end
        end
        return newTable
    end,

    findFirstPair = function(self, predicate)
        for k, v in pairs(self) do
            if predicate(k, v) then
                return k, v
            end
        end
    end,

    anyMatch = function(self, predicate)
        return self:findFirstPair(predicate) ~= nil
    end,

    allMatch = function(self, predicate)
        for k, v in pairs(self) do
            if not predicate(k, v) then
                return false
            end
        end
        return true
    end,
    
    map = function(self, mapper)
        local newTable = Table{}
        for k, v in pairs(self) do
            local newK, newV = mapper(k, v)
            newTable[newK] = newV
        end
        return newTable
    end,
    
    flatMap = function(self, mapper)
        local newTable = Table{}
        for key, value in pairs(self) do
            local subtable = mapper(key, value)
            for k, v in pairs(subtable) do 
                newTable[k] = v
            end
        end
        return newTable
    end,        

    forEach = function(self, action)
        for k, v in pairs(self) do
            action(k, v)
        end
        return self
    end
}

Table.metatable = {
    __tostring = function(self)
        local str = '{'
        for k, v in pairs(self) do
            str = str .. k .. '=' .. tostring(v) .. ', '
        end
        return string.sub(str, 1, #str - 2) .. '}'
    end,
    __index = Table.methods,
    __newindex = function (self, k, v)
        assert(not Table.methods[k], "Attempt to override '" .. k .. "' method")
        rawset(self, k, v)
    end
}

function Table:new(input)
    assert(type(input) == 'table', 'Attempt to create Table from non-table value ' .. tostring(input) .. ' <' .. type(input) ..'>')    

    local self = {}
    for k, v in pairs(input) do
        self[k] = v
    end

    return setmetatable(self, Table.metatable)
end

-- make namespace callable
Table = setmetatable(Table, {
    __call = function(self, ...)
        return self:new(...)
    end
})

function Table.deepCopy(input)
    if type(input) ~= 'table' then
        return input
    end
    local copy = {}
    for k, v in pairs(input) do
        copy[k] = Table.deepCopy(v)
    end
    return copy
end