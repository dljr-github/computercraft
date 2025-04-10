
-- event tests

-- os.loadAPI("general/bluenet.lua")
--os.loadAPI("host/global.lua")
--shell.openTab("test/temp_1.lua")
--shell.openTab("test/temp_2.lua")

--os.queueEvent("test",os.epoch("local"))
--os.startTimer(1)

-- translation test

-- local translation = require("general/blockTranslation")
-- --local nameToId = translation.nameToId
-- local nameToId = translation.nameToId
-- local idToName = translation.idToName

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
	-- print("test",os.epoch("local")-start)
-- end



-- function Map:doStuff()
	-- local start = os.epoch("local")
	-- for i =1, 1000000 do
		-- id = self:doNameToId("minecraft:stone")
	-- end
	-- print(os.epoch("local")-start)
-- end


-- local map = Map:new()

-- local function doNameToId(name)
	-- return nameToId["minecraft:stone"]
-- end


-- local start = os.epoch("local")
-- for i =1, 1000000 do
	-- id = doNameToId("minecraft:stone")
-- end
-- print(os.epoch("local")-start)
-- map:doStuff()
-- map:test(1)



-- --other stuff

-- local start = os.epoch("local")
-- for i =1, 1000000 do
	-- id = translation.idToName[1]
-- end
-- print(os.epoch("local")-start)



-- local translation = require("general/blockTranslation")
-- local map = global.map

-- local data = { name = "minecraft:stone" }
-- local start = os.epoch("local")
-- for i =1, 1000000 do
	-- --id = map:getData(1,1,1)
	-- --has = string.find("minecraft:iron_ore","_ore")
	-- --if type(data.name) == "string" then 
	-- id = nameToId["minecraft:iron_ore"]
	-- --end
-- end
-- print(id, os.epoch("local")-start)

-- local start = os.epoch("local")
-- for i =1, 1000000 do
	-- id = idToName[1]
	-- id = nameToId[id]
-- end
-- print(os.epoch("local")-start)


local vectors = {
	[0] = {x=0, y=0, z=1},  -- 	+z = 0	south
	[1] = {x=-1, y=0, z=0}, -- 	-x = 1	west
	[2] = {x=0, y=0, z=-1}, -- 	-z = 2	north
	[3] = {x=1, y=0, z=0},  -- 	+x = 3 	east
}
local tableinsert = table.insert

local function getNeighbours(cur)
	local neighbours = {}
	
	-- forward
	local vector = vectors[cur.o]
	table.insert(neighbours, { x = cur.x + vector.x, y = cur.y + vector.y, z = cur.z + vector.z, o = cur.o })
	-- up
	table.insert(neighbours, { x = cur.x, y = cur.y+1, z = cur.z, o = cur.o })
	-- down
	table.insert(neighbours, { x = cur.x, y = cur.y-1, z = cur.z, o = cur.o })
	-- left
	vector = vectors[(cur.o-1)%4]
	table.insert(neighbours, { x = cur.x + vector.x, y = cur.y + vector.y, z = cur.z + vector.z, o = (cur.o-1)%4 })
	-- right
	vector = vectors[(cur.o+1)%4]
	table.insert(neighbours, { x = cur.x + vector.x, y = cur.y + vector.y, z = cur.z + vector.z, o = (cur.o+1)%4 })
	-- back
	vector = vectors[(cur.o+2)%4]
	table.insert(neighbours, { x = cur.x + vector.x, y = cur.y + vector.y, z = cur.z + vector.z, o = (cur.o+2)%4 })

	return neighbours
end

local function getNeighboursNew(cur)
	local neighbours = {}
	
	local cx, cy, cz, co = cur.x, cur.y, cur.z, cur.o
	-- forward
	local vector = vectors[co]
	neighbours[1] = { x = cx + vector.x, y = cy + vector.y, z = cz + vector.z, o = co }
	-- up
	neighbours[2] = { x = cx, y = cy + 1, z = cz, o = co }
	-- down
	neighbours[3] = { x = cx, y = cy - 1, z = cz, o = co }
	-- left
	local curo = (co-1)%4
	vector = vectors[curo]
	neighbours[4] = { x = cx + vector.x, y = cy + vector.y, z = cz + vector.z, o = curo }
	-- right
	curo = (co+1)%4
	vector = vectors[curo]
	neighbours[5] = { x = cx + vector.x, y = cy + vector.y, z = cz + vector.z, o = curo }
	-- back
	curo = (co+2)%4
	vector = vectors[curo]
	neighbours[6] = { x = cx + vector.x, y = cy + vector.y, z = cz + vector.z, o = curo }

	return neighbours
end



-- test performance

local function testNeighbours()
	local cur = { x = 2345, y = 72, z = -2664, o = 3, block = 2 }
	local iterations = 100000 -- Number of operations to test
	local start = os.epoch("local")
	for i = 1, iterations do
		local neighbours = getNeighbours(cur)
		--print(neighbours)
	end
	local stop = os.epoch("local")
	print("getNeighbours time:", stop - start)


	local start = os.epoch("local")
	for i = 1, iterations do
		local neighbours = getNeighboursNew(cur)
		--print(neighbours)
	end
	local stop = os.epoch("local")
	print("getNeighboursNew time:", stop - start)
end

testNeighbours()