function Queue()
    local methods = {
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

    local self = setmetatable({}, {
        __tostring = function(self)
            local str = 'Queue['
            for i, value in ipairs(self) do
                str = str .. tostring(value) .. ', '
            end
            if string.len(str) == 6 then
                return str .. ']'
            end
            return string.sub(str, 1, string.len(str) - 2) .. ']'
        end,
        __index = methods,
        __newindex = function (self, k, v) end
    })

    return self
end