Queue = {}

Queue.methods = {
    put = function(self, elem)
        table.insert(self, elem)
    end,

    pop = function(self)
        return table.remove(self, 1)
    end,

    size = function(self)
        return #self
    end
}

Queue.metatable = {
    __tostring = function(self)
        local str = 'Queue{'
        for i, value in ipairs(self) do
            str = str .. tostring(value) .. ', '
        end
        if #str == 6 then
            return str .. '}'
        end
        return string.sub(str, 1, #str - 2) .. '}'
    end,
    __index = Queue.methods,
    __newindex = function (self, k, v) end
}

function Queue:new()
    return setmetatable({}, Queue.metatable)
end

-- make namespace callable
Queue = setmetatable(Queue, {
    __call = function(self, ...)
        return self:new(...)
    end
})