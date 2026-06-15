local function importList()
    local success, List = pcall(function() return require 'collections.List' end)
    if not success then
        print('Map.<module init>: List module not found, falling back to lua tables')

        List = setmetatable({}, {
            __call = function(self, ...)
                return self:new(...)
            end
        })

        function List:new(input)
            input.size = input.size or #input   
            return input
        end

        function List.pack(...)
            local list = table.pack(...)
            list.size, list.n = list.n, list.size
            return list
        end

        function List:iterator()
            local i = 0
            local size = self.size or #self
            return function()
                i = i + 1
                if i <= size then
                    return i, self[i]
                end
            end
        end
    end
    return List
end

local List = importList()

local DATA_STORAGE = setmetatable({}, {__mode = 'k'})
local TO_STRING_SEEN_STORAGE = setmetatable({}, {__mode = 'k'})

local function getData(self)
    return DATA_STORAGE[self] or self
end

local function hasCustomToString(t)
    local mt = getmetatable(t)
    return type(mt) == 'table' and type(mt.__tostring) == 'function'
end

local Map = setmetatable({}, {
    __call = function(self, ...)
        return self:new(...)
    end,
    __tostring = function()
        return '<class Map>'
    end
})

Map.NIL = setmetatable({}, {__tostring = function() return '<Map.NIL>' end})

local function unnillify(value1, value2)
    if value1 == nil then
        value1 = Map.NIL
    end
    if value2 == nil then
        value2 = Map.NIL
    end
    return value1, value2
end

local function nillify(value1, value2)
    if value1 == Map.NIL then
        value1 = nil
    end
    if value2 == Map.NIL then
        value2 = nil
    end
    return value1, value2
end

function Map:new(input)
    assert(type(input) == 'table', "bad argument #1 to 'Map:new' (table expected, got " .. type(input) .. ')')
    
    local data = getData(input)
    local newMap = {}
    DATA_STORAGE[newMap] = {}
    for k, v in pairs(data) do
        DATA_STORAGE[newMap][k] = v
    end

    rawset(self, '__pairs', function(this)
        return function(state, key)
            local k, v = next(state, key)
            while v == Map.NIL or k == Map.NIL do
                k, v = next(state, k)
            end
            return k, v
        end, getData(this), nil
    end)

    rawset(self, '__index', function(this, key)
        local value, found = self.get(this, key)
        if found then
            return value
        end
        return self[key]
    end)

    rawset(self, '__newindex', function(this, key, value)
        self.set(this, key, value)
    end)

    rawset(self, '__eq', function(this, other)
        return self.equals(this, other)
    end)

    rawset(self, '__concat', function(this, other)
        return self.combine(this, other)
    end)

    rawset(self, '__tostring', function(this)
        return self.toString(this)
    end)

    return setmetatable(newMap, self)
end

function Map.fromEntries(entries)
    assert(type(entries) == 'table', "bad argument #1 to 'Map.fromEntries' (table expected, got " .. type(entries) .. ')')

    local newMap = {}
    for i = 1, #entries do
        local entry = entries[i]
        assert(type(entry) == 'table', "bad argument #1 to 'Map.fromEntries' (bad entry type, table expected, got " .. type(entry) .. ')')

        local key, value = unnillify(entry[1], entry[2])
        newMap[key] = value
    end

    return Map(newMap)
end

function Map.pack(...)
    local args = table.pack(...)

    local newMap = {}
    for i = 1, args.n, 2 do
        local key, value = unnillify(args[i], args[i + 1])
        newMap[key] = value
    end

    return Map(newMap)
end

function Map.generate(generator, sizeOrCondition, identityKey, identityValue)
    assert(type(generator) == 'function', "bad argument #1 to 'Map.generate' (function expected, got " .. type(generator) .. ')')

    if type(sizeOrCondition) == 'number' then
        local size = sizeOrCondition

        local newMap = {}
        local k, v = identityKey, identityValue
        for i = 1, size do
            k, v = generator(k, v)
            local mapK, mapV = unnillify(k, v)
            newMap[mapK] = mapV
        end
        return Map(newMap)
    elseif type(sizeOrCondition) == 'function' then
        local condition = sizeOrCondition

        local newMap = {}
        local k, v = generator(identityKey, identityValue)
        while condition(k, v) do
            local mapK, mapV = unnillify(k, v)
            newMap[mapK] = mapV
            k, v = generator(k, v)
        end
        return Map(newMap)
    else
        error("bad argument #2 to 'Map.generate' (number or function expected, got " .. type(sizeOrCondition) .. ')')
    end
end

function Map:isMap()
    local metatable = self
    repeat
        metatable = getmetatable(metatable)
        if metatable == Map then
            return true
        end
    until metatable == nil
    return false
end

function Map:iterator()
    local function nextEntry(state, key)
        local k, v = next(state, key)
        if k == Map.NIL then
            k, v = next(state, k)
        end
        return k, (nillify(v))
    end
    return nextEntry, getData(self), nil
end

function Map:indexedIterator()
    local indexesMap = {}
    local function nextByIndex(state, i)
        if i > state.size then
            return nil
        end

        local k, v
        if i > #indexesMap then
            k = indexesMap[#indexesMap]
            local start = #indexesMap + 1
            for j = start, i do
                k = next(state.data, k)
                indexesMap[j] = k
            end
        else
            k = indexesMap[i]    
        end

        k, v = next(state.data, k)
        if k == nil then
            return nil
        end
        i = i + 1
        indexesMap[i] = k
        return i, nillify(k, v)
    end
    local invariantState = {data = getData(self)}
    invariantState.size = Map.size(invariantState.data)
    return nextByIndex, invariantState, 0
end

function Map:fullIterator()
    local k, v
    return function()
        k, v = next(getData(self), k)
        if k == nil then
            return nil
        end
        return true, nillify(k, v)
    end
end

function Map:set(key, value)
    key, value = unnillify(key, value)
    getData(self)[key] = value
    return self
end

function Map:update(other)
    assert(type(other) == 'table', "bad argument #1 to 'Map:update' (table expected, got " .. type(other) .. ')')
    
    for _, k, v in Map.fullIterator(other) do
        Map.set(self, k, v)
    end
    return self
end

function Map:get(key, default)    
    key = unnillify(key)
    local result = getData(self)[key]
    if result == nil then
        return (nillify(default)), false
    end
    return (nillify(result)), true
end

function Map:getAll(keys)
    keys = keys or {}
    assert(type(keys) == 'table', "bad argument #1 to 'Map:getAll' (table expected, got " .. type(keys) .. ')')
    
    local data = getData(self)
    local values = {}

    for i, k in List.iterator(keys) do 
        local key = unnillify(k)
        values[i] = nillify(data[key])        
        values.size = i
    end
    return List(values)
end

function Map:slice(keys)
    keys = keys or {}
    assert(type(keys) == 'table', "bad argument #1 to 'Map:slice' (table expected, got " .. type(keys) .. ')')

    local data = getData(self)
    local newMap = Map{}
    for i, k in List.iterator(keys) do
        local key = unnillify(k)
        newMap:set(key, data[key])
    end
    return newMap
end

function Map:keys()
    local size = 0
    local keys = {}
    for _, k in Map.fullIterator(self) do
        size = size + 1
        keys[size] = k
    end
    keys.size = size
    return List(keys)
end

function Map:values()
    local size = 0
    local values = {}
    for _, k, v in Map.fullIterator(self) do
        size = size + 1
        values[size] = v
    end
    values.size = size
    return List(values)
end

function Map:entries()
    local entries = {}
    for _, k, v in Map.fullIterator(self) do
        entries[#entries + 1] = List.pack(k, v)
    end
    return List(entries)
end

function Map:unpack()
    local args = {}
    local size = 0
    for _, k, v in Map.fullIterator(self) do
        args[size + 1] = k
        args[size + 2] = v
        size = size + 2
    end
    return table.unpack(args, 1, size)
end

function Map:getKey(value, default)
    for _, k, v in Map.fullIterator(self) do
        if v == value then
            return k, true
        end
    end
    return (nillify(default)), false
end

function Map:remove(...)
    local keys = table.pack(...)
    local data = getData(self)
    for i = 1, keys.n do
        local key = unnillify(keys[i])
        data[key] = nil
    end
    return self
end

function Map:removeAll(keys)
    keys = keys or {}
    assert(type(keys) == 'table', "bad argument #1 to 'Map:removeAll' (table expected, got " .. type(keys) .. ')')

    local data = getData(self)
    for i, k in List.iterator(keys) do
        data[unnillify(k)] = nil
    end
    return self
end

function Map:containsKey(key)
    return getData(self)[unnillify(key)] ~= nil
end

function Map:containsValue(value)
    local _, found = Map.getKey(self, value)
    return found
end

function Map:containsEntry(key, value)
    key, value = unnillify(key, value)
    return getData(self)[key] == value
end

function Map:size()
    local size = 0
    for _ in Map.fullIterator(self) do
        size = size + 1
    end
    return size
end

function Map:clear()
    if DATA_STORAGE[self] then
        DATA_STORAGE[self] = {}
        return self
    end
    return Map.removeAll(self, Map.keys(self))
end

function Map:inverse()
    local newMap = Map{}
    for _, k, v in Map.fullIterator(self) do
        newMap:set(v, k)
    end
    return newMap
end

function Map:equals(other)
    if type(other) ~= 'table' then
        return false
    end
    if Map.size(self) ~= Map.size(other) then
        return false
    end

    for _, k, v in Map.fullIterator(self) do
        if not Map.containsEntry(other, k, v) then
            return false
        end
    end
    return true
end

function Map:combine(other)
    return Map(self):update(other)
end

function Map:toString()
    if type(self) == 'string' then
        return ('%q'):format(self)
    end
    if type(self) ~= 'table' then
        return tostring(self)
    end
    if not Map.isMap(self) and hasCustomToString(self) then 
        return tostring(self)
    end
    if TO_STRING_SEEN_STORAGE[self] then
        return '<cycle>'
    end

    TO_STRING_SEEN_STORAGE[self] = true
    local str = ''
    for _, k, v in Map.fullIterator(self) do
        if type(k) == 'table' or type(k) == 'function' then
            k = ('[%s]'):format(tostring(k))
        else
            k = Map.toString(k)
        end
        str = ('%s, %s: %s'):format(str, k, Map.toString(v))
    end
    TO_STRING_SEEN_STORAGE[self] = nil
    return '{' .. str:sub(3) .. '}'
end

function Map:toTable()
    local newTable = {}
    for k, v in Map.iterator(self) do
        newTable[k] = v
    end
    return newTable
end

function Map:clone()
    if Map.isMap(self) then
        return Map(self)
    end
    return Map.toTable(self)
end

function Map:filter(predicate)
    assert(type(predicate) == 'function', "bad argument #1 to 'Map:filter' (function expected, got " .. type(predicate) .. ')')

    local newMap = Map{}
    for _, k, v in Map.fullIterator(self) do
        if predicate(k, v) then
            newMap:set(k, v)
        end
    end
    return newMap
end

function Map:find(predicate)
    assert(type(predicate) == 'function', "bad argument #1 to 'Map:find' (function expected, got " .. type(predicate) .. ')')

    for _, k, v in Map.fullIterator(self) do
        if predicate(k, v) then
            return k, v
        end
    end
end

function Map:anyMatch(predicate)
    assert(type(predicate) == 'function', "bad argument #1 to 'Map:anyMatch' (function expected, got " .. type(predicate) .. ')')

    for _, k, v in Map.fullIterator(self) do
        if predicate(k, v) then
            return true
        end
    end
    return false
end

function Map:allMatch(predicate)
    assert(type(predicate) == 'function', "bad argument #1 to 'Map:allMatch' (function expected, got " .. type(predicate) .. ')')

    for _, k, v in Map.fullIterator(self) do
        if not predicate(k, v) then
            return false
        end
    end
    return true
end

function Map:map(mapper)
    assert(type(mapper) == 'function', "bad argument #1 to 'Map:map' (function expected, got " .. type(mapper) .. ')')

    local newMap = Map{}
    for _, k, v in Map.fullIterator(self) do
        newMap:set(mapper(k, v))
    end
    return newMap
end

function Map:flatMap(mapper)
    assert(type(mapper) == 'function', "bad argument #1 to 'Map:flatMap' (function expected, got " .. type(mapper) .. ')')

    local newMap = Map{}
    for _, k, v in Map.fullIterator(self) do
        local result = mapper(k, v)
        assert(type(result) == 'table', "bad response from mapper function in 'Map:flatMap' (table expected, got " .. type(result) .. ')')
        for _, resK, resV in Map.fullIterator(result) do
            newMap:set(resK, resV)
        end
    end
    return newMap
end

function Map:packMap(mapper)
    assert(type(mapper) == 'function', "bad argument #1 to 'Map:packMap' (function expected, got " .. type(mapper) .. ')')

    local newMap = Map{}
    for _, k, v in Map.fullIterator(self) do
        local result = Map.pack(mapper(k, v))
        for _, resK, resV in result:fullIterator() do
            newMap:set(resK, resV)
        end
    end
    return newMap
end

function Map:forEach(action)
    assert(type(action) == 'function', "bad argument #1 to 'Map:forEach' (function expected, got " .. type(action) .. ')')

    for _, k, v in Map.fullIterator(self) do
        action(k, v)
    end
    return self
end

function Map:reduce(reducer, identity)
    assert(type(reducer) == 'function', "bad argument #1 to 'Map:reduce' (function expected, got " .. type(reducer) .. ')')
        
    local accumulator = identity
    for _, k, v in Map.fullIterator(self) do
        accumulator = reducer(accumulator, k, v)
    end
    return accumulator
end

-- TODO remove usages
function Map.deepCopy(input)
    if type(input) ~= 'table' then
        return input
    end
    local copy = {}
    for k, v in pairs(input) do
        copy[k] = Map.deepCopy(v)
    end
    return copy
end

return Map