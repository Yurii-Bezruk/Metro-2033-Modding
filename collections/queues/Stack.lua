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

local Stack = setmetatable({}, {
    __call = function(self, ...)
        return self:new(...)
    end,
    __tostring = function()
        return '<class Stack>'
    end
})

function Stack:new(input)
    input = input or {}
    assert(type(input) == 'table', "bad argument #1 to 'Stack:new' (table expected, got " .. type(input) .. ')')

    local newStack = {}
    if Deque.isDeque(input) then
        DEQUE_STORAGE[newStack] = input:clone()
    else
        DEQUE_STORAGE[newStack] = Deque:new(input)
    end

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

    return setmetatable(newStack, self)
end

function Stack.pack(...)
    local input = table.pack(...)
    input.size, input.n = input.n, nil
    return Stack(input)
end

function Stack.generate(generator, sizeOrCondition, identity)
    assert(type(generator) == 'function', "bad argument #1 to 'Stack.generate' (function expected, got " .. type(generator) .. ')')
    
    if type(sizeOrCondition) == 'number' then
        local size = sizeOrCondition

        local newStack = {size = size}
        local last = identity
        for i = 1, size do
            last = generator(last)
            newStack[i] = last
        end
        return Stack(newStack)
    elseif type(sizeOrCondition) == 'function' then
        local condition = sizeOrCondition

        local i = 0
        local newStack = {}
        local last = generator(identity)
        while condition(last) do
            i = i + 1
            newStack[i] = last
            last = generator(last)
        end
        newStack.size = i
        return Stack(newStack)
    else
        error("bad argument #2 to 'Stack.generate' (number or function expected, got " .. type(sizeOrCondition) .. ')')
    end
end

function Stack:isStack()
    local metatable = self
    repeat
        metatable = getmetatable(metatable)
        if metatable == Stack then
            return true
        end
    until metatable == nil
    return false
end

function Stack:iterator()
    local next, state, identity = getDeque(self):reverseIterator()
    return function(state, i)
        local nextI, nextV = next(state, state.from - i)
        if not nextI then
            return nextI, nextV
        end
        return state.from - nextI, nextV
    end, state, state.from - identity
end

function Stack:reverseIterator()
    return getDeque(self):reverseIterator()
end

function Stack:valuesIterator()
    local next, state, identity = getDeque(self):reverseIterator()
    local i, v = identity, nil
    return function()
        repeat
            i, v = next(state, i)
        until v ~= nil or i == nil
        return v
    end
end

function Stack:push(value)
    getDeque(self):pushRight(value)
    return self
end

function Stack:pushAll(values)
    getDeque(self):pushAllRight(values)
    return self
end

function Stack:pop()
    return getDeque(self):popRight()
end

function Stack:peek()
    return getDeque(self):peekRight()
end

function Stack:remove()
    getDeque(self):removeRight()
    return self
end

function Stack:unpack()
    return getDeque(self):unpack()
end

function Stack:contains(value)
    return getDeque(self):contains(value)
end

function Stack:size()
    return getDeque(self):size()
end

function Stack:clear()
    getDeque(self):clear()
    return self
end

function Stack:equals(other)
    if type(other) ~= 'table' then
        return false
    end
    return getDeque(self):equals(getDeque(other))
end

function Stack:combine(other)
    return Stack(getDeque(self):combine(getDeque(other)))
end

function Stack:concat(sep)
    return getDeque(self):concat(sep)
end

function Stack:toString()
    return 'Stack' .. getDeque(self):toString():sub(6)
end

function Stack:toTable()
    return getDeque(self):toTable()
end

function Stack:toList()
    return getDeque(self):toList()
end

function Stack:clone()
    local deque = getDeque(self)
    if Stack.isStack(self) then
        return Stack(deque)
    end
    return deque:toTable()
end

function Stack:map(mapper)
    return Stack(getDeque(self):map(mapper))
end

function Stack:flatMap(mapper)
    assert(type(mapper) == 'function', "bad argument #1 to 'Stack:flatMap' (function expected, got " .. type(mapper) .. ')')

    local newStack = {}
    local size = 0
    for i, v in getDeque(self):iterator() do
        local result = mapper(v)
        assert(type(result) == 'table', "bad response from mapper function in 'Stack:flatMap' (table expected, got " .. type(result) .. ')')
        for _, resV in getDeque(result):iterator() do
            size = size + 1
            newStack[size] = resV
        end
    end
    return Stack(newStack)
end

function Stack:packMap(mapper)
    return Stack(getDeque(self):packMap(mapper))
end

function Stack:forEach(action)
    assert(type(action) == 'function', "bad argument #1 to 'Deque:forEach' (function expected, got " .. type(action) .. ')')

    for i, v in getDeque(self):reverseIterator() do
        action(v)
    end
    return self
end

function Stack:reduce(...)
    local args = table.pack(...)
    local reducer = args[1]
    local identity = args[2]
    local deque = getDeque(self)

    if args.n > 1 then
        return deque:reduceRight(reducer, identity)
    end
    return deque:reduceRight(reducer)
end

return Stack