local Heap = require("classHeap")
require("classMap")
require("classLogger")
require("classList")

local default = {
	waitTimeFallingBlock = 0.5,
	maxVeinRadius = 32,
	maxVeinSize = 256,
	inventorySize = 16,
	criticalFuelLevel = 128,
	goodFuelLevel = 1600,
	maxHomeDistance = 128,
	file = "runtime/miner.txt",
	fuelAmount = 16,
}

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
["minecraft:andesite"]=true,
["minecraft:deepslate"]=true,
--["minecraft:glass"]=true,
}


local fuelItems = {
["minecraft:coal"]=true,
["minecraft:charcoal"]=true,
["minecraft:coal_block"]=true,
["minecraft:lava_bucket"]=true,
}

local inventoryBlocks = {
["minecraft:chest"]=true,
["minecraft:hopper"]=true,
}

local disallowedBlocks = {
["minecraft:chest"] = true
}

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
	o.pos = {}
	o.gettingFuel = false
	o.lookingAt = vector.new(0,0,0)
	o.map = Map:new()
	o.taskList = List:new()
	o.vectors = {}
	o.vectors[0] = vector.new(0,0,1)  -- 	+z = 0	south
	o.vectors[1] = vector.new(-1,0,0) -- 	-x = 1	west
	o.vectors[2] = vector.new(0,0,-1) -- 	-z = 2	north
	o.vectors[3] = vector.new(1,0,0)  -- 	+x = 3 	east
	
	o:initialize()
	print("--------------------")
	return o
end


function Miner:initialize()
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	self:requestMap()
	self:refuel()
	print("fuel level:", turtle.getFuelLevel())
	self:initPosition()
	self:initOrientation()
	if not self:requestStation() then
		self:setHome(self.pos.x, self.pos.y, self.pos.z)
	end
	self:setStartupPos(self.pos)
	
	self.taskList:remove(currentTask)
end	

function Miner:initPosition()
	local x,y,z = gps.locate()
	if x and y and z then
		self.pos = vector.new(x,y,z)
	else
		--gps not working
		print("gps not working")
		self.pos = vector.new(0,70,0)
	end
	print("position:",self.pos.x,self.pos.y,self.pos.z)
end

function Miner:initOrientation()
	local newPos
	local turns = 0
	for i=1,4 do
		
		if not turtle.forward() then
			self:turnLeft()
			turns = turns + 1
		else
			newPos = vector.new(gps.locate())
			break
		end
	end
	if not newPos then
		print("orientation not determinable")
		self.orientation = 0
	else
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
	-- print("orientation:", self.orientation)
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
	if global.node and global.node.host then
		local answer, forMsg = self.node:send(global.node.host,
		{"REQUEST_MAP"},true,true)
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

function Miner:requestStation()
	-- ask host for station
	local retval = false
	if global.node and global.node.host then
		local answer, forMsg = self.node:send(global.node.host,{"REQUEST_STATION"},true,true)
		if answer then
			if answer.data[1] == "STATION" then
				retval = true
				local station = answer.data[2]
				self:setStation(station)
			elseif answer.data[1] == "STATIONS_FULL" then
				self:setStation(nil)
			end
		else
			--print("no station answer")
		end
	else
		--print("no station host")
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
	if self.home then
		print("RETURNING HOME", self.home.x, self.home.y, self.home.z)
		self:navigateToPos(self.home.x, self.home.y, self.home.z)
		self:turnTo(self.homeOrientation)
	end
	self.taskList:remove(currentTask)
end

function Miner:error(reason,real)
	-- TODO: create image of current Miner to load later on
	-- self:save()

	if self.taskList.count > 0 then func = "ERR:"..self.taskList:getFirst()[1]
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
	return self.taskList:add(task)
end

function Miner:checkStatus()
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	-- called by self:forward()
	self:refuel()
	if self:getEmptySlots() == 0 then
		self:condenseInventory()
		if self:getEmptySlots() < 2 then
			self:dumpBadItems()
			if self:getEmptySlots() < 2 then
				self:returnHome()
				self:transferItems()
				if self:getEmptySlots() < 2 then
					-- do nothing and return to task
				else
					-- catch this in stripmine e.g.
					self:error("INVENTORY_FULL",true)
				end
			end
		end
	end
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

function Miner:transferItems()
	--check for chest and transfer items
	--do not transfer all fuel items (keep 1 stack)
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local hasFuel = false
	local hasInventory = false
	local startOrientation = self.orientation
	
	for k=1,4 do
	--check for chest
		self:inspect()
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
		else
			--if self:getCostHome() * 2 > turtle.getFuelLevel() then
				local startPos = vector.new(self.pos.x, self.pos.y, self.pos.z)
				local startOrientation = self.orientation
				if not self:getFuel() then
					self:returnHome()
					self:error("NEED FUEL",true) -- -> terminates stripMine etc.
				else
					refueled = true
					self:navigateToPos(startPos.x, startPos.y, startPos.z)
					self:turnTo(startOrientation)
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
				self:inspect()
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
	
	self.gettingFuel = false
	
	if not result then
		print(result)
		result = false
	end
	
	self.taskList:remove(currentTask)
	return result
end

function Miner:setMapValue(x,y,z,value)
	self.map:logData(x,y,z,value)
	self.map:setData(x,y,z,value)
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
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = turtle.forward()
	if result then
		self:setMapValue(self.pos.x, self.pos.y, self.pos.z, 0)
		self.pos = self.pos + self.vectors[self.orientation]
	end
	self:checkStatus()
	self.taskList:remove(currentTask)
	return result
end

function Miner:back()
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = turtle.back()
	if result then
		self:setMapValue(self.pos.x, self.pos.y, self.pos.z, 0)
		self.pos = self.pos - self.vectors[self.orientation]
	end
	self.taskList:remove(currentTask)
	return result
end

function Miner:up()
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = turtle.up()
	if result then
		self:setMapValue(self.pos.x, self.pos.y, self.pos.z, 0)
		self.pos.y = self.pos.y + 1
	end
	self.taskList:remove(currentTask)
	return result
end

function Miner:down()
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = turtle.down()
	if result then
		self:setMapValue(self.pos.x, self.pos.y, self.pos.z, 0)
		self.pos.y = self.pos.y - 1
	end
	self.taskList:remove(currentTask)
	return result
end

function Miner:turnLeft()
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	turtle.turnLeft()
	self.orientation = ( self.orientation - 1 ) % 4
	self.taskList:remove(currentTask)
end

function Miner:turnRight()
	turtle.turnRight()
	self.orientation = ( self.orientation + 1 ) % 4
end

function Miner:dig(side)
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = turtle.dig(side)
	if result then
		self:updateLookingAt()
		if self:getMapValue(self.lookingAt.x, self.lookingAt.y, self.lookingAt.z) then
			self:setMapValue(self.lookingAt.x, self.lookingAt.y, self.lookingAt.z,0)
		end
	end
	self.taskList:remove(currentTask)
	return result
end

function Miner:digUp(side)
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = turtle.digUp(side)
	if result then
		if self:getMapValue(self.pos.x, self.pos.y+1, self.pos.z) then
			self:setMapValue(self.pos.x, self.pos.y+1, self.pos.z, 0)
		end
	end
	self.taskList:remove(currentTask)
	return result
end

function Miner:digDown(side)
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = turtle.digDown(side)
	if result then
		if self:getMapValue(self.pos.x, self.pos.y-1, self.pos.z) then
			self:setMapValue(self.pos.x, self.pos.y-1, self.pos.z, 0)
		end
	end
	self.taskList:remove(currentTask)
	return result
end

function Miner:checkSafe(id)
	-- does not take changed blocks into account if id comes from the map value
	local isSafe = false
	if not id or id == 0 or mineBlocks[id] or oreBlocks[id] then
		isSafe = true
	end
	return isSafe
end

function Miner:safeDig(side)
	local blockName = self:inspect()
	if self:checkSafe(blockName) then self:dig() return true end
	return false
end

function Miner:safeDigUp(side)
	local blockName = self:inspectUp()
	if self:checkSafe(blockName) then self:digUp() return true end
	return false
end

function Miner:safeDigDown(side)
	local blockName = self:inspectDown()
	if self:checkSafe(blockName) then self:digDown() return true end
	return false
end

function Miner:safeDigMove()		
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local ct = 0
	local result = true
	--try to move
	while not self:forward() do
		local blockName = self:inspect(true)
		--check block
		if blockName then
			--dig if safe
			if self:checkSafe(blockName) then
				self:dig()
				sleep(0.25)
				print(self:checkSafe(blockname), blockName)
			else
				print("NOT SAFE",blockName)
				result = false -- return false
				break
			end
		end
		ct = ct + 1
		if ct > 100 then
			if turtle.getFuelLevel == 0 then
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

function Miner:digMove()
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local ct = 0
	local result = true
	
	while not self:forward() do
		local hasBlock = turtle.detect()
		if hasBlock then
			self:dig()
			sleep(0.25)
		end
		ct = ct + 1
		if ct > 100 then
			if turtle.getFuelLevel == 0 then
				self:refuel()
				ct = 90
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

function Miner:digToPos(x,y,z,safe)	
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	--print("digToPos:", x, y, z, "safe:", safe)
	local result = true
	
	if self.pos.x < x then
		self:turnTo(3) -- +x
		self:inspect()
	elseif self.pos.x > x then
		self:turnTo(1) -- -x
		self:inspect()
	end
	while self.pos.x ~= x do
		if safe then 
			if not self:safeDigMove() then result = false; break end
		else self:digMove() end
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
			if safe then 
				if not self:safeDigMove() then result = false; break end
			else self:digMove() end
			self:inspect()
			self:inspectDown()
			self:inspectUp()
		end
		
		if result then
			while self.pos.y ~= y do
				if self.pos.y < y then
					if safe then 
						if not self:safeDigUp() then result = false; break end
					else self:digUp() end
					self:up()
					self:inspect()
					self:inspectUp()
				else
					if safe then 
						if not self:safeDigDown() then result = false; break end
					else self:digDown() end
					self:down()
					self:inspect()
					self:inspectDown()
				end
			end
		end
	end
	self.taskList:remove(currentTask)
	return result
end

function Miner:inspect(safe)
	-- WARNING: does NOT update the Map if the block has been explored before
	-- -> separate function safeInspect or inspect(safe)
	self:updateLookingAt()
	local blockName 
	if not safe then 
		blockName = self:getMapValue(self.lookingAt.x, self.lookingAt.y, self.lookingAt.z)
	end
	if blockName == nil then
		-- never inspected before
		local hasBlock, data = turtle.inspect()
		self:setMapValue(self.lookingAt.x,self.lookingAt.y,self.lookingAt.z,
		( data and data.name ) or 0)
		blockName = data.name
	end
	return blockName
end
-- function Miner:inspect()
	-- -- WARNING: does NOT update the Map if the block has been explored before
	-- -- -> separate function safeInspect or inspect(safe)
	-- self:updateLookingAt()
	-- local blockName = self:getMapValue(self.lookingAt.x, self.lookingAt.y, self.lookingAt.z)
	-- if blockName == nil then
		-- -- never inspected before
		-- local hasBlock, data = turtle.inspect()
		-- self:setMapValue(self.lookingAt.x,self.lookingAt.y,self.lookingAt.z,
		-- ( data and data.name ) or 0)
		-- blockName = data.name
	-- end
	-- return blockName
-- end
function Miner:inspectUp()
	local blockName = self:getMapValue(self.pos.x, self.pos.y+1, self.pos.z)
	if blockName == nil then
		local hasBlock, data = turtle.inspectUp()
		self:setMapValue(self.pos.x,self.pos.y+1,self.pos.z,
		( data and data.name ) or 0)
		blockName = data.name
	end
	return blockName
end
function Miner:inspectDown()
	local blockName = self:getMapValue(self.pos.x, self.pos.y-1, self.pos.z)
	if blockName == nil then
		local hasBlock, data = turtle.inspectDown()
		self:setMapValue(self.pos.x,self.pos.y-1,self.pos.z,
		( data and data.name ) or 0)
		blockName = data.name
	end
	return blockName
end
function Miner:inspectLeft()
	local block = self.pos + self.vectors[(orientation-1)%4]
	local blockName = self:getMapValue(block.x, block.y, block.z)
	if blockName == nil then
		self:turnTo((orientation-1)%4)
		local hasBlock, data = turtle.inspect()
		self:setMapValue(block.x, block.y, block.z, 
		( data and data.name ) or 0)
		blockName = data.name
	end
	return blockName
end
function Miner:inspectRight()
	local block = self.pos + self.vectors[(orientation+1)%4]
	local blockName = self:getMapValue(block.x, block.y, block.z)
	if blockName == nil then
		self:turnTo((orientation+1)%4)
		local hasBlock, data = turtle.inspect()
		self:setMapValue(block.x, block.y, block.z,
		( data and data.name ) or 0)
		blockName = data.name
	end
	return blockName
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

function Miner:mineVein(id) 
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
	
	local ores
	if not id then
		ores = oreBlocks
	elseif type(id) == "table" then
		ores = id
	else
		ores = { [id]=true }
	end
	
	local startPos = vector.new(self.pos.x, self.pos.y, self.pos.z)
	local startOrientation = self.orientation
	local block
	local ct = 0
	
	repeat
	
	self:inspectAll()
	--in front
	block = self.pos + self.vectors[self.orientation]
	if ores[self:getMapValue(block.x, block.y, block.z)] then
		self:digMove()
	else -- left
		block = self.pos + self.vectors[(self.orientation-1)%4]
		if ores[self:getMapValue(block.x, block.y, block.z)] then
			self:turnLeft()
			self:digMove()
		else -- right
			block = self.pos + self.vectors[(self.orientation+1)%4]
			if ores[self:getMapValue(block.x, block.y, block.z)] then
				self:turnRight()
				self:digMove()
			else -- behind
				block = self.pos + self.vectors[(self.orientation+2)%4]
				if ores[self:getMapValue(block.x, block.y, block.z)] then
					self:turnRight()
					self:turnRight()
					self:digMove()
				else -- up
					if ores[self:getMapValue(self.pos.x, self.pos.y+1, self.pos.z)] then
						self:digUp()
						self:up()
					else -- down
						if ores[self:getMapValue(self.pos.x, self.pos.y-1, self.pos.z)] then
							self:digDown()
							self:down()
						else -- nearest ore
							local nextOre = self.map:findNextBlock(self.pos, ores, default.maxVeinRadius)
							if nextOre then
								self:digToPos(nextOre.x, nextOre.y, nextOre.z)
							else
								-- done
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
			self:tunnelMine(rowLength,1,1)
			if currentRow < rows then
				self:turnTo(rowOrientation+tunnelDirection)
				self:tunnelMine(rowFactor,1,1)
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
					self:tunnelMine(1,1,1)
					self:turnRight()
					self:tunnelMine(1,1,1)
			else
				if rows%2 == 0 then
					self:tunnelMine(1,1,1)
					self:turnLeft()
					self:tunnelMine(1,1,1)
					self:turnLeft()
				else
					self:turnLeft()
					self:tunnelMine(1,1,1)
					self:turnLeft()
					self:tunnelMine(1,1,1)
				end
			end
			
		end
		rowOrientation = self.orientation
	end

--SINGLE LEVEL PART OF MULTILEVEL
--------------------
--	 * 	   *     *
-- * M * * M * * M *
--	 *     *     *
--------------------

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
	levels = math.floor(((diff.y+levelFactor)/levelFactor)+0.5)
	rows = math.floor(rows+0.5)
	--self.map:load()
	
	self:navigateToPos(start.x, start.y, start.z)
	self:turnTo(orientation)
	
	self:stripMine(rowLength, rows, levels)
	
	self:returnHome()
	self:condenseInventory()
	self:dumpBadItems()
	self:transferItems()
	--self:getFuel()
	--self.map:save()
	
	
	self.taskList:remove(currentTask)
end

function Miner:tunnelMine(length,height,width)
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	for i=1,length do
		self:inspectMine()
		self:digMove()
	end
	self:inspectMine()
	self.taskList:remove(currentTask)
end

function Miner:tunnelUp(height)
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	for i=1,height do
		self:inspectMine()
		self:digUp()
		self:up()
	end
	self:inspectMine()
	self.taskList:remove(currentTask)
end
function Miner:tunnelDown(height)
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	for i=1,height do
		self:inspectMine()
		self:digDown()
		self:down()
	end
	self:inspectMine()
	self.taskList:remove(currentTask)
end

function Miner:inspectMine()
	-- useless function
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	self:mineVein()
	self.taskList:remove(currentTask)
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
		if maxTries < 15 then maxTries = 15 end
		local ct = 0

		repeat
			ct = ct + 1
			local path = self:aStar(self.pos, self.orientation, goal , self.map.map)
			if path then 
				if not self:followPath(path) then 
					print("NOT SAFE TO FOLLOW PATH")
					result = false
				else result = true end
			else
				if not self:digToPos(self.home.x, self.home.y, self.home.z, true) then
					--path was not safe
					print("NOT SAFE TO DIG TO POS")
					result = false
				else result = true end
			end
		until result == true or ct >= maxTries
	end
	
	if result == false then 
		print("NOT SAFE TO FOLLOW PATH AFTER MULTIPLE TRIES")
	end
	
	self.taskList:remove(currentTask)
	return result
end

function Miner:reconstructPath(flatPath, cameFrom, currentNode)
	-- doesnt have to be recursive ...
	local fromNode = cameFrom[self:posToString(currentNode)]
	if fromNode then
		table.insert(flatPath, 1, fromNode) 
		return self:reconstructPath(flatPath, cameFrom, fromNode)
	else
		return flatPath
	end
end

function Miner:calculateHeuristic(current,goal)
	--manhattan = orthogonal
	local h = math.abs(current.x - goal.x) + math.abs(current.y - goal.y) + math.abs(current.z - goal.z)
	--local h = math.sqrt((current.x-goal.x)^2 + (current.y+goal.y)^2 + (current.z+goal.z)^2)
	return h
	-- --diagonal = 8 richtigungen mit grid
	-- dx = abs(current – goal.x)
	-- dy = abs(current – goal.y)
	-- dz = abs(current.z - goal.z)
	-- -- D = length of node (cost) ... 
	-- -- D2 is diagonal distance = sqrt(2) <-- 2D
	-- h = D * (dx + dy) + (D2 - 2 * D) * min(dx, dy)

	--euclidian = omnidirektional (ohne grid)
end

function Miner:posToId(pos)
	--return self:xyzToId(pos.x, pos.y, pos.z)
	return self.map:xyzToId(pos.x, pos.y, pos.z)
end

function Miner:posToString(pos, orientation)
    if orientation then
        return pos.x .. ',' .. pos.y .. ',' .. pos.z .. ':' .. orientation
    else
        return pos.x .. ',' .. pos.y .. ',' .. pos.z
    end
end

function Miner:posFromString(str) end

--REWRITE GETBLOCK BECAUSE ITS RELATIVE Miner:getBlockUp
function Miner:getBlockForward(current)
	local block = { pos = current.pos + self.vectors[current.orientation], orientation = current.orientation }
	return block
end
function Miner:getBlockUp(current)
	--if not current then current = { pos = self.pos, orientation = self.orientation } end
	local block = { pos = vector.new(current.pos.x, current.pos.y+1, current.pos.z), orientation = current.orientation }
	return block
end
function Miner:getBlockDown(current)
	local block = { pos = vector.new(current.pos.x, current.pos.y-1, current.pos.z), orientation = current.orientation }
	return block
end
function Miner:getBlockLeft(current)
	-- self reference is missing
	local block = { pos = current.pos + self.vectors[(current.orientation-1)%4], orientation = (current.orientation-1)%4 }
	return block
end
function Miner:getBlockRight(current)
	local block = { pos = current.pos + self.vectors[(current.orientation+1)%4], orientation = (current.orientation+1)%4 }
	return block
end
function Miner:getBlockBack(current)
	local block = { pos = current.pos + self.vectors[(current.orientation+2)%4], orientation = (current.orientation+2)%4 }
	return block
end

function Miner:checkValidNode(block, map)
	local blockName = self:getMapValue(block.x, block.y, block.z)
	-- if blockName and ( blockName == 0 or mineBlocks[blockName] or oreBlocks[blockName] ) then
	-- --UNCOMMENTED: allow digging through unknown blocks.
		-- return true
	-- end
	-- return false
	return self:checkSafe(blockName)
end

function Miner:getNeighbours(current, map)
	local neighbours = {}
	-- neighbour = { pos, orientation }
	local neighbour
	
	neighbour = self:getBlockDown(current)
	if self:checkValidNode(neighbour.pos, map) == true then
		table.insert(neighbours, neighbour)
	end
	neighbour = self:getBlockUp(current)
	if self:checkValidNode(neighbour.pos, map) == true then
		table.insert(neighbours, neighbour)
	end
	
	neighbour = self:getBlockLeft(current)
	if self:checkValidNode(neighbour.pos, map) == true then
		table.insert(neighbours, neighbour)
	end
	neighbour = self:getBlockRight(current)
	if self:checkValidNode(neighbour.pos, map) == true then
		table.insert(neighbours, neighbour )
	end
	neighbour = self:getBlockBack(current)
	if self:checkValidNode(neighbour.pos, map) == true then
		table.insert(neighbours, neighbour)
	end
	
	neighbour = self:getBlockForward(current)
	if self:checkValidNode(neighbour.pos, map) == true then
		table.insert(neighbours, neighbour)
	end
	
	return neighbours
end

costOrientation = {
[0] = 1, 	-- forward, up, down
[2] = 1.75, -- back
[-2] = 1.75, -- back
[-1] = 1.5, -- left
[3] = 1.5,	-- left
[1] = 1.5,	-- right
[-3] = 1.5,	-- right
}

--KEEP COSTS LOW BECAUSE HEURISTIC VALUE IS ALSO SMALL IN DIFFERENCE

function Miner:calculateCost(current,neighbour)
	
	local cost = costOrientation[(neighbour.orientation-current.orientation)]
	neighbour.blockName = self:getMapValue(neighbour.pos.x, neighbour.pos.y, neighbour.pos.z)
	--TODO: move mapCheck to checkValidNode and attach blockName to neighbour
	
	if neighbour.blockName then
		--block already explored
		if neighbour.blockName == 0 then
			-- no extra cost
		else
			-- if block is mineable is checked in checkValidNode -> not yet
			cost = cost + 0.75 -- 0.75 fastest
			-- WARNING: we dont neccessarily know which block comes after this one...
		end
	else
		-- it is unknown what type of block is here could be air, could be a chest
		-- SOLUTION -> recalculate path when it is blocked by a disallowed block
		cost = cost + 1.5 -- 1.5 fastest
	end
	return cost
end

function Miner:aStar(startPos, startOrientation, finishPos, map)
	-- very good path for medium distances
	-- e.g. navigateHome
	-- start and finish must be free!
	if not self:checkValidNode(finishPos, map) then
		print("ASTAR: FINISH NOT VALID", self:getMapValue(finishPos.x, finishPos.y, finishPos.z))
		self:setMapValue(finishPos.x, finishPos.y, finishPos.z,0)
		-- override current map value
	end
	
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local start = { pos = startPos, orientation = startOrientation }
	local finish = { pos = finishPos }
	start.blockName = 0 -- for followPath
	
	local gScore = {}
	local startId = self:posToId(start.pos)
	gScore[startId] = 0
	start.gScore = 0
	start.fScore = self:calculateHeuristic(start.pos, finish.pos)
	
	local open = Heap()
	local closed = {}
	open.Compare = function(a,b)
		return a.fScore < b.fScore
	end
	open:Push(start)
	
	local ct = 0
	
	while not open:Empty() do
		ct = ct + 1
		
		local current = open:Pop()
		--logger:add(tostring(current.pos))
		
		local currentId = self:posToId(current.pos)
		if not closed[currentId] then
			if current.pos == finish.pos then
				local path = {}
				while true do
					if current.previous then
						table.insert(path, 1, current)
						current = current.previous
					else
						table.insert(path, 1, start)
						print("FOUND PATH, MOVES:", #path, "ITERATIONS:", ct)
						self.taskList:remove(currentTask)
						return path
					end		
				end
			end
			closed[currentId] = true
			
			local neighbours = self:getNeighbours(current, map)
			for i=1, #neighbours do
				local neighbour = neighbours[i]
				local neighbourId = self:posToId(neighbour.pos)
				if not closed[neighbourId] then
					local addedGScore = current.gScore + self:calculateCost(current,neighbour)
					
					neighbour.gScore = gScore[neighbourId]
					if not neighbour.gScore or addedGScore < neighbour.gScore then
						gScore[neighbourId] = addedGScore
						neighbour.gScore = addedGScore
						
						if not neighbour.hScore then
							neighbour.hScore = self:calculateHeuristic(neighbour.pos,finish.pos)
						end
						neighbour.fScore = addedGScore + neighbour.hScore
						
						open:Push(neighbour)
						neighbour.previous = current
					end
				end
			end
		end
		if ct > 1000000 then
			print("NO PATH FOUND")
			self.taskList:remove(currentTask)
			return nil
		end
		if ct%10000 == 0 then
			sleep(0.001) -- to avoid timeout
		end
	end
	self.taskList:remove(currentTask)
	return nil
	--https://github.com/GlorifiedPig/Luafinding/blob/master/src/luafinding.lua
end

function Miner:followPath(path)
	-- safe function
	print("FOLLOWING PATH TO", path[#path].pos)
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	local result = true
	for _,step in ipairs(path) do
		if step.pos ~= self.pos then
			local diff = step.pos - self.pos
			local newOr
			local upDown = 0
			if diff.x < 0 then newOr = 1
			elseif diff.x > 0 then newOr = 3
			elseif diff.z < 0 then newOr = 2
			elseif diff.z > 0 then newOr = 0
			elseif diff.y < 0 then upDown = -1
			else upDown = 1 end
			
			--TODO: check if path is blocked by a block that is not allowed to mine
			-- while following: check if safeDigMove fails 
			-- -> compare Block to Block from map,
			-- -> recalculate Path, repeat, done
			
			
			if upDown > 0 then
				if not self:safeDigUp() then 
					print("1")
					result = false --return false
					break
				end
				self:up()
			elseif upDown < 0 then
				if not self:safeDigDown() then 
					print("2")
					result = false --return false
					break
				end
				self:down()
			else
				if (newOr-2)%4 == self.orientation and step.blockName == 0 then
					self:back()
				else
					if newOr ~= self.orientation then
						self:turnTo(newOr)
						self:inspect() --inspect left / right
					end
					if not self:safeDigMove() then
						print("3")
						result = false --return false
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