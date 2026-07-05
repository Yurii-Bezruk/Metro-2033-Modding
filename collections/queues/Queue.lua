local Deque = require 'collections.queues.Deque'

local DEQUE_STORAGE = setmetatable({}, {__mode = 'k'})

local function getDeque(self)
    local deque = DEQUE_STORAGE[self]
    if not deque then
        deque = Deque:new(self)
        DEQUE_STORAGE[self] = deque
    end
    return deque
end

local Queue = setmetatable({}, {
    __call = function(self, ...)
        return self:new(...)
    end,
    __tostring = function()
        return '<class Queue>'
    end
})

function Queue:new(input)
    input = input or {}
    assert(type(input) == 'table', "bad argument #1 to 'Queue:new' (table expected, got " .. type(input) .. ')')

    local newQueue = {}
    if Deque.isDeque(input) then
        DEQUE_STORAGE[newQueue] = input:clone()
    else
        DEQUE_STORAGE[newQueue] = Deque:new(input)
    end

    self.__index = function(this, index)
        if type(index) == 'number' then
            return getDeque(this)[index]
        end
        if index == 'size' then
            return self.size(this)
        end
        return self[index]
    end

    self.__newindex = function(this, index, value)
        if type(index) == 'number' then
            getDeque(this)[index] = value
            return
        end
        rawset(this, index, value)
    end

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

    return setmetatable(newQueue, self)
end

function Queue.pack(...)
    local input = table.pack(...)
    input.size, input.n = input.n, nil
    return Queue(input)
end

function Queue.generate(generator, sizeOrCondition, identity)
    assert(type(generator) == 'function', "bad argument #1 to 'Queue.generate' (function expected, got " .. type(generator) .. ')')
    
    if type(sizeOrCondition) == 'number' then
        local size = sizeOrCondition

        local newQueue = {size = size}
        local last = identity
        for i = 1, size do
            last = generator(last)
            newQueue[i] = last
        end
        return Queue(newQueue)
    elseif type(sizeOrCondition) == 'function' then
        local condition = sizeOrCondition

        local i = 0
        local newQueue = {}
        local last = generator(identity)
        while condition(last) do
            i = i + 1
            newQueue[i] = last
            last = generator(last)
        end
        newQueue.size = i
        return Queue(newQueue)
    else
        error("bad argument #2 to 'Queue.generate' (number or function expected, got " .. type(sizeOrCondition) .. ')')
    end
end

function Queue:isQueue()
    local metatable = self
    repeat
        metatable = getmetatable(metatable)
        if metatable == Queue then
            return true
        end
    until metatable == nil
    return false
end

function Queue:iterator()
    return getDeque(self):iterator()
end

function Queue:reverseIterator()
    local next, state, identity = getDeque(self):iterator()
    return function(state, i)
        local nextI, nextV = next(state, state.to + 1 - i)
        if not nextI then
            return nextI, nextV
        end
        return state.to + 1 - nextI, nextV
    end, state, state.to + identity + 1
end

function Queue:valuesIterator()
    return getDeque(self):valuesIterator()
end

function Queue:push(value)
    getDeque(self):pushRight(value)
    return self
end

function Queue:pushAll(values)
    getDeque(self):pushAllRight(values)
    return self
end

function Queue:pop()
    return getDeque(self):popLeft()
end

function Queue:peek()
    return getDeque(self):peekLeft()
end

function Queue:remove()
    getDeque(self):removeLeft()
    return self
end

function Queue:unpack()
    return getDeque(self):unpack()
end

function Queue:contains(value)
    return getDeque(self):contains(value)
end

function Queue:size()
    return getDeque(self).size
end

function Queue:clear()
    getDeque(self):clear()
    return self
end

function Queue:equals(other)
    if type(other) ~= 'table' then
        return false
    end
    return getDeque(self):equals(getDeque(other))
end

function Queue:combine(other)
    return Queue(getDeque(self):combine(getDeque(other)))
end

function Queue:concat(sep)
    return getDeque(self):concat(sep)
end

function Queue:toString()
    return 'Queue' .. getDeque(self):toString():sub(6)
end

function Queue:toTable()
    return getDeque(self):toTable()
end

function Queue:toList()
    return getDeque(self):toList()
end

function Queue:clone()
    local deque = getDeque(self)
    if Queue.isQueue(self) then
        return Queue(deque)
    end
    return deque:toTable()
end

function Queue:map(mapper)
    return Queue(getDeque(self):map(mapper))
end

function Queue:flatMap(mapper)
    assert(type(mapper) == 'function', "bad argument #1 to 'Queue:flatMap' (function expected, got " .. type(mapper) .. ')')

    local newQueue = {}
    local size = 0
    for i, v in getDeque(self):iterator() do
        local result = mapper(v)
        assert(type(result) == 'table', "bad response from mapper function in 'Queue:flatMap' (table expected, got " .. type(result) .. ')')
        for _, resV in getDeque(result):iterator() do
            size = size + 1
            newQueue[size] = resV
        end
    end
    return Queue(newQueue)
end

function Queue:packMap(mapper)
    return Queue(getDeque(self):packMap(mapper))
end

function Queue:forEach(action)
    getDeque(self):forEach(action)
end

function Queue:reduce(...)
    local args = table.pack(...)
    local reducer = args[1]
    local identity = args[2]
    local deque = getDeque(self)

    if args.n > 1 then
        return deque:reduce(reducer, identity)
    end
    return deque:reduce(reducer)
end

return Queue