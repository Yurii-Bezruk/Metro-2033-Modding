local function importList()
    local success, List = pcall(function() return require 'collections.List' end)
    if not success then
        print('Set.<module init>: List module not found, falling back to lua tables')

        List = setmetatable({}, {
            __call = function(self, ...)
                return self:new(...)
            end
        })

        function List:new(input)
            input.size = self.size(input)
            return input
        end

        function List.pack(...)
            local list = table.pack(...)
            list.size, list.n = list.n, list.size
            return list
        end

        function List:iterator()
            local i = 0
            local size = List.size(self)
            return function()
                i = i + 1
                if i <= size then
                    return i, self[i]
                end
            end
        end

        function List:size()
            local size = self.size
            if size and type(size) == 'number' and size >= 0 then
                return size
            end
            return #self
        end
    end
    return List
end

local function importMap()
    local success, Map = pcall(function() return require 'collections.Map' end)
    if not success then
        print('Set.<module init>: Map module not found, falling back to lua tables')

        Map = setmetatable({}, {
            __call = function(self, ...)
                return self:new(...)
            end
        })

        function Map:new(input) 
            return input
        end
    end
    return Map
end

local List = importList()
local Map = importMap()

local DATA_STORAGE = setmetatable({}, {__mode = 'k'})
local TO_STRING_SEEN_STORAGE = setmetatable({}, {__mode = 'k'})

local function getData(self)
    return DATA_STORAGE[self] or self
end

local function hasCustomToString(t)
    local mt = getmetatable(t)
    return type(mt) == 'table' and type(mt.__tostring) == 'function'
end

local Set = setmetatable({}, {
    __call = function(self, ...)
        return self:new(...)
    end,
    __tostring = function()
        return '<class Set>'
    end
})

Set.NIL = setmetatable({}, {__tostring = function() return '<Set.NIL>' end})

local function unnillify(value)
    if value == nil then
        return Set.NIL
    end
    return value
end

local function nillify(value)
    if value == Set.NIL then
        return nil
    end
    return value
end

function Set:new(input)
    assert(type(input) == 'table', "bad argument #1 to 'Set:new' (table expected, got " .. type(input) .. ')')

    local inputSize = List.size(input)

    local newSet = {}
    DATA_STORAGE[newSet] = {}
    for i = 1, inputSize do
        local value = unnillify(input[i])
        DATA_STORAGE[newSet][value] = true
    end

    rawset(self, '__pairs', function(this)
        return function(state, key)
            local k = next(state, key)
            if k == Set.NIL then
                k = next(state, k)
            end
            return k, true
        end, getData(this), nil
    end)

    rawset(self, '__index', function(this, key)
        local contains = self.contains(this, key)
        return contains or self[key]
    end)

    rawset(self, '__newindex', function(this, key, value)
        if type(value) == 'boolean' or type(value) == 'nil' then
            self.set(this, key, value)
            return
        end
        rawset(this, key, value)
    end)

    rawset(self, '__eq', function(this, other)
        return self.equals(this, other)
    end)

    rawset(self, '__add', function(this, other)
        return self.union(this, other)
    end)

    rawset(self, '__sub', function(this, other)
        return self.difference(this, other)
    end)

    rawset(self, '__pow', function(this, other)
        return self.symmetricDifference(this, other)
    end)

    rawset(self, '__mul', function(this, other)
        return self.intersection(this, other)
    end)

    rawset(self, '__lt', function(this, other)
        return self.isSubset(this, other)
    end)

    rawset(self, '__concat', function(this, other)
        return tostring(this) .. tostring(other)
    end)

    rawset(self, '__tostring', function(this)
        return self.toString(this)
    end)

    return setmetatable(newSet, self)
end

function Set.from(input)
    assert(type(input) == 'table', "bad argument #1 to 'Set.from' (table expected, got " .. type(input) .. ')')

    local size = 0
    local newSet = {}
    for k, v in pairs(input) do
        if v then
            size = size + 1
            newSet[size] = k
        end
    end
    newSet.size = size
    return Set(newSet)
end

function Set.pack(...)
    local input = table.pack(...)
    input.size, input.n = input.n, nil
    return Set(input)
end

function Set.generate(generator, sizeOrCondition, identity)
    assert(type(generator) == 'function', "bad argument #1 to 'Set.generate' (function expected, got " .. type(generator) .. ')')
    
    if type(sizeOrCondition) == 'number' then
        local size = sizeOrCondition

        local newSet = {size = size}
        local last = identity
        for i = 1, size do
            last = generator(last)
            newSet[i] = last
        end
        return Set(newSet)
    elseif type(sizeOrCondition) == 'function' then
        local condition = sizeOrCondition

        local i = 0
        local newSet = {}
        local last = generator(identity)
        while condition(last) do
            i = i + 1
            newSet[i] = last
            last = generator(last)
        end
        newSet.size = i
        return Set(newSet)
    else
        error("bad argument #2 to 'Set.generate' (number or function expected, got " .. type(sizeOrCondition) .. ')')
    end
end

function Set:isSet()
    local metatable = self
    repeat
        metatable = getmetatable(metatable)
        if metatable == Set then
            return true
        end
    until metatable == nil
    return false
end

function Set:iterator()
    function nextValue(state, key)
        local k = next(state, key)
        if k == Set.NIL then
            k = next(state, k)
        end
        return k
    end
    return nextValue, getData(self), nil
end

function Set:indexedIterator()
    local indexesMap = {}
    local function nextByIndex(state, i)
        if i > state.size then
            return nil
        end

        local k
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

        k = next(state.data, k)
        if k == nil then
            return nil
        end
        i = i + 1
        indexesMap[i] = k
        return i, nillify(k)
    end
    local invariantState = {data = getData(self)}
    invariantState.size = Set.size(invariantState.data)
    return nextByIndex, invariantState, 0
end

function Set:fullIterator()
    local value
    return function()
        value = next(getData(self), value)
        if value == nil then
            return nil
        end
        if value == Set.NIL then
            return true, nil
        end
        return true, value
    end
end

function Set:insert(value)
    getData(self)[unnillify(value)] = true
    return self
end

function Set:insertAll(values)
    assert(type(values) == 'table', "bad argument #1 to 'Set:insertAll' (table expected, got " .. type(values) .. ')')

    local data = getData(self)
    for i, v in List.iterator(values) do
        data[unnillify(v)] = true
    end
    return self
end

function Set:update(other)
    assert(type(other) == 'table', "bad argument #1 to 'Set:update' (table expected, got " .. type(other) .. ')')
    
    local data = getData(self)
    for _, value in Set.fullIterator(other) do
        data[unnillify(value)] = true
    end
    return self
end

function Set:remove(value)
    getData(self)[unnillify(value)] = nil
    return self
end

function Set:removeAll(values)
    values = values or {}
    assert(type(values) == 'table', "bad argument #1 to 'Set:removeAll' (table expected, got " .. type(values) .. ')')

    local data = getData(self)
    for i, v in List.iterator(values) do
        data[unnillify(v)] = nil
    end
    return self
end

function Set:set(value, state)
    assert(type(state) == 'boolean' or type(state) == 'nil', "bad argument #2 to 'Set:set' (boolean or nil expected, got " .. type(state) .. ')')

    if state then
        return Set.insert(self, value)
    end
    return Set.remove(self, value)
end

function Set:unpack()
    local args = {}
    local size = 0
    for _, value in Set.fullIterator(self) do
        args[size + 1] = value
        size = size + 1
    end
    return table.unpack(args, 1, size)
end

function Set:contains(value)
    if getData(self)[unnillify(value)] then
        return true
    end
    return false
end

function Set:size()
    local size = 0
    for _ in Set.fullIterator(self) do
        size = size + 1
    end
    return size
end

function Set:clear()
    if DATA_STORAGE[self] then
        DATA_STORAGE[self] = {}
        return self
    end
    for _, value in Set.fullIterator(self) do
        Set.remove(self, value)
    end
    return self
end

function Set:equals(other)
    if type(other) ~= 'table' then
        return false
    end
    if Set.size(self) ~= Set.size(other) then
        return false
    end

    for _, value in Set.fullIterator(self) do
        if not Set.contains(other, value) then
            return false
        end
    end
    return true
end

function Set:union(other)
    return Set.from(self):update(other)
end

function Set:difference(other)
    assert(type(other) == 'table', "bad argument #1 to 'Set:difference' (table expected, got " .. type(other) .. ')')

    local newSet = Set{}
    for _, value in Set.fullIterator(self) do
        if not Set.contains(other, value) then
            newSet:insert(value)
        end
    end
    return newSet
end

function Set:symmetricDifference(other)
    assert(type(other) == 'table', "bad argument #1 to 'Set:symmetricDifference' (table expected, got " .. type(other) .. ')')

    local newSet = Set{}
    for _, value in Set.fullIterator(self) do
        if not Set.contains(other, value) then
            newSet:insert(value)
        end
    end
    for _, value in Set.fullIterator(other) do
        if not Set.contains(self, value) then
            newSet:insert(value)
        end
    end
    return newSet
end

function Set:intersection(other)
    assert(type(other) == 'table', "bad argument #1 to 'Set:intersection' (table expected, got " .. type(other) .. ')')

    local newSet = Set{}
    for _, value in Set.fullIterator(self) do
        if Set.contains(other, value) then
            newSet:insert(value)
        end
    end
    return newSet
end

function Set:isSubset(other)
    assert(type(other) == 'table', "bad argument #1 to 'Set:isSubset' (table expected, got " .. type(other) .. ')')

    local newSet = Set{}
    for _, value in Set.fullIterator(self) do
        if not Set.contains(other, value) then
            return false
        end
    end
    return true
end

function Set:isSuperset(other)
    assert(type(other) == 'table', "bad argument #1 to 'Set:isSuperset' (table expected, got " .. type(other) .. ')')

    return Set.isSubset(other, self)
end

function Set:isDisjoint(other)
    assert(type(other) == 'table', "bad argument #1 to 'Set:isDisjoint' (table expected, got " .. type(other) .. ')')

    local newSet = Set{}
    for _, value in Set.fullIterator(self) do
        if Set.contains(other, value) then
            return false
        end
    end
    return true
end

function Set:concat(sep)
    sep = sep or ''
    assert(type(sep) == 'string', "bad argument #1 to 'Set:concat' (string expected, got " .. type(sep) .. ')')
    
    local str = ''
    for _, value in Set.fullIterator(self) do
        str = ('%s%s%s'):format(str, sep, tostring(value))
    end
    return str:sub(#sep + 1)
end

function Set:toString()
    if type(self) == 'string' then
        return ('%q'):format(self)
    end
    if type(self) ~= 'table' then
        return tostring(self)
    end
    if not Set.isSet(self) and hasCustomToString(self) then 
        return tostring(self)
    end
    if TO_STRING_SEEN_STORAGE[self] then
        return '<cycle>'
    end

    TO_STRING_SEEN_STORAGE[self] = true
    local str = ''
    for _, value in Set.fullIterator(self) do
        local valueStr
        if type(value) == 'string' then
            valueStr = ('%q'):format(value)
        else 
            valueStr = tostring(value)
        end
        str = ('%s, %s'):format(str, valueStr)
    end
    TO_STRING_SEEN_STORAGE[self] = nil
    return 'Set{' .. str:sub(3) .. '}'
end

function Set:toTable()
    local newTable = {}
    for value in Set.iterator(self) do
        newTable[value] = true
    end
    return newTable
end

function Set:toList()
    local newList = {}
    local size = 0
    for _, value in Set.fullIterator(self) do
        size = size + 1
        newList[size] = value
    end
    newList.size = size
    return List(newList)
end

function Set:clone()
    if Set.isSet(self) then
        return Set.from(self)
    end
    return Set.toTable(self)
end

function Set:filter(predicate)
    assert(type(predicate) == 'function', "bad argument #1 to 'Set:filter' (function expected, got " .. type(predicate) .. ')')

    local newSet = {}
    local size = 0
    for _, value in Set.fullIterator(self) do
        if predicate(value) then
            size = size + 1
            newSet[size] = value
        end
    end
    newSet.size = size
    return Set(newSet)
end

function Set:find(predicate)
    assert(type(predicate) == 'function', "bad argument #1 to 'Set:find' (function expected, got " .. type(predicate) .. ')')

    for _, value in Set.fullIterator(self) do
        if predicate(value) then
            return value
        end
    end
end

function Set:anyMatch(predicate)
    assert(type(predicate) == 'function', "bad argument #1 to 'Set:anyMatch' (function expected, got " .. type(predicate) .. ')')

    for _, value in Set.fullIterator(self) do
        if predicate(value) then
            return true
        end
    end
    return false
end

function Set:allMatch(predicate)
    assert(type(predicate) == 'function', "bad argument #1 to 'Set:allMatch' (function expected, got " .. type(predicate) .. ')')

    for _, value in Set.fullIterator(self) do
        if not predicate(value) then
            return false
        end
    end
    return true
end

function Set:map(mapper)
    assert(type(mapper) == 'function', "bad argument #1 to 'Set:map' (function expected, got " .. type(mapper) .. ')')

    local newSet = Set{}
    for _, value in Set.fullIterator(self) do
        newSet:insert(mapper(value))
    end
    return newSet
end

function Set:flatMap(mapper)
    assert(type(mapper) == 'function', "bad argument #1 to 'Set:flatMap' (function expected, got " .. type(mapper) .. ')')

    local newSet = Set{}
    for _, value in Set.fullIterator(self) do
        local result = mapper(value)
        assert(type(result) == 'table', "bad response from mapper function in 'Set:flatMap' (table expected, got " .. type(result) .. ')')
        for _, resV in Set.fullIterator(result) do
            newSet:insert(resV)
        end
    end
    return newSet
end

function Set:listMap(mapper)
    assert(type(mapper) == 'function', "bad argument #1 to 'Set:listMap' (function expected, got " .. type(mapper) .. ')')

    local newSet = Set{}
    for _, value in Set.fullIterator(self) do
        local result = mapper(value)
        assert(type(result) == 'table', "bad response from mapper function in 'Set:listMap' (table expected, got " .. type(result) .. ')')
        for i, resV in List.iterator(result) do
            newSet:insert(resV)
        end
    end
    return newSet
end

function Set:packMap(mapper)
    assert(type(mapper) == 'function', "bad argument #1 to 'Set:packMap' (function expected, got " .. type(mapper) .. ')')

    local newSet = Set{}
    for _, value in Set.fullIterator(self) do
        local result = Set.pack(mapper(value))
        for _, resV in result:fullIterator() do
            newSet:insert(resV)
        end
    end
    return newSet
end

function Set:forEach(action)
    assert(type(action) == 'function', "bad argument #1 to 'Set:forEach' (function expected, got " .. type(action) .. ')')

    for _, value in Set.fullIterator(self) do
        action(value)
    end
    return self
end

function Set:reduce(...)
    local args = table.pack(...)
    local reducer = args[1]
    local identity = args[2]
    assert(type(reducer) == 'function', "bad argument #1 to 'Set:reduce' (function expected, got " .. type(reducer) .. ')')
    
    local accumulator
    local identitySet = false

    if args.n > 1 then
        accumulator = identity
        identitySet = true
    end

    for _, value in Set.fullIterator(self) do
        if not identitySet then
            accumulator = value
            identitySet = true
        else
            accumulator = reducer(accumulator, value)
        end
    end
    return accumulator
end

function Set:groupBy(grouper)
    assert(type(grouper) == 'function', "bad argument #1 to 'Set:groupBy' (function expected, got " .. type(grouper) .. ')')

    local groups = Map{}
    for _, value in Set.fullIterator(self) do
        local group = grouper(value)
        if not groups[group] then
            groups[group] = Set{}
        end
        groups[group]:insert(value)
    end
    return groups
end

return Set