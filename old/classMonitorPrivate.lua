function newMonitor(m)
    self = {
        width = 0,
        height = 0,
    }

    setmetatable(self, m)
    m.__index = m
    
    local updateSize = function()
        self.width, height = self.getSize()
    end
    local getWidth = function()
        updateSize()
        return self.width
    end
    local getHeight = function()
        updateSize()
        return self.height
    end
    return {
        width = self.width,
        height = self.height,
        self = self,
        getWidth = getWidth,
        getHeight = getHeight
    }
end
