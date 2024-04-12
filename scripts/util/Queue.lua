function Queue()
    return {
        size = 0,
        array = {},
        put = function (self, elem)
            table.insert(self.array, elem)
            self.size = self.size + 1
        end,
        pop = function (self)
            local elem = table.remove(self.array, 1)            
            self.size = self.size - 1
            return elem        
        end,
        getValues = function (self)
            return self.array
        end
    }
end