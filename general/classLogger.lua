local default = {
	fileName = "log.txt",
}

Logger = {}

function Logger:new(fileName)
	local o = o or {}
	setmetatable(o,self)
	self.__index = self
	
	self.fileName = fileName or default.fileName
	self.entries = {}
	
	return self
end

function Logger:initialize()
	
end

function Logger:save(fileName)
	fileName = fileName or self.fileName
	local f = fs.open(fileName, "w")
	f.write(textutils.serialize(self.entries))
	f.close()
end

function Logger:addFirst(entry)
	table.insert(self.entries, entry)
end

function Logger:print()
	for _,entry in ipairs(self.entries) do
		print(textutils.serialize(entry))
	end
end