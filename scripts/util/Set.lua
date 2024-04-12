function Set()
    return {
        size = 0,
        array = {},
        put = function (self, elem)
            if self.array[elem] then
                return
            end
            self.array[elem] = true
            self.size = self.size + 1
        end,
        putAll = function (self, arr)
            for i, elem in ipairs(arr) do
                self:put(elem)
            end
        end,
        remove = function (self, elem)
            if self.array[elem] then
                self.array[elem] = false
                self.size = self.size - 1
            end
        end,
        removeAll = function (self, arr)
            for i, elem in ipairs(arr) do
                self:remove(elem)
            end
        end,
        contains = function (self, elem)
            if self.array[elem] then
                return true
            end
            return false
        end,
        getValues = function (self)
            local keys = {}
            for key, value in pairs(self.array) do
                if value then
                    table.insert(keys, key)
                end
            end
            return keys
        end
    }
end