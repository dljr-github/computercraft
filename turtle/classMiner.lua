local PathFinder = require("classPathFinder")
--require("classMap")
require("classLogger")
require("classList")
require("classChunkyMap")

-- local blockTranslation = require("blockTranslation")
-- local nameToId = blockTranslation.nameToId
-- local idToName = blockTranslation.idToName

local default = {
	waitTimeFallingBlock = 0.5,
	maxVeinRadius = 10, --8 MAX:16
	maxVeinSize = 256,
	inventorySize = 16,
	criticalFuelLevel = 512,
	goodFuelLevel = 4099,
	--maxHomeDistance = 128, -- unused
	file = "runtime/miner.txt",
	fuelAmount = 16,
	turtleName = "computercraft:turtle_advanced",
	pathfinding = {
		maxTries = 15,
		maxParts = 2,
		maxDistance = 10,
	}
}

local fuelItems = {
["minecraft:coal"]=true,
["minecraft:charcoal"]=true,
["minecraft:coal_block"]=true,
["minecraft:lava_bucket"]=true,
}
-- do not translate

local mineBlocks = {
["minecraft:cobblestone"]=true,
["minecraft:stone"]=true,
["minecraft:grass_block"]=true,
["minecraft:dirt"]=true,
["minecraft:gravel"]=true,
["minecraft:sand"]=true,
["minecraft:bedrock"]=true,
["minecraft:flint"]=true,
["minecraft:sandstone"]=true,
["minecraft:diorite"]=true,
["minecraft:granite"]=true,
["minecraft:andesite"]=true,
["minecraft:tuff"]=true,
["minecraft:deepslate"]=true,
["minecraft:cobbled_deepslate"]=true,
-- own array with fluids / allowedBlocks
["minecraft:water"]=true,
["minecraft:lava"]=true,
--["minecraft:glass"]=true,
}
--mineBlocks = blockTranslation.translateTable(mineBlocks)


local inventoryBlocks = {
["minecraft:chest"]=true,
["minecraft:hopper"]=true,
}
--inventoryBlocks = blockTranslation.translateTable(inventoryBlocks)

local disallowedBlocks = {
["minecraft:chest"] = true,
["minecraft:hopper"]=true,
["computercraft:turtle_advanced"] = true,
["computercraft:computer_advanced"] = true,
["computercraft:wireless_modem_advanced"] = true,
["computercraft:monitor_advanced"] = true,
}
--disallowedBlocks = blockTranslation.translateTable(disallowedBlocks)
-- local blocks = {
-- iron = { iron_ore = { id = "minecraft:iron_ore", doMine = true, level = 99 },
	-- { deepslate_iron_ore = { id = "minecraft:deepslate_iron_ore", doMine = true, level = 99 } }
-- coal = { coal
-- }

local oreBlocks = {
["minecraft:iron_ore"]=true,
["minecraft:deepslate_iron_ore"]=true,
["minecraft:coal_ore"]=true,
["minecraft:deepslate_coal_ore"]=true,
["minecraft:gold_ore"]=true,
["minecraft:deepslate_gold_ore"]=true,
["minecraft:diamond_ore"]=true,
["minecraft:deepslate_diamond_ore"]=true,
["minecraft:redstone_ore"]=true,
["minecraft:deepslate_redstone_ore"]=true,
["minecraft:lapis_ore"]=true,
["minecraft:deepslate_lapis_ore"]=true,
["minecraft:copper_ore"]=true,
["minecraft:deepslate_copper_ore"]=true,
}
--oreBlocks = blockTranslation.translateTable(oreBlocks)

local vector = vector
local debuginfo = debug.getinfo

local vectors = {
	[0] = vector.new(0,0,1),  -- 	+z = 0	south
	[1] = vector.new(-1,0,0), -- 	-x = 1	west
	[2] = vector.new(0,0,-1), -- 	-z = 2	north
	[3] = vector.new(1,0,0),  -- 	+x = 3 	east
}

local vectorUp = vector.new(0,1,0)
local vectorDown = vector.new(0,-1,0)

Miner = {}

function Miner:new()
	local o = o or {} --Worker:new()
	setmetatable(o,self)
	self.__index = self
	print("----INITIALIZING----")
	assert(turtle,"this device is not a turtle")
	
	o.fuelLimit = turtle.getFuelLimit()
	if o.fuelLimit == "unlimited" then o.fuelLimit = 0 end
	
	o.home = nil
	o.startupPos = nil
	o.homeOrientation = 0
	o.orientation = 0
	o.node = global.node
	o.pos = vector.new(0,70,0)
	o.gettingFuel = false
	o.initializing = true
	o.lookingAt = vector.new(0,0,0)
	o.map = ChunkyMap:new(true)
	o.taskList = List:new()
	o.vectors = vectors
	
	o:initialize() -- initialize after starting parallel tasks in startup.lua
	--print("--------------------")
	return o
end


function Miner:initialize()
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	
	self.map.requestChunk = function(chunkId) return self:requestChunk(chunkId) end
	--self:requestMap()
	
	-- TODO: simple refuel without getFuel (position is not initialized)
	print("fuel level:", turtle.getFuelLevel())
	self:initPosition()
	self:initOrientation()

	self.taskList:remove(currentTask)
end	

function Miner:finishInitialization()
	-- split initialization into two parts
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	
	self:refuel()
	if not self:requestStation() then
		self:setHome(self.pos.x, self.pos.y, self.pos.z)
	end
	self:setStartupPos(self.pos)
	self.initializing = nil
	
	self.taskList:remove(currentTask)
end

function Miner:initPosition()
	local x,y,z = gps.locate()
	if x and y and z then
		self.pos = vector.new(x,y,z)
	else
		--gps not working
		self:error("GPS UNAVAILABLE",true)
		-- self.pos = vector.new(0,70,0)
	end
	print("position:",self.pos.x,self.pos.y,self.pos.z)
end

function Miner:initOrientation()
	local newPos
	local turns = 0
	for i=1,4 do
		print(i,"forward")
		if not turtle.forward() then
			self:turnLeft()
			turns = turns + 1
		else
			newPos = vector.new(gps.locate())
			break
		end
	end
	if not newPos then
		self:error("ORIENTATION NOT DETERMINABLE",true)
		self.orientation = 0
	else
		print(newPos, self.pos, turns, self.orientation)
		local diff = newPos - self.pos
		self.pos = newPos
		if diff.x < 0 then self.orientation = 1
		elseif diff.x > 0 then self.orientation = 3
		elseif diff.z < 0 then self.orientation = 2
		else self.orientation = 0
		end
		self:updateLookingAt()
		self:back()
		self:turnTo((self.orientation+turns)%4)
		self.homeOrientation = self.orientation
	end
	print("orientation:", self.orientation)
end

function Miner:save(fileName)
	-- this already includes the map!
	if not fileName then fileName = default.file end
	local f = fs.open(fileName,"w")
	f.write(textutils.serialize(self))
	f.close()
end
function Miner:load(fileName)
	if not fileName then fileName = default.file end
	local f = fs.open(fileName,"r")
	if f then
		self = textutils.unserialize( f.readAll() )
		f.close()
	else
		print("FILE DOES NOT EXIST")
	end
end

function Miner:setStartupPos(pos)
	self.startupPos = vector.new(pos.x,pos.y,pos.z)
end
function Miner:setHome(x,y,z)
	self.home = vector.new(x,y,z)
	print("home:", self.home.x, self.home.y, self.home.z)
end

function Miner:requestMap()
	-- ask host for the map
	local retval = false
	if self.node and self.node.host then
		local answer, forMsg = self.node:send(global.node.host,
		{"REQUEST_MAP"},true,true,10)
		if answer then
			if answer.data[1] == "MAP" then
				retval = true
				self.map:setMap(answer.data[2])
				-- not just the map but all map information, including the log etc.
			end
		end
	end
	return retval  
end

function Miner:requestChunk(chunkId)
	-- ask host for a chunk
	-- perhaps use own protocol for this?
	local start = os.epoch("local")
	if self.node and self.node.host then
		local answer, forMsg = self.node:send(global.node.host,
			{"REQUEST_CHUNK", chunkId},true,true,1,"chunk")
		if answer then
			if answer.data[1] == "CHUNK" then
				print(os.epoch("local")-start,"RECEIVED CHUNK", chunkId)
				return answer.data[2]
			else
				print("received other", answer.data[1])
			end
		end
		--print("no answer")
	end
	print(os.epoch("local")-start, "CHUNK REQUEST FAILED", chunkId)
	return nil
end

function Miner:requestStation()
	-- ask host for station
	local retval = false
	if global.node and global.node.host then
		local answer, forMsg = self.node:send(global.node.host,{"REQUEST_STATION"},true,true,10)
		if answer then
			if answer.data[1] == "STATION" then
				retval = true
				local station = answer.data[2]
				self:setStation(station)
			elseif answer.data[1] == "STATIONS_FULL" then
				self:setStation(nil)
			end
			--print("station", textutils.serialize(answer.data[2]))
		else
			print("no station answer")
		end
	else
		print("no station host or node", global.node, global.node.host)
	end
	
	return retval
end
function Miner:setStation(station)
	if station then
		self:setHome(station.pos.x,station.pos.y,station.pos.z)
		if station.orientation then
			self.homeOrientation = station.orientation
		end
		
		if self.taskList.count == 0 -- no task
			or self.taskList.count == 1 then -- or initializing
			self:returnHome()
		end
	else
		print("NO STATION AVAILABLE")
	end
end

function Miner:getCostHome()
	local result = 0
	if self.home then
		local diff = self.pos - self.home
		result = math.abs(diff.x) + math.abs(diff.y) + math.abs(diff.z)	
	end
	return result
end

function Miner:returnHome()
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	self.returningHome = true
	if self.home then
		print("RETURNING HOME", self.home.x, self.home.y, self.home.z)
		self:navigateToPos(self.home.x, self.home.y, self.home.z)
		self:turnTo(self.homeOrientation)
	end
	self.returningHome = false
	self.taskList:remove(currentTask)
end

function Miner:error(reason,real)
	-- TODO: create image of current Miner to load later on
	-- self:save()

	if self.taskList.count > 0 then func = "ERR:"..self.taskList.first[1]
	else func = "ERR:unknown" end
	self.taskList:clear()
	error({real=real,text=reason,func=func})
end
function Miner:addCheckTask(task)
	-- called by most functions to interrupt execution
	if self.stop then
		self.stop = false
		self:error("stopped",false)
	end
	return self.taskList:addFirst(task)
end

function Miner:checkStatus()
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	-- called by self:forward()
	self:refuel()
	self:cleanInventory()
	
	self.taskList:remove(currentTask)
end

function Miner:getFuelLevel()
	return turtle.getFuelLevel()
end

function Miner:hasFullInventory(minOpen)
	minOpen = minOpen or 0
	if self:getEmptySlots() <= minOpen then
		return true
	end
	return false
end

function Miner:getEmptySlots()
	local empty = 0
	for slot = 1,default.inventorySize do
		if turtle.getItemCount(slot) == 0 then
			empty = empty + 1
		end
	end
	return empty
end

function Miner:cleanInventory()
	-- check for fully inventory and take action
	if not self.cleaningInventory and self:getEmptySlots() == 0 then
		self:condenseInventory()
		if self:getEmptySlots() < 2 then
			self:dumpBadItems()
			if self:getEmptySlots() < 2 then
				self:offloadItemsAtHome()
			end
		end
	end
end

function Miner:offloadItemsAtHome()
	-- return home, empty inventory, return to task
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	self.cleaningInventory = true
	
	local startPos = vector.new(self.pos.x, self.pos.y, self.pos.z)
	local startOrientation = self.orientation

	self:returnHome()
	self:transferItems()
	if self:getEmptySlots() < 2 then
		-- catch this in stripmine e.g.
		self.cleaningInventory = false
		self:error("INVENTORY_FULL",true)
	else
		-- do nothing and return to task
		self:navigateToPos(startPos.x, startPos.y, startPos.z)
		self:turnTo(startOrientation)
	end
	
	self.cleaningInventory = false
	self.taskList:remove(currentTask)
end

function Miner:transferItems()
	--check for chest and transfer items
	--do not transfer all fuel items (keep 1 stack)
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local hasFuel = false
	local hasInventory = false
	local startOrientation = self.orientation
	
	for k=1,4 do
	--check for chest
		self:inspect(true)
		local block = self:getMapValue(self.lookingAt.x, self.lookingAt.y, self.lookingAt.z)
		if block and inventoryBlocks[block] then
			hasInventory = true
			break
		end
		self:turnRight()
	end
	if not hasInventory then 
		print("no inventory found")
		--assert(hasInventory, "no inventory found")
	else
		local startSlot = turtle.getSelectedSlot()
		for i = 0,default.inventorySize-1 do
			local slot = (i+startSlot-1)%default.inventorySize +1
			local data = turtle.getItemDetail(slot)
			if data and data.name then
				if not hasFuel and fuelItems[data.name] then
					hasFuel = true --keep the fuel
				else
					--transfer items
					self:select(slot)
					local ok = turtle.drop(data.count)
					if ok ~= true then
						print(ok,"inventory in front is full")
						break
					end
				end
			end
		end
	end
	self:turnTo(startOrientation)
	self.taskList:remove(currentTask)
end

function Miner:dumpBadItems()
	--check for bad items and drop them
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local startSlot = turtle.getSelectedSlot()
	for i = 0,default.inventorySize-1 do
		local slot = (i+startSlot-1)%default.inventorySize +1
		local data = turtle.getItemDetail(slot)
		if data and mineBlocks[data.name] then
			--drop items
			self:select(slot)
			local ok = turtle.drop(data.count)
			if ok ~= true then
				print(ok,"inventory in front is full")
			end
		end
	end	
	self.taskList:remove(currentTask)
end

function Miner:condenseInventory()
	--stack items
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local startSlot = turtle.getSelectedSlot()
	for i = 0,default.inventorySize-1 do
		local slot = (i+startSlot-1)%default.inventorySize +1
		local data = turtle.getItemDetail(slot)
		if data and data.name then
			for targetSlot=1,default.inventorySize do
				--search matching items starting at the first slot
				if targetSlot ~= slot then
					local targetData = turtle.getItemDetail(targetSlot)
					if targetData and targetData.name == data.name then
						local fromSlot = slot
						local toSlot = targetSlot
						if targetSlot > slot then
							fromSlot = targetSlot
							toSlot = slot
						end
						--deal with multiple stacks
						if turtle.getItemSpace(toSlot) > 0 then
							self:select(fromSlot)
							turtle.transferTo(toSlot)
							if turtle.getItemCount(fromSlot) == 0 then
								break
							end
						end
					end
				end
			end
		end
	end
	self.taskList:remove(currentTask)
end

function Miner:select(slot)
	if slot > default.inventorySize then
		slot = (slot-1)%default.inventorySize+1
	end

	if turtle.getSelectedSlot() ~= slot then
		return turtle.select(slot)
	end
	return true
end

function Miner:refuel()
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})

	local refueled = false
	local goodLevel = false
	
	if not self.gettingFuel and self.fuelLimit > 0 and turtle.getFuelLevel() <= default.criticalFuelLevel then
		print("refueling...")
		for slot = 1, default.inventorySize do
			data = turtle.getItemDetail(slot)
			if data and fuelItems[data.name] then
				self:select(slot)
				repeat
					local ok, err = turtle.refuel(1)
					goodLevel = ( turtle.getFuelLevel() >= default.goodFuelLevel )
				until goodLevel or not ok
				if goodLevel then break end
			end
		end
		if turtle.getFuelLevel() > default.criticalFuelLevel then
			refueled = true
		elseif turtle.getFuelLevel() == 0 then
			-- ran out of fuel
			self:error("NEED FUEL, STUCK",true)
		else
			--if self:getCostHome() * 2 > turtle.getFuelLevel() then
				local startPos = vector.new(self.pos.x, self.pos.y, self.pos.z)
				local startOrientation = self.orientation
				if not self:getFuel() then
					self:returnHome()
					self:error("NEED FUEL",true) -- -> terminates stripMine etc.
				else
					refueled = true
					if not self.returningHome then
						self:navigateToPos(startPos.x, startPos.y, startPos.z)
						self:turnTo(startOrientation)
					end
					-- actual refueling happens with the next refuel call
				end
			--end
		end
		print("fuel level:", turtle.getFuelLevel())
	else
		refueled = true
	end
	self.taskList:remove(currentTask)
	return refueled
end

function Miner:getFuel()
	-- TODO: change from config to internal variable?
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	
	self.gettingFuel = true
	local result = false
	
	for _,station in ipairs(config.stations.refuel) do
		if station.occupied == false then
			self:navigateToPos(station.pos.x, station.pos.y, station.pos.z)
			if station.orientation then 
				self:turnTo(station.orientation) 
			end
			
			local hasInventory = false
			
			for k=1,4 do
			--check for chest
				self:inspect(true) -- true for wrong map entries or new stations
				local block = self:getMapValue(self.lookingAt.x, self.lookingAt.y, self.lookingAt.z)
				if block and inventoryBlocks[block] then
					hasInventory = true
					break
				end
				self:turnRight()
			end
			if not hasInventory then 
				print("no inventory found")
				--assert(hasInventory, "no inventory found")
			else
				result = turtle.suck(default.fuelAmount)
			end
			
			break
		end
	end
	
	if self:getEmptySlots() < 8 then
		-- already at home, also offload items
		self:offloadItemsAtHome() 
	end
	-- cancellation while getting fuel can result in this never being set to false
	self.gettingFuel = false
	
	if not result then
		print(result)
		result = false
	end
	
	self.taskList:remove(currentTask)
	return result
end

function Miner:setMapValue(x,y,z,value)
	--self.map:logData(x,y,z,value)
	self.map:setData(x,y,z,value,true)
end

function Miner:getMapValue(x,y,z)
	return self.map:getData(x,y,z)
end	

function Miner:turnTo(orient)
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	orient = orient%4
	while self.orientation ~= orient do
	
		local diff = self.orientation - orient
		if ( diff > 0 and math.abs(diff) < 3 ) or ( self.orientation == 0 and orient == 3 ) then
			self:turnLeft()
		else
			self:turnRight()
		end
	end
	self.taskList:remove(currentTask)
end



function Miner:updateLookingAt()
	-- 	+z = 0	south
	-- 	-x = 1	west
	-- 	-z = 2	north
	-- 	+x = 3 	east
	self.lookingAt = self.pos + self.vectors[self.orientation]
end

function Miner:forward()
	--local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = turtle.forward()
	if result then
		self:setMapValue(self.pos.x, self.pos.y, self.pos.z, 0)
		self.pos = self.pos + self.vectors[self.orientation]
		-- TODO: setMapValue of current position to avoid wrong entries
		--self:setMapValue(self.pos.x, self.pos.y, self.pos.z,default.turtleName)
	end
	self:checkStatus()
	--self.taskList:remove(currentTask)
	return result
end

function Miner:back()
	--local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = turtle.back()
	if result then
		self:setMapValue(self.pos.x, self.pos.y, self.pos.z, 0)
		self.pos = self.pos - self.vectors[self.orientation]
		--self:setMapValue(self.pos.x, self.pos.y, self.pos.z,default.turtleName)
	end
	--self.taskList:remove(currentTask)
	return result
end

function Miner:up()
	--local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = turtle.up()
	if result then
		self:setMapValue(self.pos.x, self.pos.y, self.pos.z, 0)
		self.pos.y = self.pos.y + 1
		--self:setMapValue(self.pos.x, self.pos.y, self.pos.z,default.turtleName)
	end
	--self.taskList:remove(currentTask)
	return result
end

function Miner:down()
	--local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = turtle.down()
	if result then
		self:setMapValue(self.pos.x, self.pos.y, self.pos.z, 0)
		self.pos.y = self.pos.y - 1
		--self:setMapValue(self.pos.x, self.pos.y, self.pos.z,default.turtleName)
	end
	--self.taskList:remove(currentTask)
	return result
end

function Miner:turnLeft()
	--local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	turtle.turnLeft()
	self.orientation = ( self.orientation - 1 ) % 4
	--self.taskList:remove(currentTask)
end

function Miner:turnRight()
	turtle.turnRight()
	self.orientation = ( self.orientation + 1 ) % 4
end

function Miner:dig(side)
	--local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = turtle.dig(side)
	if result then
		self:updateLookingAt()
		-- local block = self:getMapValue(self.lookingAt.x, self.lookingAt.y, self.lookingAt.z)
		-- if block and block ~= 0 then
			self:setMapValue(self.lookingAt.x, self.lookingAt.y, self.lookingAt.z,0)
		-- end
	end
	--self.taskList:remove(currentTask)
	return result
end

function Miner:digUp(side)
	--local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = turtle.digUp(side)
	if result then
		-- local block = self:getMapValue(self.pos.x, self.pos.y+1, self.pos.z)
		-- if block and block ~= 0 then
			self:setMapValue(self.pos.x, self.pos.y+1, self.pos.z, 0)
		-- end
	end
	--self.taskList:remove(currentTask)
	return result
end

function Miner:digDown(side)
	--local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = turtle.digDown(side)
	if result then
		-- local block = self:getMapValue(self.pos.x, self.pos.y-1, self.pos.z) 
		-- if block and block ~= 0 then
			self:setMapValue(self.pos.x, self.pos.y-1, self.pos.z, 0)
		-- end
	end
	--self.taskList:remove(currentTask)
	return result
end

function Miner.checkOreBlock(blockName)
	if blockName and blockName ~= 0 then
		if oreBlocks[blockName] then
			return true
		elseif string.find(blockName, "_ore") then
			oreBlocks[blockName] = true -- save this block as an ore
			-- TODO: save new blocks in translation on host when seeting map data?
			return true
		end
	end
	return false
end
local checkOreBlock = Miner.checkOreBlock

function Miner.checkDisallowed(id)
	-- blacklist function
	return disallowedBlocks[id]
end
local checkDisallowed = Miner.checkDisallowed

function Miner.checkSafe(id)
	-- whitelist function
	-- does not take changed blocks into account if id comes from the map value
	if not id or id == 0 or mineBlocks[id] or checkOreBlock(id) then
		return true
	end
	return false
end
local checkSafe = Miner.checkSafe

function Miner:inspect(safe)
	-- WARNING: NOT safe does NOT update the Map if the block has been explored before
	self:updateLookingAt()
	local block 
	if not safe then 
		block = self:getMapValue(self.lookingAt.x, self.lookingAt.y, self.lookingAt.z)
	end
	if block == nil then
		-- never inspected before
		local hasBlock, data = turtle.inspect()
		--block = hasBlock and ( nameToId[data.name] or data.name ) or 0
		self:setMapValue(self.lookingAt.x,self.lookingAt.y,self.lookingAt.z,
		( data and data.name ) or 0)
		block = data.name
	end
	return block
end

function Miner:inspectUp(safe)
	local block
	if not safe then
		block = self:getMapValue(self.pos.x, self.pos.y+1, self.pos.z)
	end
	if block == nil then
		local hasBlock, data = turtle.inspectUp()
		self:setMapValue(self.pos.x,self.pos.y+1,self.pos.z,
		( data and data.name ) or 0)
		block = data.name
	end
	return block
end

function Miner:inspectDown(safe)
	local block
	if not safe then
		block = self:getMapValue(self.pos.x, self.pos.y-1, self.pos.z)
	end
	if block == nil then
		local hasBlock, data = turtle.inspectDown()
		self:setMapValue(self.pos.x,self.pos.y-1,self.pos.z,
		( data and data.name ) or 0)
		block = data.name
	end
	return block
end
function Miner:inspectLeft()
	local block = self.pos + self.vectors[(orientation-1)%4]
	local block = self:getMapValue(block.x, block.y, block.z)
	if block == nil then
		self:turnTo((orientation-1)%4)
		local hasBlock, data = turtle.inspect()
		self:setMapValue(block.x, block.y, block.z, 
		( data and data.name ) or 0)
		block = data.name
	end
	return block
end
function Miner:inspectRight()
	local block = self.pos + self.vectors[(orientation+1)%4]
	local block = self:getMapValue(block.x, block.y, block.z)
	if block == nil then
		self:turnTo((orientation+1)%4)
		local hasBlock, data = turtle.inspect()
		self:setMapValue(block.x, block.y, block.z,
		( data and data.name ) or 0)
		block = data.name
	end
	return block
end

function Miner:inspectAll()
	--inspectLeft + inspectRigth ist gleich schnell wie inspectAll
	--AUßER: eines von beiden wurde bereits inspected und behind ist irrelevant
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	
	local orientation = self.orientation
	local hasBlock, data
	self:inspect()
	self:inspectDown()
	self:inspectUp()
	
	-- inspect Front, Left, Behind, Right
	for i=0,3 do
		block = self.pos + self.vectors[(orientation+i)%4]
		if self:getMapValue(block.x, block.y, block.z) == nil then
			self:turnTo((orientation+i)%4)
			hasBlock, data = turtle.inspect()
			self:setMapValue(block.x, block.y, block.z, 
			( data and data.name ) or 0)
		end
	end
	self.taskList:remove(currentTask)
end

function Miner:digMove(safe)		
	-- tries to dig the block in front and move forwards
	-- while not mining any turtles
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local ct = 0
	local result = true	
	
	-- all changes here should be made in Down and Up as well
	
	-- optimization: if it is known that a block is in front -> dig first, then move
	-- trust, that the mapvalue is correct/up to date?
	-- could lead to mining another turtle
	-- why have the map in the first place if it cannot be trusted?
	-- solution: only check block if not safe -> no trust issues
	local blockName
	-- if not safe then
		-- blockName = self:inspect() -- or getMapValue for faster mining
		-- if blockName and blockName ~= 0 then
			-- if not checkDisallowed(blockName) then
				-- self:dig()
			-- end
		-- end
		-- -- else 
			-- -- nonone has been here before -> must be safe -- only for getMapValue
			-- -- but block could also be free so dig is redundant
			-- -- self:dig()
		-- -- end
	-- end
	-- end of optimization --> perhaps delete
	
	--try to move
	while not self:forward() do
		blockName = self:inspect(true) -- cannot move so there has to be a block
		--check block
		if blockName then
			--dig if safe
			local doMine = true
			if safe then
				doMine = checkSafe(blockName)
			else
				-- -> check if its explictly disallowed
				doMine = not checkDisallowed(blockName)
			end
			if doMine then
				self:dig()
				sleep(0.25)
				--print("digMove", checkSafe(blockname), blockName)
			else
				print("NOT SAFE",blockName)
				result = false -- return false
				break
			end
		end
		ct = ct + 1
		if ct > 100 then
			if turtle.getFuelLevel() == 0 then
				self:refuel()
				ct = 90
				--possible endless loop if fuel is empty -> no refuel raises error
			else
				print("UNABLE TO MOVE")
			end
			result = false -- return false
			break
		end
	end

	self.taskList:remove(currentTask)
	return result
end

function Miner:digMoveDown(safe)
	-- check digMove for documentation
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local ct = 0
	local result = true
	
	-- might be an unnecessary optimization for up/down
	-- delete if there are problems with turtles mining each other
	local blockName
	-- if not safe then
		-- blockName = self:inspectDown()
		-- if blockName and blockName ~= 0 then
			-- if not checkDisallowed(blockName) then
				-- self:digDown()
			-- end
		-- end
	-- end
	
	while not self:down() do
		blockName = self:inspectDown(true)
		if blockName then
			local doMine = true
			if safe then
				doMine = checkSafe(blockName)
			else
				doMine = not checkDisallowed(blockName)
			end
			if doMine then
				self:digDown()
				sleep(0.25)
				--print("digMoveDown", checkSafe(blockName), blockName)
			else
				print("NOT SAFE DOWN", blockName)
				result = false
				break
			end
		end
		ct = ct+1
		if ct>100 then
			if turtle.getFuelLevel() == 0 then
				self:refuel()
				ct = 90
			else
				print("UNABLE TO MOVE DOWN")
			end
			result = false
			break
		end
	end
	
	self.taskList:remove(currentTask)
	return result
end

function Miner:digMoveUp(safe)
	-- check digMove for documentation
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local ct = 0
	local result = true
	
	local blockName
	-- if not safe then
		-- blockName = self:inspectUp()
		-- if blockName and blockName ~= 0 then
			-- if not checkDisallowed(blockName) then
				-- self:digUp()
			-- end
		-- end
	-- end
	
	while not self:up() do
		blockName = self:inspectUp(true)
		if blockName then
			local doMine = true
			if safe then
				doMine = checkSafe(blockName)
			else
				doMine = not checkDisallowed(blockName)
			end
			if doMine then
				self:digUp()
				sleep(0.25)
				--print("digMoveUp", checkSafe(blockName), blockName)
			else
				print("NOT SAFE UP", blockName)
				result = false
				break
			end
		end
		ct = ct+1
		if ct>100 then
			if turtle.getFuelLevel() == 0 then
				self:refuel()
				ct = 90
			else
				print("UNABLE TO MOVE UP")
			end
			result = false
			break
		end
	end
	self.taskList:remove(currentTask)
	return result
end


function Miner:digToPos(x,y,z,safe)	
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	print("digToPos:", x, y, z, "safe:", safe)
	-- TODO: if digToPos fails, retry with navigateToPos
	-- 		if that fails as well (not immediately), return to digToPos
	
	-- inspect is unnecessary due to digMove inspecting on demand
	local result = true
	
	if self.pos.x < x then
		self:turnTo(3) -- +x
		self:inspect()
	elseif self.pos.x > x then
		self:turnTo(1) -- -x
		self:inspect()
	end
	while self.pos.x ~= x do
		if not self:digMove(safe) then result = false; break end
		self:inspect()
		self:inspectDown()
		self:inspectUp()
	end
	if result then
		if self.pos.z < z then
			self:turnTo(0) -- +z
			self:inspect()
		elseif self.pos.z > z then
			self:turnTo(2) -- -z
			self:inspect()
		end
		
		while self.pos.z ~= z do
			if not self:digMove(safe) then result = false; break end
			self:inspect()
			self:inspectDown()
			self:inspectUp()
		end
		
		if result then
			while self.pos.y ~= y do
				if self.pos.y < y then
					if not self:digMoveUp(safe) then result = false; break end
					self:inspect()
					self:inspectUp()
				else
					if not self:digMoveDown(safe) then result = false; break end
					self:inspect()
					self:inspectDown()
				end
			end
		end
	end
	self.taskList:remove(currentTask)
	return result
end

function Miner:mineVein() 
	--ore in front? dig, move, inspect
	--ore left? turnleft, dig, move, inspect
	--ore right? turnright, dig, move, inspect
	--ore behind? turnright, turnright, dig, move, inspect
	--ore up? digup, moveup, inspect
	--ore down? digdown, movedown, inspect
	--ore somewhere on map? check last seen ores via list
		--dig towards nearest or last seen ore (last seen = nearest?)
		-- inspect
	--no ores: exit
	--else repeat
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	
	-- local ores
	-- if not id then
		-- ores = oreBlocks
	-- elseif type(id) == "table" then
		-- ores = id
	-- else
		-- ores = { [id]=true }
	-- end
	
	local startPos = vector.new(self.pos.x, self.pos.y, self.pos.z)
	local startOrientation = self.orientation
	local block
	local ct = 0
	local isInVein = false
	
	repeat
	
	self:inspectAll()
	--in front
	block = self.pos + self.vectors[self.orientation]
	if checkOreBlock(self:getMapValue(block.x, block.y, block.z)) then
		self:digMove()
		isInVein = true
	else -- left
		block = self.pos + self.vectors[(self.orientation-1)%4]
		if checkOreBlock(self:getMapValue(block.x, block.y, block.z)) then
			self:turnLeft()
			self:digMove()
			isInVein = true
		else -- right
			block = self.pos + self.vectors[(self.orientation+1)%4]
			if checkOreBlock(self:getMapValue(block.x, block.y, block.z)) then
				self:turnRight()
				self:digMove()
				isInVein = true
			else -- behind
				block = self.pos + self.vectors[(self.orientation+2)%4]
				if checkOreBlock(self:getMapValue(block.x, block.y, block.z)) then
					self:turnRight()
					self:turnRight()
					self:digMove()
					isInVein = true
				else -- up
					if checkOreBlock(self:getMapValue(self.pos.x, self.pos.y+1, self.pos.z)) then
						self:digMoveUp()
						isInVein = true
					else -- down
						if checkOreBlock(self:getMapValue(self.pos.x, self.pos.y-1, self.pos.z)) then
							self:digMoveDown()
							isInVein = true
						else -- nearest ore, if ore has been found before
							if isInVein then
								local nextOre = self.map:findNextBlock(self.pos, 
									checkOreBlock
									,default.maxVeinRadius)
								if nextOre then
									self:digToPos(nextOre.x, nextOre.y, nextOre.z)
								else
									-- done
									break
								end
							else
								-- do not look if none has been found before
								break
							end
						end
					end
				end
			end
		end
	end
	ct = ct + 1
	
	until ct > default.maxVeinSize
	
	--return to start
	self:navigateToPos(startPos.x, startPos.y, startPos.z)
	self:turnTo(startOrientation)
	self.taskList:remove(currentTask)
end

function Miner:stripMine(rowLength, rows, levels, rowFactor, levelFactor)
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	print("stripmining", "rows", rows, "levels", levels)
	if not levels then levels = 1 end
	local positiveLevel = true
	if levels < 0 then 
		positiveLevel = false 
		levels = levels * -1
	end
	local directionFactor = 1 -- -1 for right hand mining
	
	local startPos = vector.new(self.pos.x, self.pos.y, self.pos.z)
	local startOrientation = self.orientation
	
-- OPTIMAL STRATEGIES
-- M -> Mine
-- * -> gets looked at

-- MULTILEVEL lookAtAll
--------------------
--	 * 	 *	 *		
-- * M * M * M *	
--	 * * * * * *
--	 * M * M * M *
--	   *   *   *	
--------------------
	-- local rowFactor = 2
	-- local rowLength = (rows-1) * rowFactor
	-- for currentLevel=1,levels do
		-- for currentRow=1,rows do
			-- self:tunnelMine(rowLength,1,1)
			-- --self:turnRight()
			-- if currentRow < rows then
				-- self:turnTo(startOrientation-1)
				-- self:tunnelMine(rowFactor,1,1)
				-- if currentRow%2 == 1 then
					-- self:turnTo(startOrientation-2)
				-- else
					-- self:turnTo(startOrientation)
				-- end
			-- end
		-- end
		-- -- go up one level
	-- end



	
-- MULTILEVEL speed (leaves areas uninspected)
--------------------
--	 * 	   *	 *		
-- * M * * M * * M *	
--	 * *   * *   * *
--	 * M * * M * * M *
--	   *     *     *	
--------------------

	-- try, catch
	local ok,err = pcall(function()

		if not rowFactor then rowFactor = 3 end
		if not levelFactor then levelFactor = 2 end

		-- local rowLength = (rows-1) * rowFactor
		local rowOrientation = startOrientation
		local tunnelDirection = -1 * directionFactor
		
		for currentLevel=1,levels do
			if currentLevel%2 == 0 and rows%2 == 0 then 
				tunnelDirection = 1 * directionFactor
			else tunnelDirection = -1 * directionFactor end
			
			for currentRow=1,rows do
				self:tunnelStraight(rowLength)
				if currentRow < rows then
					self:turnTo(rowOrientation+tunnelDirection)
					self:tunnelStraight(rowFactor)
					if currentRow%2 == 1 then
						self:turnTo(rowOrientation-2)
					else
						self:turnTo(rowOrientation)
					end
				end
			end
			if currentLevel < levels then
				-- move up
				if positiveLevel then
					self:tunnelUp(levelFactor)
				else
					self:tunnelDown(levelFactor)
				end
				if self.orientation == startOrientation or currentLevel%2 == 0 then
						self:turnRight() 
						self:tunnelStraight(1)
						self:turnRight()
						self:tunnelStraight(1)
				else
					if rows%2 == 0 then
						self:tunnelStraight(1)
						self:turnLeft()
						self:tunnelStraight(1)
						self:turnLeft()
					else
						self:turnLeft()
						self:tunnelStraight(1)
						self:turnLeft()
						self:tunnelStraight(1)
					end
				end
				
			end
			rowOrientation = self.orientation
		end
		
	end)
	
	if not ok then 
		print(ok, err)
	end

--SINGLE LEVEL PART OF MULTILEVEL
--------------------
--	 * 	   *     *
-- * M * * M * * M *
--	 *     *     *
--------------------

	-- only needed for testing i guess
	self:navigateToPos(startPos.x, startPos.y, startPos.z)
	self:turnTo(startOrientation)

	self.taskList:remove(currentTask)
end

function Miner:mineArea(start, finish) 
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	-- TODO: mine area within start and finish pos
	-- 8 corners = 8 possible starting locations, pick nearest
	-- determine how many rows and levels to mine and in which direction
	
	local minX = math.min(start.x, finish.x)
	local minY = math.min(start.y, finish.y)
	local minZ = math.min(start.z, finish.z)
	local maxX = math.max(start.x, finish.x)
	local maxY = math.max(start.y, finish.y)
	local maxZ = math.max(start.z, finish.z)
	
	local width = math.abs(start.x - finish.x)
	local height = math.abs(start.y - finish.y)
	local depth = math.abs(start.z - finish.z)
	
	
	local corners = {
		-- 1-4 bottom
		vector.new(minX, minY, minZ),
		vector.new(minX, minY, maxZ),
		vector.new(maxX, minY, minZ),
		vector.new(maxX, minY, maxZ),
		-- 5-8 top
		vector.new(maxX, maxY, maxZ),
		vector.new(maxX, maxY, minZ),
		vector.new(minX, maxY, maxZ),
		vector.new(minX, maxY, minZ),
		-- 1 is opposite to (id + 4) % 8
	}
	
	local minCost, minId
	for id,corner in ipairs(corners) do
		local cost = math.abs(self.pos.x - corner.x) + math.abs(self.pos.y - corner.y) + math.abs(self.pos.z - corner.z)
		if minCost == nil or cost < minCost then
			minCost = cost
			minId = id
		end
	end
	
	print("start", start,"end",finish)
	
	start = corners[minId]
	finish = corners[((minId+3)%8)+1] -- opposite corner
	
	
	local diff = finish - start
	local width = math.abs(diff.x)
	local height = math.abs(diff.y)
	local depth = math.abs(diff.z)
	
	-- turn to the correct orientation 
	-- 	+z = 0	south
	-- 	-x = 1	west
	-- 	-z = 2	north
	-- 	+x = 3 	east
	local orientation
	if diff.x <= 0 and diff.z > 0 then
		orientation = 1 
	elseif diff.x <= 0 and diff.z <= 0 then
		orientation = 2 
	elseif diff.x > 0 and diff.z <= 0 then
		orientation = 3 
	else
		orientation = 0 
	end
	
	local rowFactor = 3
	local levelFactor = 2
	local rowLength, rows, levels
	if orientation%2 == 0 then
		rowLength = depth
		rows = (width+rowFactor)/rowFactor
	else
		rowLength = width
		rows = (depth+rowFactor)/rowFactor
	end
	if diff.y < 0 then
		levels = math.floor(((-height-levelFactor)/levelFactor)+0.5)
	else
		levels = math.floor(((height+levelFactor)/levelFactor)+0.5)
	end
	
	rows = math.floor(rows+0.5)
	--self.map:load()
	
	print("start", start,"end",finish, "diff", diff, "levels", levels)
	
	if not self:navigateToPos(start.x, start.y, start.z) then
		print("unable to get to area")
		self:returnHome()
	else
	
		self:turnTo(orientation)
		
		self:stripMine(rowLength, rows, levels)
		
		self:returnHome()
		self:condenseInventory()
		self:dumpBadItems()
		self:transferItems()
		--self:getFuel()
		--self.map:save()
	end 
	self.taskList:remove(currentTask)
end


function Miner:tunnel(length, direction)
	-- throws error
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	
	local result = true
	local skipSteps = 0
	
	-- determine direction to mine
	if not direction or direction == "straight" then 
		directionVector = self.vectors[self.orientation]
		digFunc = Miner.digMove
	elseif direction == "up" then
		directionVector = vectorUp
		digFunc = Miner.digMoveUp
	elseif direction == "down" then
		directionVector = vectorDown
		digFunc = Miner.digMoveDown
	end
	
	local expectedEndPos = self.pos + directionVector * length
	local startOrientation = self.orientation
	
	-- actually mine
	for i=1,length do
		if skipSteps == 0 then 
		
			self:inspectMine()
			if not digFunc(self) then 
				-- if two turtles get in each others way, steps could be skipped
				-- try to navigate to next step, else quit
				if i < length - 1 then
					newPos = self.pos + directionVector * 2
					if not self:navigateToPos(newPos.x, newPos.y, newPos.z) then
						result = false
						break
					else 
						self:turnTo(startOrientation)
						skipSteps = 2
						--skip the next step as well
					end
				else
					result = false
					break
				end
			end
		else
			skipSteps = skipSteps - 1
		end
		
	end
	
	self:inspectMine()
	
	if self.pos ~= expectedEndPos then
		-- try navigating to the position we should be at
		if not self:navigateToPos(expectedEndPos.x, expectedEndPos.y, expectedEndPos.z) then
			-- we truly failed
			result = false
		else 
			result = true
		end
		self:turnTo(startOrientation)
	end
	
	self.taskList:remove(currentTask)
	
	if not result then error("TUNNEL FAIL") end
	return result
	
end

function Miner:tunnelStraight(length)
	return self:tunnel(length,"straight")
end

function Miner:tunnelUp(height)
	return self:tunnel(height,"up")
end

function Miner:tunnelDown(height)
	return self:tunnel(height,"down")
end

function Miner:inspectMine()
	-- useless function
	self:mineVein()
	return
end

--##############################################################

function Miner:navigateToPos(x,y,z)
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = true
	local goal = vector.new(x,y,z)
	if self.pos ~= goal then
	
		-- calculate how many tries are allowed
		local diff = self.pos - goal
		local cost = math.abs(diff.x) + math.abs(diff.y) + math.abs(diff.z)	
		local maxTries = cost / 2
		if maxTries < 15 then maxTries = default.pathfinding.maxTries end
		local maxParts = ( cost / default.pathfinding.maxDistance ) * 2
		if maxParts < 2 then maxParts = default.pathfinding.maxParts end
		local ct = 0
		local minDist = -1
		local mapReset = false
		
		local pathFinder = PathFinder()
		pathFinder.checkValid = checkSafe
		
		repeat
			ct = ct + 1
			local countParts = 0
			repeat 
				countParts = countParts+1
				local path = pathFinder:aStarPart(self.pos, self.orientation, goal , self.map, nil)
				if path then 
					if not self:followPath(path) then 
						-- print("NOT SAFE TO FOLLOW PATH")
						result = false
					else 
						if self.pos == goal then
							result = true 
						else
							-- check if the goal can be reached
							local cp = self.pos
							local dist = math.abs(cp.x - goal.x) + math.abs(cp.y - goal.y) + math.abs(cp.z - goal.z)
							--print("min", minDist, "dist", dist, "try", ct, "part", countParts)
							result = false
							if minDist < 0 or dist < minDist then 
								minDist = dist
							elseif dist >= minDist and ct > 1 then  
								path = pathFinder:checkPossible(self.pos, self.orientation, goal, self.map, nil, not mapReset)
								if not path then 
									
									if not mapReset then 
										mapReset = true
										countParts = 0
										ct = math.max(ct, maxTries/2)
									else
										-- path truly impossible
										print("IMPOSSIBLE GOAL", goal)
										
										ct = maxTries
										countParts = maxParts
										-- get home as near as possible
										result = self:digToPos(self.home.x, self.home.y, self.home.z, true)
										
									end
									
								else
									print("GOAL POSSIBLE", goal, #path)
									result = self:followPath(path)
								end
							end
						end
					end
				else
					if not self:digToPos(self.home.x, self.home.y, self.home.z, true) then
						--path was not safe
						print("NOT SAFE TO DIG TO POS")
						result = false
						countParts = maxParts
					else result = true end
				end
			until result == true or countParts >= maxParts
		until result == true or ct >= maxTries
	end
	
	if result == false then 
		print("NOT SAFE TO FOLLOW PATH AFTER MULTIPLE TRIES")
	end
	
	self.taskList:remove(currentTask)
	return result
end

function Miner:followPath(path)
	-- safe function
	--print("FOLLOWING PATH TO", path[#path].pos)
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = true
	local safe = true -- always safe?
	for _,step in ipairs(path) do
		if step.pos ~= self.pos  then
			local diff = step.pos - self.pos
			local newOr
			local upDown = 0
			if diff.x < 0 then newOr = 1
			elseif diff.x > 0 then newOr = 3
			elseif diff.z < 0 then newOr = 2
			elseif diff.z > 0 then newOr = 0
			elseif diff.y < 0 then upDown = -1
			else upDown = 1 end
	
			if upDown > 0 then
				if not self:digMoveUp(safe) then 
					result = false --return false
					break
				end
			elseif upDown < 0 then
				if not self:digMoveDown(safe) then 
					result = false --return false
					break
				end
			else
				if (newOr-2)%4 == self.orientation and step.block == 0 then
					if not self:back() then
						self:turnTo(newOr)
						print("cannot move backwards")
						result = false
						break
					end
				else
					if newOr ~= self.orientation then
						self:turnTo(newOr)
						self:inspect() --inspect left / right
					end
					if not self:digMove(safe) then
						result = false
						break
					end
				end
			end
			self:inspect()
			self:inspectUp()
			self:inspectDown()
		end 
	end
	--if not result and path[#path].pos == step.pos then
	--	self:error("GOAL IS BLOCKED")
	-- leads to infinite loop
	--end
	self.taskList:remove(currentTask)
	return result
	
end