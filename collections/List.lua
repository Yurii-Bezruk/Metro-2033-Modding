local Map

local function importMap()
    if Map then
        return
    end

    local success, module = pcall(function() return require 'collections.Map' end)
    if not success then
        print('List.<module init>: Map module not found, falling back to lua tables')

        Map = setmetatable({}, {
            __call = function(self, ...)
                return self:new(...)
            end
        })

        function Map:new(input) 
            return input
        end
    end
    Map = module
end

local TO_STRING_SEEN_STORAGE = setmetatable({}, {__mode = 'k'})

local function getSize(self)
    if self.size and type(self.size) == 'number' and self.size >= 0 then
        return self.size
    end
    return #self
end

local function setSize(self, size)
    if self.size and type(self.size) == 'number' and self.size >= 0 then
        self.size = size
    end
end

local function transformIndex(index, size)
    if index < 0 and index >= -size then
        return size + index + 1
    end
    return index
end

local function quicksort(arr, left, right, comparator)
    if left >= right then
        return
    end

    local pivot = arr[math.floor((left + right) / 2)]
    local i = left
    local j = right

    while i <= j do
        while comparator(arr[i], pivot) do
            i = i + 1
        end
        while comparator(pivot, arr[j]) do
            j = j - 1
        end
        if i <= j then
            arr[i], arr[j] = arr[j], arr[i]
            i = i + 1
            j = j - 1
        end
    end

    if left < j then
        quicksort(arr, left, j, comparator)
    end
    if i < right then
        quicksort(arr, i, right, comparator)
    end
end

local function hasCustomToString(t)
    local mt = getmetatable(t)
    return type(mt) == 'table' and type(mt.__tostring) == 'function'
end

local List = setmetatable({}, {
    __call = function(self, ...)
        return self:new(...)
    end,
    __tostring = function()
        return '<class List>'
    end
})

function List:new(input)
    assert(type(input) == 'table', "bad argument #1 to 'List:new' (table expected, got " .. type(input) .. ')')

    local newList = {
        size = getSize(input)
    }
    for i = 1, newList.size do
        newList[i] = input[i]
    end

    self.__index = function(this, index)
        if type(index) == 'number' then
            return self.get(this, index)
        end
        return self[index]
    end

    self.__newindex = function(this, index, value)
        if type(index) == 'number' then
            self.set(this, index, value)
            return
        end
        rawset(this, index, value)
    end

    self.__eq = function(this, other)
        return self.equals(this, other)
    end

    self.__concat = function(this, other)
        return self.combine(this, other)
    end

    self.__mul = function(this, times)
        return self.times(this, times)
    end

    self.__tostring = function(this)
        return self.toString(this)
    end

    return setmetatable(newList, self)
end

function List.pack(...)
    local input = table.pack(...)
    input.size, input.n = input.n, nil
    return List(input)
end

function List.rep(value, size)
    assert(type(size) == 'number', "bad argument #2 to 'List.rep' (number expected, got " .. type(size) .. ')')
    
    local newList = {size = size}
    for i = 1, size do
        newList[i] = value
    end
    return List(newList)
end

function List.generate(generator, sizeOrCondition, identity)
    assert(type(generator) == 'function', "bad argument #1 to 'List.generate' (function expected, got " .. type(generator) .. ')')
    
    if type(sizeOrCondition) == 'number' then
        local size = sizeOrCondition

        local newList = {size = size}
        local last = identity
        for i = 1, size do
            last = generator(last)
            newList[i] = last
        end
        return List(newList)
    elseif type(sizeOrCondition) == 'function' then
        local condition = sizeOrCondition

        local i = 0
        local newList = {}
        local last = generator(identity)
        while condition(last) do
            i = i + 1
            newList[i] = last
            last = generator(last)
        end
        newList.size = i
        return List(newList)
    else
        error("bad argument #2 to 'List.generate' (number or function expected, got " .. type(sizeOrCondition) .. ')')
    end
end

function List:isList()
    local metatable = self
    repeat
        metatable = getmetatable(metatable)
        if metatable == List then
            return true
        end
    until metatable == nil
    return false
end

function List:iterator(from, to)
    local size = getSize(self)
    from = from or 1
    to = to or size
    assert(type(from) == 'number', "bad argument #1 to 'List:iterator' (number expected, got " .. type(from) .. ')')
    from = transformIndex(from, size)
    assert(size == 0 or from >= 1 and from <= size, "bad argument #1 to 'List:iterator' (position out of bounds: " .. from .. ')')
    assert(type(to) == 'number', "bad argument #2 to 'List:iterator' (number expected, got " .. type(to) .. ')')
    to = transformIndex(to, size)
    assert(size == 0 or to >= 1 and to <= size, "bad argument #2 to 'List:iterator' (position out of bounds: " .. to .. ')')
    
    local function next(state, i)
        if i < state.from then
            return nil
        end
        i = i + 1
        if i <= state.to then
            return i, state.list[i]
        end
    end
    return next, {list = self, from = from - 1, to = to}, from - 1
end

function List:reverseIterator(from, to)
    local size = getSize(self)
    from = from or size
    to = to or 1
    assert(type(from) == 'number', "bad argument #1 to 'List:reverseIterator' (number expected, got " .. type(from) .. ')')
    from = transformIndex(from, size)
    assert(size == 0 or from >= 1 and from <= size, "bad argument #1 to 'List:reverseIterator' (position out of bounds: " .. from .. ')')
    assert(type(to) == 'number', "bad argument #2 to 'List:reverseIterator' (number expected, got " .. type(to) .. ')')
    to = transformIndex(to, size)
    assert(size == 0 or to >= 1 and to <= size, "bad argument #2 to 'List:reverseIterator' (position out of bounds: " .. to .. ')')
    
    local function next(state, i)
        if i > state.from then
            return nil
        end
        i = i - 1
        if i >= state.to then
            return i, state.list[i]
        end
    end
    return next, {list = self, from = from + 1, to = to}, from + 1
end

function List:valuesIterator()
    local i = 0
    local list = self
    local size = getSize(list)
    return function()
        repeat
            i = i + 1
        until i > size or list[i]
        if i <= size then
            return list[i]
        end
    end
end

function List:insert(...)
    local args = table.pack(...)
    local size = getSize(self)
    local index, value
    if args.n == 0 then
        error("bad argument #1 to 'List:insert' (value or index expected, got nil)")
    elseif args.n == 1 then
        index = size + 1
        value = args[1]
    else
        index = args[1]
        value = args[2]
        assert(type(index) == 'number', "bad argument #1 to 'List:insert' (number expected, got " .. type(index) .. ')')
        index = transformIndex(index, size)
        assert(index >= 1 and index <= size + 1, "bad argument #1 to 'List:insert' (position out of bounds: " .. index .. ')')
    end

    setSize(self, size + 1)
    for i = size + 1, index, -1 do
        self[i] = rawget(self, i - 1)
    end
    self[index] = value
    return self
end

function List:insertAll(...)
    local args = table.pack(...)
    local size = getSize(self)
    local index, values
    if args.n == 0 then
        error("bad argument #1 to 'List:insertAll' (table or index expected, got nil)")
    elseif args.n == 1 then
        index = size + 1
        values = args[1]
    else
        index = args[1]
        values = args[2]
        assert(type(index) == 'number', "bad argument #1 to 'List:insertAll' (number expected, got " .. type(index) .. ')')
        index = transformIndex(index, size)
        assert(index >= 1 and index <= size + 1, "bad argument #1 to 'List:insertAll' (position out of bounds: " .. index .. ')')
    end
    assert(type(values) == 'table', "bad argument #2 to 'List:insertAll' (table expected, got " .. type(index) .. ')')

    local valuesSize = getSize(values)
    local newSize = size + valuesSize
    setSize(self, newSize)

    for i = size, index, -1 do
        rawset(self, i + valuesSize, self[i])
    end
    for i = 1, valuesSize do
        rawset(self, i + index - 1, values[i])
    end
    return self
end

function List:remove(index)
    local size = getSize(self)
    index = index or size
    assert(type(index) == 'number', "bad argument #1 to 'List:remove' (number expected, got " .. type(index) .. ')')
    index = transformIndex(index, size)
    assert(index >= 1 and index <= size, "bad argument #1 to 'List:remove' (position out of bounds: " .. index .. ')')
    
    for i, v in List.iterator(self, index) do
        self[i] = rawget(self, i + 1)
    end
    setSize(self, size - 1)
    return self
end

function List:set(index, value)
    local size = getSize(self)
    assert(type(index) == 'number', "bad argument #1 to 'List:set' (number expected, got " .. type(index) .. ')')
    index = transformIndex(index, size)
    assert(index >= 1 and index <= size, "bad argument #1 to 'List:set' (position out of bounds: " .. index .. ')')
    
    rawset(self, index, value)
    return self
end

function List:get(index)
    local size = getSize(self)
    assert(type(index) == 'number', "bad argument #1 to 'List:get' (number expected, got " .. type(index) .. ')')
    index = transformIndex(index, size)
    assert(index >= 1 and index <= size, "bad argument #1 to 'List:get' (position out of bounds: " .. index .. ')')

    return rawget(self, index)
end

function List:fill(value, from, to)
    local size = getSize(self)
    from = from or 1
    to = to or size    
    assert(type(from) == 'number', "bad argument #1 to 'List:fill' (number expected, got " .. type(from) .. ')')
    from = transformIndex(from, size)
    assert(from >= 1 and from <= size, "bad argument #1 to 'List:fill' (position out of bounds: " .. from .. ')')
    assert(type(to) == 'number', "bad argument #2 to 'List:fill' (number expected, got " .. type(to) .. ')')
    to = transformIndex(to, size)
    assert(to >= 1 and to <= size, "bad argument #2 to 'List:fill' (position out of bounds: " .. to .. ')')

    for i = from, to do
        rawset(self, i, value)        
    end
   
    return self
end

function List:slice(from, to)
    local size = getSize(self)
    from = from or 1
    to = to or getSize(self)    
    assert(type(from) == 'number', "bad argument #1 to 'List:unpack' (number expected, got " .. type(from) .. ')')
    from = transformIndex(from, size)
    assert(size == 0 or from >= 1 and from <= size, "bad argument #1 to 'List:unpack' (position out of bounds: " .. from .. ')')
    assert(type(to) == 'number', "bad argument #2 to 'List:unpack' (number expected, got " .. type(to) .. ')')
    to = transformIndex(to, size)
    assert(size == 0 or to >= 1 and to <= size, "bad argument #2 to 'List:unpack' (position out of bounds: " .. to .. ')')
    

    local newList = {}
    local j = 1
    for i, v in List.iterator(self, from, to) do
        newList[j] = v
        j = j + 1
    end
    newList.size = to - from + 1
    return List(newList)
end

function List:unpack(from, to)
    local size = getSize(self)
    from = from or 1
    to = to or size
    assert(type(from) == 'number', "bad argument #1 to 'List:unpack' (number expected, got " .. type(from) .. ')')
    from = transformIndex(from, size)
    assert(size == 0 or from >= 1 and from <= size, "bad argument #1 to 'List:unpack' (position out of bounds: " .. from .. ')')
    assert(type(to) == 'number', "bad argument #2 to 'List:unpack' (number expected, got " .. type(to) .. ')')
    to = transformIndex(to, size)
    assert(size == 0 or to >= 1 and to <= size, "bad argument #2 to 'List:unpack' (position out of bounds: " .. to .. ')')
    
    return table.unpack(self, from, to)
end

function List:indexOf(value)
    for i, v in List.iterator(self) do
        if value == v then
            return i
        end
    end
end

function List:lastIndexOf(value)
    for i, v in List.reverseIterator(self) do
        if value == v then
            return i
        end
    end
end

function List:contains(value)
    return List.indexOf(self, value) ~= nil
end

function List:clear()
    local size = getSize(self)
    for i = 1, size do
        rawset(self, i, nil)
    end
    setSize(self, 0)
    return self
end

function List:sort(comparator)
    comparator = comparator or function(x, y)
        return x < y
    end
    assert(type(comparator) == 'function', "bad argument #1 to 'List:sort' (function expected, got " .. type(comparator) .. ')')

    local newList = List(self)
    quicksort(newList, 1, newList.size, comparator)
    return newList
end

function List:reverse()
    local size = getSize(self)
    local newList = {size = size}

    for i, v in List.reverseIterator(self) do
        local j = size - i + 1
        newList[j] = v
    end    
    return List(newList)
end

function List:equals(other)
    if type(other) ~= 'table' then
        return false
    end
    if getSize(self) ~= getSize(other) then
        return false
    end
    
    local next, state, seed = List.iterator(other)
    local i2, v2 = seed, nil
    for i1, v1 in List.iterator(self) do
        i2, v2 = next(state, i2)
        if v1 ~= v2 then
            if type(v1) == 'table' and type(v2) == 'table' then
               return List.equals(v1, v2)
            end
            return false
        end
    end
    return true
end

function List:combine(other)
    assert(type(other) == 'table', "bad argument #1 to 'List:combine' (table expected, got " .. type(other) .. ')')

    local selfSize = getSize(self)
    local otherSize = getSize(other)
    local newList = {size = selfSize + otherSize}
    for i = 1, selfSize do
        newList[i] = self[i]
    end
    for i = 1, otherSize do
        newList[i + selfSize] = other[i]
    end
    return List(newList)
end

function List:times(times)
    assert(type(times) == 'number', "bad argument #1 to 'List:times' (number expected, got " .. type(times) .. ')')
    assert(times >= 0, "bad argument #1 to 'List:times' (positive number or zero expected, got " .. times .. ')')
    
    local size = getSize(self)
    local newList = {size = size * times}
    for i = 1, times do
        for j, v in List.iterator(self) do
            newList[size * (i - 1) + j] = v
        end
    end
    return List(newList)
end

function List:concat(sep, from, to)
    sep = sep or ''
    assert(type(sep) == 'string', "bad argument #1 to 'List:concat' (string expected, got " .. type(sep) .. ')')
    
    local str = ''
    for i, v in List.iterator(self, from, to) do
        str = ('%s%s%s'):format(str, sep, tostring(self[i]))
    end
    return str:sub(#sep + 1)
end

function List:toString()
    if type(self) == 'string' then
        return ('%q'):format(self)
    end
    if type(self) ~= 'table' then
        return tostring(self)
    end
    if not List.isList(self) and hasCustomToString(self) then 
        return tostring(self)
    end
    if TO_STRING_SEEN_STORAGE[self] then
        return '<cycle>'
    end

    TO_STRING_SEEN_STORAGE[self] = true
    local str = ''
    for i, v in List.iterator(self) do
        str = ('%s, %s'):format(str, List.toString(v))
    end
    TO_STRING_SEEN_STORAGE[self] = nil
    return '[' .. str:sub(3) .. ']'
end

function List:toTable()
    local newTable = {}
    for i, v in List.iterator(self) do
        newTable[i] = v
    end
    return newTable
end

function List:clone()
    if List.isList(self) then
        return List(self)
    end
    return List.toTable(self)
end

function List:filter(predicate)
    assert(type(predicate) == 'function', "bad argument #1 to 'List:filter' (function expected, got " .. type(predicate) .. ')')

    local newList = {}
    local size = 0
    for i, v in List.iterator(self) do
        if predicate(v) then
            size = size + 1
            newList[size] = v
        end
    end
    newList.size = size
    return List(newList)
end

function List:findFirst(predicate)
    assert(type(predicate) == 'function', "bad argument #1 to 'List:findFirst' (function expected, got " .. type(predicate) .. ')')
    
    for i, v in List.iterator(self) do
        if predicate(v) then
            return v, i
        end
    end
end

function List:findLast(predicate)
    assert(type(predicate) == 'function', "bad argument #1 to 'List:findLast' (function expected, got " .. type(predicate) .. ')')
    
    for i, v in List.reverseIterator(self) do
        if predicate(v) then
            return v, i
        end
    end
end

function List:anyMatch(predicate)
    assert(type(predicate) == 'function', "bad argument #1 to 'List:anyMatch' (function expected, got " .. type(predicate) .. ')')

    for i, v in List.iterator(self) do
        if predicate(v) then
            return true
        end
    end
    return false
end

function List:allMatch(predicate)
    assert(type(predicate) == 'function', "bad argument #1 to 'List:allMatch' (function expected, got " .. type(predicate) .. ')')

    for i, v in List.iterator(self) do
        if not predicate(v) then
            return false
        end
    end
    return true
end

function List:map(mapper)
    assert(type(mapper) == 'function', "bad argument #1 to 'List:map' (function expected, got " .. type(mapper) .. ')')

    local newList = {size = getSize(self)}
    for i, v in List.iterator(self) do
        newList[i] = mapper(v)
    end
    return List(newList)
end

function List:flatMap(mapper)
    assert(type(mapper) == 'function', "bad argument #1 to 'List:flatMap' (function expected, got " .. type(mapper) .. ')')
    
    local newList = {}
    local size = 0
    for i, v in List.iterator(self) do
        local result = mapper(v)
        assert(type(result) == 'table', "bad response from mapper function in 'List:flatMap' (table expected, got " .. type(result) .. ')')
        for _, resV in List.iterator(result) do
            size = size + 1
            newList[size] = resV
        end
    end
    return List(newList)
end

function List:packMap(mapper)
    assert(type(mapper) == 'function', "bad argument #1 to 'List:packMap' (function expected, got " .. type(mapper) .. ')')
    
    local newList = {}
    local size = 0
    for i, v in List.iterator(self) do
        local result = List.pack(mapper(v))
        for _, resV in List.iterator(result) do
            size = size + 1
            newList[size] = resV
        end
    end
    return List(newList)
end

function List:forEach(action)
    assert(type(action) == 'function', "bad argument #1 to 'List:forEach' (function expected, got " .. type(action) .. ')')

    for i, v in List.iterator(self) do
        action(v)
    end
    return self
end

function List:reduce(...)
    local args = table.pack(...)
    local reducer = args[1]
    local identity = args[2]
    local size = getSize(self)
    local start = 1
    assert(type(reducer) == 'function', "bad argument #1 to 'List:reduce' (function expected, got " .. type(reducer) .. ')')
    
    if size == 0 then
        return identity
    end
    if size == 1 and args.n == 1 then
        return self[1]
    end

    if args.n == 1 then
        identity = self[1]
        start = 2
    end
    
    local accumulator = identity
    for i, v in List.iterator(self, start) do
        accumulator = reducer(accumulator, v)
    end
    return accumulator
end

function List:reduceRight(...)
    local args = table.pack(...)
    local reducer = args[1]
    local identity = args[2]
    local size = getSize(self)
    local start = size
    assert(type(reducer) == 'function', "bad argument #1 to 'List:reduceRight' (function expected, got " .. type(reducer) .. ')')
    
    if size == 0 then
        return identity
    end
    if size == 1 and args.n == 1 then
        return self[1]
    end

    if args.n == 1 then
        identity = self[size]
        start = size - 1
    end
    
    local accumulator = identity
    for i, v in List.reverseIterator(self, start) do
        accumulator = reducer(accumulator, v)
    end
    return accumulator
end

function List:zip(other, zipper, identity)
    assert(type(other) == 'table', "bad argument #1 to 'List:zip' (table expected, got " .. type(other) .. ')')
    assert(type(zipper) == 'function', "bad argument #2 to 'List:zip' (function expected, got " .. type(zipper) .. ')')

    local selfSize = getSize(self)
    local otherSize = getSize(other)
    local newList = {size = math.max(selfSize, otherSize)}

    function getSelf(i)
        if i > selfSize then
            return identity
        end
        return self[i]
    end
    function getOther(i)
        if i > otherSize then
            return identity
        end
        return other[i]
    end

    for i = 1, newList.size do
        newList[i] = zipper(getSelf(i), getOther(i))
    end

    return List(newList)
end

function List:groupBy(grouper)
    assert(type(grouper) == 'function', "bad argument #1 to 'List:groupBy' (function expected, got " .. type(grouper) .. ')')
    importMap()

    local groups = Map{}
    for i, v in List.iterator(self) do
        local group = grouper(v)
        if not groups[group] then
            groups[group] = List{}
        end
        groups[group]:insert(v)
    end
    return groups
end

return List