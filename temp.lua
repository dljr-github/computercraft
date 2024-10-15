
-- event tests

os.loadAPI("general/bluenet.lua")
os.loadAPI("host/global.lua")
shell.openTab("temp_1.lua")
shell.openTab("temp_2.lua")

os.queueEvent("test",os.epoch("local"))

-- translation test

-- local translation = require("general/blockTranslation")
-- --local nameToId = translation.nameToId
-- local nameToId = translation.nameToId

-- Map = {}

-- function Map:new()
	-- local o = o or {}
	-- setmetatable(o, self)
	-- self.__index = self
	-- o.nameToId = require("general/blockTranslation").nameToId
	-- return o
-- end

-- function Map:translate(name)
	-- return nameToId[name]
-- end


-- function Map:doNameToId(name)
	-- return nameToId[name]
-- end

-- function Map:test(name)
-- local start = os.epoch("local")
	-- for i =1, 1000000 do
		-- --id = map:nameToId("minecraft:stone")
		-- --id = self:translate("minecraft:stone")
		-- id = nameToId[name]
	-- end
	-- print(os.epoch("local")-start)
-- end



-- function Map:doStuff()
	-- local start = os.epoch("local")
	-- for i =1, 1000000 do
		-- id = self:doNameToId("minecraft:stone")
	-- end
	-- print(os.epoch("local")-start)
-- end


-- local map = Map:new()

-- function doNameToId(name)
	-- return nameToId["minecraft:stone"]
-- end


-- local start = os.epoch("local")
-- for i =1, 1000000 do
	-- id = doNameToId("minecraft:stone")
-- end
-- print(os.epoch("local")-start)
-- map:doStuff()
-- map:test()



-- other stuff

-- local start = os.epoch("local")
-- for i =1, 1000000 do
	-- id = translation.idToName[1]
-- end
-- print(os.epoch("local")-start)



-- local translation = require("general/blockTranslation")


-- local start = os.epoch("local")
-- for i =1, 1000000 do
	-- id = translation.nameToId["minecraft:stone"]
-- end
-- print(os.epoch("local")-start)

-- local start = os.epoch("local")
-- for i =1, 1000000 do
	-- id = translation.idToName[1]
-- end
-- print(os.epoch("local")-start)