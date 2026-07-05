local function importList()
    local success, List = pcall(function() return require 'collections.List' end)
    if not success then
        print('Deque.<module init>: List module not found, falling back to lua tables')

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

local List = importList()

local DATA_STORAGE = setmetatable({}, {__mode = 'k'})

local function getData(self)
    local data = DATA_STORAGE[self]
    if not data then
        data = {
            startIndex = 1,
            endIndex = List.size(self)
        }
        DATA_STORAGE[self] = data
    end
    return data
end

local TO_STRING_SEEN_STORAGE = setmetatable({}, {__mode = 'k'})

local function hasCustomToString(t)
    local mt = getmetatable(t)
    return type(mt) == 'table' and type(mt.__tostring) == 'function'
end

local Deque = setmetatable({}, {
    __call = function(self, ...)
        return self:new(...)
    end,
    __tostring = function()
        return '<class Deque>'
    end
})

function Deque:new(input)
    input = input or {}
    assert(type(input) == 'table', "bad argument #1 to 'Deque:new' (table expected, got " .. type(input) .. ')')

    local newDeque = {}
    local size = List.size(input)
    for i = 1, size do
        newDeque[i] = input[i]
    end
    DATA_STORAGE[newDeque] = {
        startIndex = 1,
        endIndex = size
    }

    self.__index = self

    self.__eq = function(this, other)
        return self.equals(this, other)
    end

    self.__add = function(this, other)
        return self.combine(this, other)
    end

    self.__concat = function(this, other)
        return tostring(this) .. tostring(other)
    end

    self.__tostring = function(this)
        return self.toString(this)
    end

    return setmetatable(newDeque, self)
end

function Deque.pack(...)
    local input = table.pack(...)
    input.size, input.n = input.n, nil
    return Deque(input)
end

function Deque.generate(generator, sizeOrCondition, identity)
    assert(type(generator) == 'function', "bad argument #1 to 'Deque.generate' (function expected, got " .. type(generator) .. ')')
    
    if type(sizeOrCondition) == 'number' then
        local size = sizeOrCondition

        local newDeque = {size = size}
        local last = identity
        for i = 1, size do
            last = generator(last)
            newDeque[i] = last
        end
        return Deque(newDeque)
    elseif type(sizeOrCondition) == 'function' then
        local condition = sizeOrCondition

        local i = 0
        local newDeque = {}
        local last = generator(identity)
        while condition(last) do
            i = i + 1
            newDeque[i] = last
            last = generator(last)
        end
        newDeque.size = i
        return Deque(newDeque)
    else
        error("bad argument #2 to 'Deque.generate' (number or function expected, got " .. type(sizeOrCondition) .. ')')
    end
end

function Deque:isDeque()
    local metatable = self
    repeat
        metatable = getmetatable(metatable)
        if metatable == Deque then
            return true
        end
    until metatable == nil
    return false
end

function Deque:iterator()
    local data = getData(self)

    local function next(state, i)
        if i < state.from then
            return nil
        end
        i = i + 1
        if i <= state.to then
            return i, state.deque[i + state.startIndex - 1]
        end
    end
    return next, {deque = self, startIndex = getData(self).startIndex, from = 0, to = Deque.size(self)}, 0
end

function Deque:reverseIterator()
    local data = getData(self)
    local from = Deque.size(self) + 1

    local function next(state, i)
        if i > state.from then
            return nil
        end
        i = i - 1
        if i >= state.to then
            return i, state.deque[i + state.startIndex - 1]
        end
    end
    return next, {deque = self, startIndex = getData(self).startIndex, from = from, to = 1}, from
end

function Deque:valuesIterator()
    local data = getData(self)
    local i = data.startIndex - 1
    local deque = self
    return function()
        repeat
            i = i + 1
        until i > data.endIndex or deque[i]
        if i <= data.endIndex then
            return deque[i]
        end
    end
end

function Deque:pushLeft(value)
    local data = getData(self)
    data.startIndex = data.startIndex - 1
    self[data.startIndex] = value
    return self
end

function Deque:pushAllLeft(values)
    assert(type(values) == 'table', "bad argument #1 to 'Deque:pushAllLeft' (table expected, got " .. type(values) .. ')')

    local data = getData(self)
    local startIndex = data.startIndex
    for i = 1, List.size(values) do
        startIndex = startIndex - 1
        self[startIndex] = values[i]
    end
    data.startIndex = startIndex
    return self
end

function Deque:pushRight(value)
    local data = getData(self)
    data.endIndex = data.endIndex + 1
    self[data.endIndex] = value
    return self
end

function Deque:pushAllRight(values)
    assert(type(values) == 'table', "bad argument #1 to 'Deque:pushAllRight' (table expected, got " .. type(values) .. ')')

    local data = getData(self)
    local endIndex = data.endIndex
    for i = 1, List.size(values) do
        endIndex = endIndex + 1
        self[endIndex] = values[i]
    end
    data.endIndex = endIndex
    return self
end

function Deque:popLeft()
    if Deque.size(self) == 0 then
        return nil, false
    end
    local data = getData(self)
    local value = rawget(self, getData(self).startIndex)
    self[data.startIndex] = nil
    data.startIndex = data.startIndex + 1
    return value, true
end

function Deque:popRight()
    if Deque.size(self) == 0 then
        return nil, false
    end
    local data = getData(self)
    local value = rawget(self, getData(self).endIndex)
    self[data.endIndex] = nil
    data.endIndex = data.endIndex - 1
    return value, true
end

function Deque:peekLeft()
    if Deque.size(self) == 0 then
        return nil, false
    end
    return rawget(self, getData(self).startIndex), true
end

function Deque:peekRight()
    if Deque.size(self) == 0 then
        return nil, false
    end
    return rawget(self, getData(self).endIndex), true
end

function Deque:removeLeft()    
    if Deque.size(self) == 0 then
        return self
    end
    local data = getData(self)
    self[data.startIndex] = nil
    data.startIndex = data.startIndex + 1
    return self
end

function Deque:removeRight()
    if Deque.size(self) == 0 then
        return self
    end
    local data = getData(self)
    self[data.endIndex] = nil
    data.endIndex = data.endIndex - 1
    return self
end

function Deque:unpack()
    local data = getData(self)
    return table.unpack(self, data.startIndex, data.endIndex)
end

function Deque:contains(value)
    for i, v in Deque.iterator(self) do
        if v == value then
            return true
        end
    end
    return false
end

function Deque:size()
    local data = getData(self)
    return data.endIndex - data.startIndex + 1
end

function Deque:clear()
    local data = getData(self)
    for i = data.startIndex, data.endIndex do
        rawset(self, i, nil)
    end
    if List.size(self) > 0 then
        self.size = 0
    end
    data.startIndex = 1
    data.endIndex = #self
    return self
end

function Deque:reverse()
    local size = Deque.size(self)
    local newDeque = {size = size}

    for i, v in Deque.reverseIterator(self) do
        local j = size - i + 1
        newDeque[j] = v
    end    
    return Deque(newDeque)
end

function Deque:equals(other)
    if type(other) ~= 'table' then
        return false
    end
    if Deque.size(self) ~= Deque.size(other) then
        return false
    end
    
    local next, state, seed = Deque.iterator(other)
    local i2, v2 = seed, nil
    for i1, v1 in Deque.iterator(self) do
        i2, v2 = next(state, i2)
        if v1 ~= v2 then
            return false
        end
    end
    return true
end

function Deque:combine(other)
    assert(type(other) == 'table', "bad argument #1 to 'Deque:combine' (table expected, got " .. type(other) .. ')')

    local selfSize = Deque.size(self)
    local otherSize = Deque.size(other)
    local newDeque = {}
    for i, v in Deque.iterator(self) do
        newDeque[i] = v
    end
    for i, v in Deque.iterator(other) do
        newDeque[i + selfSize] = v
    end
    newDeque.size = selfSize + otherSize
    return Deque(newDeque)
end

function Deque:concat(sep)
    sep = sep or ''
    assert(type(sep) == 'string', "bad argument #1 to 'Deque:concat' (string expected, got " .. type(sep) .. ')')
    
    local str = ''
    for i, v in Deque.iterator(self) do
        str = ('%s%s%s'):format(str, sep, tostring(v))
    end
    return str:sub(#sep + 1)
end

function Deque:toString()
    if type(self) == 'string' then
        return ('%q'):format(self)
    end
    if type(self) ~= 'table' then
        return tostring(self)
    end
    if not Deque.isDeque(self) and hasCustomToString(self) then 
        return tostring(self)
    end
    if TO_STRING_SEEN_STORAGE[self] then
        return '<cycle>'
    end

    TO_STRING_SEEN_STORAGE[self] = true
    local str = ''
    local data = getData(self)
    for i, v in Deque.iterator(self) do
        local valueStr
        if type(v) == 'string' then
            valueStr = ('%q'):format(v)
        else 
            valueStr = tostring(v)
        end
        str = ('%s, %s'):format(str, valueStr)
    end
    TO_STRING_SEEN_STORAGE[self] = nil
    return 'Deque{' .. str:sub(3) .. '}'
end

function Deque:toTable()
    local newTable = {}
    for i, v in Deque.iterator(self) do
        newTable[i] = v
    end
    return newTable
end

function Deque:toList()
    local newList = Deque.toTable(self)
    newList.size = Deque.size(self)
    return List(newList)
end

function Deque:clone()
    if Deque.isDeque(self) then
        local newDeque = Deque.toTable(self)
        newDeque.size = Deque.size(self)
        return Deque(newDeque)
    end
    return Deque.toTable(self)
end

function Deque:map(mapper)
    assert(type(mapper) == 'function', "bad argument #1 to 'Deque:map' (function expected, got " .. type(mapper) .. ')')

    local newDeque = {size = Deque.size(self)}
    for i, v in Deque.iterator(self) do
        newDeque[i] = mapper(v)
    end
    return Deque(newDeque)
end

function Deque:flatMap(mapper)
    assert(type(mapper) == 'function', "bad argument #1 to 'Deque:flatMap' (function expected, got " .. type(mapper) .. ')')
    
    local newDeque = {}
    local size = 0
    for i, v in Deque.iterator(self) do
        local result = mapper(v)
        assert(type(result) == 'table', "bad response from mapper function in 'Deque:flatMap' (table expected, got " .. type(result) .. ')')
        for _, resV in Deque.iterator(result) do
            size = size + 1
            newDeque[size] = resV
        end
    end
    return Deque(newDeque)
end

function Deque:packMap(mapper)
    assert(type(mapper) == 'function', "bad argument #1 to 'Deque:packMap' (function expected, got " .. type(mapper) .. ')')
    
    local newDeque = {}
    local size = 0
    for i, v in Deque.iterator(self) do
        local result = Deque.pack(mapper(v))
        for _, resV in result:iterator() do
            size = size + 1
            newDeque[size] = resV
        end
    end
    return Deque(newDeque)
end

function Deque:forEach(action)
    assert(type(action) == 'function', "bad argument #1 to 'Deque:forEach' (function expected, got " .. type(action) .. ')')

    for i, v in Deque.iterator(self) do
        action(v)
    end
    return self
end

function Deque:reduce(...) 
    local args = table.pack(...)
    local reducer = args[1]
    local identity = args[2]
    assert(type(reducer) == 'function', "bad argument #1 to 'Deque:reduce' (function expected, got " .. type(reducer) .. ')')
    
    local accumulator
    local identitySet = false

    if args.n > 1 then
        accumulator = identity
        identitySet = true
    end

    for i, v in Deque.iterator(self) do
        if not identitySet then
            accumulator = v
            identitySet = true
        else
            accumulator = reducer(accumulator, v)
        end
    end
    return accumulator
end

function Deque:reduceRight(...) 
    local args = table.pack(...)
    local reducer = args[1]
    local identity = args[2]
    assert(type(reducer) == 'function', "bad argument #1 to 'Deque:reduceRight' (function expected, got " .. type(reducer) .. ')')
    
    local accumulator
    local identitySet = false

    if args.n > 1 then
        accumulator = identity
        identitySet = true
    end

    for i, v in Deque.reverseIterator(self) do
        if not identitySet then
            accumulator = v
            identitySet = true
        else
            accumulator = reducer(accumulator, v)
        end
    end
    return accumulator
end

return Deque