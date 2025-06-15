local PathFinder = require("classPathFinder")
local CheckPointer = require("classCheckPointer")
require("classLogger")
require("classList")
require("classChunkyMap")
local bluenet = require("bluenet")
local config = config

local default = {
	waitTimeFallingBlock = 0.25,
	maxVeinRadius = 10, --8 MAX:16
	maxVeinSize = 256,
	inventorySize = 16,
	criticalFuelLevel = 512,
	goodFuelLevel = 4099,
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
["minecraft:coal"]=80,
["minecraft:charcoal"]=80,
["minecraft:coal_block"]=800,
["minecraft:lava_bucket"]=1000,
}
-- do not translate

local mineBlocks = {
-- Basic terrain blocks
["minecraft:cobblestone"]=true,
["minecraft:stone"]=true,
["minecraft:smooth_stone"]=true,
["minecraft:grass_block"]=true,
["minecraft:dirt"]=true,
["minecraft:coarse_dirt"]=true,
["minecraft:podzol"]=true,
["minecraft:mycelium"]=true,
["minecraft:grass_path"]=true,
["minecraft:farmland"]=true,
["minecraft:gravel"]=true,
["minecraft:sand"]=true,
["minecraft:red_sand"]=true,
["minecraft:sandstone"]=true,
["minecraft:red_sandstone"]=true,
["minecraft:chiseled_sandstone"]=true,
["minecraft:chiseled_red_sandstone"]=true,
["minecraft:cut_sandstone"]=true,
["minecraft:cut_red_sandstone"]=true,
["minecraft:smooth_sandstone"]=true,
["minecraft:smooth_red_sandstone"]=true,

-- Stone variants
["minecraft:diorite"]=true,
["minecraft:granite"]=true,
["minecraft:andesite"]=true,
["minecraft:polished_diorite"]=true,
["minecraft:polished_granite"]=true,
["minecraft:polished_andesite"]=true,
["minecraft:tuff"]=true,
["minecraft:calcite"]=true,
["minecraft:dripstone_block"]=true,
["minecraft:pointed_dripstone"]=true,

-- Deepslate variants
["minecraft:deepslate"]=true,
["minecraft:cobbled_deepslate"]=true,
["minecraft:polished_deepslate"]=true,
["minecraft:deepslate_bricks"]=true,
["minecraft:deepslate_tiles"]=true,
["minecraft:cracked_deepslate_bricks"]=true,
["minecraft:cracked_deepslate_tiles"]=true,
["minecraft:chiseled_deepslate"]=true,

-- Cave/underground blocks
["minecraft:cave_air"]=true,
["minecraft:void_air"]=true,
["minecraft:air"]=true,
["minecraft:moss_block"]=true,
["minecraft:moss_carpet"]=true,
["minecraft:azalea_leaves"]=true,
["minecraft:flowering_azalea_leaves"]=true,
["minecraft:rooted_dirt"]=true,
["minecraft:hanging_roots"]=true,
["minecraft:big_dripleaf"]=true,
["minecraft:small_dripleaf"]=true,
["minecraft:spore_blossom"]=true,
["minecraft:glow_lichen"]=true,

-- Nether blocks
["minecraft:netherrack"]=true,
["minecraft:nether_bricks"]=true,
["minecraft:cracked_nether_bricks"]=true,
["minecraft:chiseled_nether_bricks"]=true,
["minecraft:red_nether_bricks"]=true,
["minecraft:soul_sand"]=true,
["minecraft:soul_soil"]=true,
["minecraft:basalt"]=true,
["minecraft:polished_basalt"]=true,
["minecraft:smooth_basalt"]=true,
["minecraft:blackstone"]=true,
["minecraft:polished_blackstone"]=true,
["minecraft:polished_blackstone_bricks"]=true,
["minecraft:cracked_polished_blackstone_bricks"]=true,
["minecraft:chiseled_polished_blackstone"]=true,
["minecraft:gilded_blackstone"]=true,
["minecraft:crimson_nylium"]=true,
["minecraft:warped_nylium"]=true,
["minecraft:crimson_roots"]=true,
["minecraft:warped_roots"]=true,
["minecraft:nether_sprouts"]=true,
["minecraft:weeping_vines"]=true,
["minecraft:twisting_vines"]=true,
["minecraft:shroomlight"]=true,
["minecraft:warped_wart_block"]=true,
["minecraft:nether_wart_block"]=true,

-- End blocks
["minecraft:end_stone"]=true,
["minecraft:end_stone_bricks"]=true,
["minecraft:purpur_block"]=true,
["minecraft:purpur_pillar"]=true,
["minecraft:chorus_plant"]=true,
["minecraft:chorus_flower"]=true,

-- Plant/organic blocks
["minecraft:dead_bush"]=true,
["minecraft:fern"]=true,
["minecraft:large_fern"]=true,
["minecraft:grass"]=true,
["minecraft:tall_grass"]=true,
["minecraft:seagrass"]=true,
["minecraft:tall_seagrass"]=true,
["minecraft:kelp"]=true,
["minecraft:kelp_plant"]=true,
["minecraft:dried_kelp_block"]=true,
["minecraft:hay_block"]=true,
["minecraft:wheat_seeds"]=true,
["minecraft:beetroot_seeds"]=true,
["minecraft:melon_seeds"]=true,
["minecraft:pumpkin_seeds"]=true,
["minecraft:sweet_berries"]=true,
["minecraft:glow_berries"]=true,
["minecraft:cocoa"]=true,
["minecraft:sugar_cane"]=true,
["minecraft:bamboo"]=true,
["minecraft:cactus"]=true,
["minecraft:vine"]=true,
["minecraft:lily_pad"]=true,
["minecraft:sea_pickle"]=true,

-- Mushroom blocks
["minecraft:brown_mushroom"]=true,
["minecraft:red_mushroom"]=true,
["minecraft:brown_mushroom_block"]=true,
["minecraft:red_mushroom_block"]=true,
["minecraft:mushroom_stem"]=true,
["minecraft:crimson_fungus"]=true,
["minecraft:warped_fungus"]=true,
["minecraft:crimson_stem"]=true,
["minecraft:warped_stem"]=true,
["minecraft:stripped_crimson_stem"]=true,
["minecraft:stripped_warped_stem"]=true,

-- Ice blocks
["minecraft:ice"]=true,
["minecraft:packed_ice"]=true,
["minecraft:blue_ice"]=true,
["minecraft:frosted_ice"]=true,
["minecraft:snow"]=true,
["minecraft:snow_block"]=true,
["minecraft:powder_snow"]=true,

-- Web and slime
["minecraft:cobweb"]=true,
["minecraft:slime_block"]=true,
["minecraft:honey_block"]=true,

-- Coral (if mining underwater)
["minecraft:tube_coral"]=true,
["minecraft:brain_coral"]=true,
["minecraft:bubble_coral"]=true,
["minecraft:fire_coral"]=true,
["minecraft:horn_coral"]=true,
["minecraft:dead_tube_coral"]=true,
["minecraft:dead_brain_coral"]=true,
["minecraft:dead_bubble_coral"]=true,
["minecraft:dead_fire_coral"]=true,
["minecraft:dead_horn_coral"]=true,
["minecraft:tube_coral_block"]=true,
["minecraft:brain_coral_block"]=true,
["minecraft:bubble_coral_block"]=true,
["minecraft:fire_coral_block"]=true,
["minecraft:horn_coral_block"]=true,
["minecraft:dead_tube_coral_block"]=true,
["minecraft:dead_brain_coral_block"]=true,
["minecraft:dead_bubble_coral_block"]=true,
["minecraft:dead_fire_coral_block"]=true,
["minecraft:dead_horn_coral_block"]=true,
["minecraft:tube_coral_fan"]=true,
["minecraft:brain_coral_fan"]=true,
["minecraft:bubble_coral_fan"]=true,
["minecraft:fire_coral_fan"]=true,
["minecraft:horn_coral_fan"]=true,
["minecraft:dead_tube_coral_fan"]=true,
["minecraft:dead_brain_coral_fan"]=true,
["minecraft:dead_bubble_coral_fan"]=true,
["minecraft:dead_fire_coral_fan"]=true,
["minecraft:dead_horn_coral_fan"]=true,

-- Fluids
["minecraft:water"]=true,
["minecraft:lava"]=true,
}

local inventoryBlocks = {
["minecraft:chest"]=true,
["minecraft:trapped_chest"]=true,
["minecraft:ender_chest"]=true,
["minecraft:shulker_box"]=true,
["minecraft:white_shulker_box"]=true,
["minecraft:orange_shulker_box"]=true,
["minecraft:magenta_shulker_box"]=true,
["minecraft:light_blue_shulker_box"]=true,
["minecraft:yellow_shulker_box"]=true,
["minecraft:lime_shulker_box"]=true,
["minecraft:pink_shulker_box"]=true,
["minecraft:gray_shulker_box"]=true,
["minecraft:light_gray_shulker_box"]=true,
["minecraft:cyan_shulker_box"]=true,
["minecraft:purple_shulker_box"]=true,
["minecraft:blue_shulker_box"]=true,
["minecraft:brown_shulker_box"]=true,
["minecraft:green_shulker_box"]=true,
["minecraft:red_shulker_box"]=true,
["minecraft:black_shulker_box"]=true,
["minecraft:hopper"]=true,
["minecraft:barrel"]=true,
}

local disallowedBlocks = {
["minecraft:chest"] = true,
["minecraft:hopper"]=true,
["computercraft:turtle_advanced"] = true,
["computercraft:computer_advanced"] = true,
["computercraft:wireless_modem_advanced"] = true,
["computercraft:monitor_advanced"] = true,
}

local oreBlocks = {
-- Vanilla ores (overworld)
["minecraft:coal_ore"]=true,
["minecraft:iron_ore"]=true,
["minecraft:copper_ore"]=true,
["minecraft:gold_ore"]=true,
["minecraft:redstone_ore"]=true,
["minecraft:lapis_ore"]=true,
["minecraft:diamond_ore"]=true,
["minecraft:emerald_ore"]=true,

-- Deepslate variants
["minecraft:deepslate_coal_ore"]=true,
["minecraft:deepslate_iron_ore"]=true,
["minecraft:deepslate_copper_ore"]=true,
["minecraft:deepslate_gold_ore"]=true,
["minecraft:deepslate_redstone_ore"]=true,
["minecraft:deepslate_lapis_ore"]=true,
["minecraft:deepslate_diamond_ore"]=true,
["minecraft:deepslate_emerald_ore"]=true,

-- Nether ores
["minecraft:nether_gold_ore"]=true,
["minecraft:nether_quartz_ore"]=true,
["minecraft:ancient_debris"]=true,

-- Raw ore blocks (storage blocks of raw materials)
["minecraft:raw_iron_block"]=true,
["minecraft:raw_copper_block"]=true,
["minecraft:raw_gold_block"]=true,

-- Mineral blocks (for strip mining storage areas)
["minecraft:coal_block"]=true,
["minecraft:iron_block"]=true,
["minecraft:copper_block"]=true,
["minecraft:gold_block"]=true,
["minecraft:diamond_block"]=true,
["minecraft:emerald_block"]=true,
["minecraft:lapis_block"]=true,
["minecraft:redstone_block"]=true,
["minecraft:netherite_block"]=true,

-- Copper variants (oxidation states)
["minecraft:exposed_copper"]=true,
["minecraft:weathered_copper"]=true,
["minecraft:oxidized_copper"]=true,
["minecraft:cut_copper"]=true,
["minecraft:exposed_cut_copper"]=true,
["minecraft:weathered_cut_copper"]=true,
["minecraft:oxidized_cut_copper"]=true,
["minecraft:waxed_copper_block"]=true,
["minecraft:waxed_exposed_copper"]=true,
["minecraft:waxed_weathered_copper"]=true,
["minecraft:waxed_oxidized_copper"]=true,
["minecraft:waxed_cut_copper"]=true,
["minecraft:waxed_exposed_cut_copper"]=true,
["minecraft:waxed_weathered_cut_copper"]=true,
["minecraft:waxed_oxidized_cut_copper"]=true,

-- Amethyst (geodes)
["minecraft:amethyst_block"]=true,
["minecraft:budding_amethyst"]=true,
["minecraft:amethyst_cluster"]=true,
["minecraft:large_amethyst_bud"]=true,
["minecraft:medium_amethyst_bud"]=true,
["minecraft:small_amethyst_bud"]=true,

-- Other valuable blocks
["minecraft:bone_block"]=true,
["minecraft:quartz_block"]=true,
["minecraft:smooth_quartz"]=true,
["minecraft:chiseled_quartz_block"]=true,
["minecraft:quartz_pillar"]=true,
["minecraft:prismarine"]=true,
["minecraft:prismarine_bricks"]=true,
["minecraft:dark_prismarine"]=true,
["minecraft:sea_lantern"]=true,

-- Modded ore support (common mod ores)
-- Thermal Foundation
["thermal:tin_ore"]=true,
["thermal:lead_ore"]=true,
["thermal:silver_ore"]=true,
["thermal:nickel_ore"]=true,
["thermal:deepslate_tin_ore"]=true,
["thermal:deepslate_lead_ore"]=true,
["thermal:deepslate_silver_ore"]=true,
["thermal:deepslate_nickel_ore"]=true,

-- Mekanism
["mekanism:tin_ore"]=true,
["mekanism:osmium_ore"]=true,
["mekanism:uranium_ore"]=true,
["mekanism:deepslate_tin_ore"]=true,
["mekanism:deepslate_osmium_ore"]=true,
["mekanism:deepslate_uranium_ore"]=true,

-- Applied Energistics
["appliedenergistics2:quartz_ore"]=true,
["appliedenergistics2:deepslate_quartz_ore"]=true,
["appliedenergistics2:charged_quartz_ore"]=true,

-- Immersive Engineering
["immersiveengineering:ore_aluminum"]=true,
["immersiveengineering:ore_lead"]=true,
["immersiveengineering:ore_nickel"]=true,
["immersiveengineering:ore_silver"]=true,
["immersiveengineering:ore_uranium"]=true,
["immersiveengineering:deepslate_ore_aluminum"]=true,
["immersiveengineering:deepslate_ore_lead"]=true,
["immersiveengineering:deepslate_ore_nickel"]=true,
["immersiveengineering:deepslate_ore_silver"]=true,
["immersiveengineering:deepslate_ore_uranium"]=true,

-- Create
["create:zinc_ore"]=true,
["create:deepslate_zinc_ore"]=true,

-- Industrial Foregoing / Titanium
["titanium:ruby_ore"]=true,
["titanium:sapphire_ore"]=true,

-- Common patterns that will be caught by the _ore suffix check in checkOreBlock
-- This covers most modded ores automatically
}

local vector = vector
local debuginfo = debug.getinfo
local tablepack = table.pack
local tableunpack = table.unpack
local osEpoch = os.epoch

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
	o.nodeRefuel = global.nodeRefuel
	o.pos = vector.new(0,70,0)
	o.gettingFuel = false
	o.initializing = true
	o.lookingAt = vector.new(0,0,0)
	o.map = ChunkyMap:new(true)
	o.taskList = List:new()
	o.vectors = vectors
	o.checkPointer = CheckPointer:new()
	o.statusCount = 0
	
	o:initialize() -- initialize after starting parallel tasks in startup.lua
	return o
end


function Miner:initialize()
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	
	-- preset chunk request but try not to during initialization
	self.map.requestChunk = function(chunkId) return self:requestChunk(chunkId) end
	
	self:refuel(true)
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
		-- TODO: load station from settings
		self:setHome(self.pos.x, self.pos.y, self.pos.z)
	end
	self:setStartupPos(self.pos)

	
	local existsCheckpoint = self.checkPointer:existsCheckpoint()
	if not existsCheckpoint then
		self:returnHome()
	end

	self.initializing = nil
	self.taskList:remove(currentTask)

	if existsCheckpoint then
		if self.checkPointer:load(self) then
			if not self.checkPointer:executeTasks(self) then
				self:error("CHECKPOINT NOT EXECUTED")
			end
		end
	end
	
end

function Miner:initPosition()
	local x,y,z = gps.locate()
	if x and y and z then
		self.pos = vector.new(x,y,z)
	else
		--gps not working
		self:error("GPS UNAVAILABLE",true)
	end
	print("position:",self.pos.x,self.pos.y,self.pos.z)
end

function Miner:initOrientation()
	local function tryOrientationAtLevel()
		local newPos
		local turns = 0
		-- First try: normal movement
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
			-- Second try: breaking blocks
			print("breaking blocks to determine orientation")
			for i=1,4 do
				local hasBlock, data = turtle.inspect()
				if data and not Miner.checkDisallowed(data.name) then
					turtle.dig()
					sleep(default.waitTimeFallingBlock)
				end
				if not turtle.forward() then
					self:turnLeft()
					turns = turns + 1
				else
					newPos = vector.new(gps.locate())
					break
				end
			end
		end
		
		return newPos, turns
	end
	
	local originalPos = vector.new(self.pos.x, self.pos.y, self.pos.z)
	local newPos, turns = tryOrientationAtLevel()
	
	if not newPos then
		print("Cannot determine orientation at current level, trying different levels")
		local levelsTried = {self.pos.y}
		local maxLevelAttempts = 10
		local levelAttempts = 0
		
		-- Try going up first (more likely to have open space)
		while not newPos and levelAttempts < maxLevelAttempts do
			levelAttempts = levelAttempts + 1
			local targetLevel = self.pos.y + levelAttempts
			
			-- Skip if we've already tried this level
			local alreadyTried = false
			for _, level in ipairs(levelsTried) do
				if level == targetLevel then
					alreadyTried = true
					break
				end
			end
			
			if not alreadyTried then
				print("Trying orientation detection at level", targetLevel)
				table.insert(levelsTried, targetLevel)
				
				-- Try to move up
				local hasBlock, data = turtle.inspectUp()
				if data and not Miner.checkDisallowed(data.name) then
					turtle.digUp()
					sleep(default.waitTimeFallingBlock)
				end
				
				if turtle.up() then
					self.pos.y = self.pos.y + 1
					newPos, turns = tryOrientationAtLevel()
					
					if newPos then
						print("Successfully determined orientation at level", self.pos.y)
						break
					end
				else
					print("Cannot move up to level", targetLevel)
				end
			end
			
			-- Also try going down if going up didn't work
			if not newPos and levelAttempts <= maxLevelAttempts / 2 then
				targetLevel = originalPos.y - levelAttempts
				alreadyTried = false
				for _, level in ipairs(levelsTried) do
					if level == targetLevel then
						alreadyTried = true
						break
					end
				end
				
				if not alreadyTried and targetLevel > 0 then -- Don't go below bedrock
					print("Trying orientation detection at level", targetLevel)
					table.insert(levelsTried, targetLevel)
					
					-- Return to original level first, then try going down
					while self.pos.y > originalPos.y do
						if turtle.down() then
							self.pos.y = self.pos.y - 1
						else
							break
						end
					end
					
					-- Try to move down
					local hasBlock, data = turtle.inspectDown()
					if data and not Miner.checkDisallowed(data.name) then
						turtle.digDown()
						sleep(default.waitTimeFallingBlock)
					end
					
					if turtle.down() then
						self.pos.y = self.pos.y - 1
						newPos, turns = tryOrientationAtLevel()
						
						if newPos then
							print("Successfully determined orientation at level", self.pos.y)
							break
						end
					else
						print("Cannot move down to level", targetLevel)
					end
				end
			end
		end
		
		-- If we found orientation at a different level, return to original level
		if newPos and self.pos.y ~= originalPos.y then
			print("Returning to original level", originalPos.y, "from", self.pos.y)
			while self.pos.y > originalPos.y do
				if turtle.down() then
					self.pos.y = self.pos.y - 1
				else
					print("Warning: Cannot return to original level")
					break
				end
			end
			while self.pos.y < originalPos.y do
				if turtle.up() then
					self.pos.y = self.pos.y + 1
				else
					print("Warning: Cannot return to original level")
					break
				end
			end
		end
	end
	
	if not newPos then
		print("ORIENTATION NOT DETERMINABLE after trying multiple levels")
		print("Broadcasting position for manual retrieval...")
		self:broadcastStrandedPosition()
		self.orientation = 0
		self:error("TURTLE_STRANDED - Manual retrieval required", true)
	else
		-- Calculate orientation from movement
		local diff = newPos - self.pos
		self.pos = newPos
		if diff.x < 0 then self.orientation = 1
		elseif diff.x > 0 then self.orientation = 3
		elseif diff.z < 0 then self.orientation = 2
		else self.orientation = 0
		end
		self:updateLookingAt()

		-- Go back to original position
		if turtle.back() then 
			self.pos = self.pos - self.vectors[self.orientation]
		end
		
		self:turnTo((self.orientation+turns)%4)
		self.homeOrientation = self.orientation
	end
	print("orientation:", self.orientation)
end

function Miner:broadcastStrandedPosition()
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	
	local turtleInfo = {
		id = os.getComputerID(),
		label = os.getComputerLabel() or ("Turtle_" .. os.getComputerID()),
		pos = {x = self.pos.x, y = self.pos.y, z = self.pos.z},
		fuel = turtle.getFuelLevel(),
		reason = "ORIENTATION_NOT_DETERMINABLE",
		timestamp = os.epoch("utc")
	}
	
	print("Turtle stranded at:", self.pos.x, self.pos.y, self.pos.z)
	print("ID:", turtleInfo.id, "Label:", turtleInfo.label)
	print("Fuel level:", turtleInfo.fuel)
	
	-- Try to broadcast to host if available
	if self.node and self.node.host then
		local success = self.node:send(self.node.host, {"TURTLE_STRANDED", turtleInfo}, false, false, 5)
		if success then
			print("Position broadcasted to host successfully")
		else
			print("Failed to contact host - broadcasting on general channel")
		end
	else
		print("No host connection available")
	end
	
	-- Also broadcast on general channels for any listening systems
	if global.node then
		global.node:send("broadcast", {"TURTLE_STRANDED", turtleInfo}, false, false)
		print("Emergency broadcast sent on general channel")
	end
	
	-- Save stranded info to file as backup
	local fileName = "runtime/stranded_" .. os.getComputerID() .. ".txt"
	local f = fs.open(fileName, "w")
	if f then
		f.write(textutils.serialize(turtleInfo))
		f.close()
		print("Stranded info saved to:", fileName)
	end
	
	self.taskList:remove(currentTask)
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
	local start = osEpoch("local")
	if self.node and self.node.host then
		local answer, forMsg = self.node:send(self.node.host,
			{"REQUEST_CHUNK", chunkId},true,true,1,"chunk")
		if answer then
			if answer.data[1] == "CHUNK" then
				print(osEpoch("local")-start,"RECEIVED CHUNK", chunkId)
				return answer.data[2]
			else
				print("received other", answer.data[1])
			end
		end
		--print("no answer")
	end
	print(osEpoch("local")-start, "CHUNK REQUEST FAILED", chunkId)
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
		
	else
		-- TODO: try remember station, lmao
		-- settings set get etc.?
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
	local result = false
	self.returningHome = true
	if self.home then
		print("RETURNING HOME", self.home.x, self.home.y, self.home.z)
		result = self:navigateToPos(self.home.x, self.home.y, self.home.z)
		self:turnTo(self.homeOrientation)
		if result then
			self:transferItems()
		end
	end
	self.returningHome = false
	self.taskList:remove(currentTask)
	return result
end

function Miner:error(reason,real)
	-- TODO: create image of current Miner to load later on
	-- self:save()

	if self.taskList.count > 0 then func = "ERR:"..self.taskList.first[1]
	else func = "ERR:unknown" end
	self.taskList:clear()
	-- OPTI: optional: delete Checkpoint / save after clearing taskList
	if real ~= true then
		self.checkPointer:save(self)
	end
	error({real=real,text=reason,func=func}) -- watch out that this is not caught by some other function
end
function Miner:addCheckTask(task, isCheckpointable, ...)
	-- called by most functions to interrupt execution
	-- if task[1] is nil, could be due to return self:function()

	if self.stop then
		self.stop = false
		self:error("stopped",false)
	end

	if isCheckpointable and self.taskList.first
		and ( task[1] == "?" or self.taskList.first[1] == task[1] ) then
		-- task already currently in list (probably loaded by checkpointer)
		return self.taskList.first
	else
		return self.taskList:addFirst(task)
	end
end

function Miner:checkStatus()
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	-- called by self:forward()
	self:refuel()
	self:cleanInventory()
	self.statusCount = self.statusCount + 1
	if self.statusCount > 40 then
		self:checkMinedTurtle()
		self.statusCount = 0
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


function Miner:findInventoryItem(name)
	-- check for item in inventory
	local found = nil
	for slot = 1,default.inventorySize do
		local data = turtle.getItemDetail(slot)
		if data and data.name == name then
			found = slot
			break
		end
	end
	return found
end

function Miner:checkMinedTurtle()
	-- in very rare cases, a turtle might have ran in front of another turtle during stripmining without safety checks
	-- check inventory for turtles and place them back down 
	local slot = self:findInventoryItem(default.turtleName)
	if slot then
		print("OH NO, I MINED A TURTLE :(")
		self:select(slot)
		-- try and place it
		local direction
		if turtle.placeUp() then direction = "top"
		elseif turtle.placeDown() then direction = "bottom"
		elseif turtle.place() then direction = "front"
		else
			print("could not place turtle")
			return false
		end
		
		if direction then 
			sleep(1) 
			-- give it half the fuel
			for slot = 1, default.inventorySize do
				local data = turtle.getItemDetail(slot)
				if data and fuelItems[data.name] then
					-- could be unreliable if turtle has more than one stack but doesnt really matter
					self:select(slot)
					local amount = data.count/2 
					if direction == "top" then turtle.dropUp(amount)
					elseif direction == "bottom" then turtle.dropDown(amount)
					elseif direction == "front" then turtle.drop(amount) end
					print("giving turtle", amount, "fuel")
					break 
				end
			end
			sleep(1) 
			print("placed", direction, "now turning on")
			local tut = peripheral.wrap(direction)
			if tut then 
				print("turning on turtle", tut.getID())
				tut.turnOn()
				sleep(5) -- give it some time to fuck off before continuing with whatever
				return true
			else 
				self:error("FAILED TO RESTART TURTLE",true)
				return false
			end
		end
	end
	return true
end


function Miner:cleanInventory()
	-- check for full inventory and take action
	-- if turtles are still being mined and not placed back down, increase to at least 1 open slot at all times
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
	if self:returnHome() then
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
	else
		self.cleaningInventory = false
		self:error("FAILED_TO_RETURN_HOME",true)
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
		local block = self:inspect(true)
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
				local isFuelItem = fuelItems[data.name] ~= nil
				if not hasFuel and isFuelItem then
					hasFuel = true --keep the first fuel stack found
					print("keeping fuel:", data.name, "x" .. data.count, "in slot", slot)
				else
					--transfer all other items (including additional fuel stacks)
					self:select(slot)
					local ok = turtle.drop(data.count)
					if ok == true then
						print("transferred:", data.name, "x" .. data.count)
					else
						print("chest full, skipping:", data.name, "x" .. data.count)
						-- Continue trying other items in case chest has space for different items
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

function Miner:refuel(simple)
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
			-- and turtle.getFuelLevel() > 2 * self:getCostHome() then
			refueled = true
		elseif turtle.getFuelLevel() == 0 then
			-- ran out of fuel
			self:error("NEED FUEL, STUCK",true)
		else
			if not simple then -- for initializing
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
		end
		print("fuel level:", turtle.getFuelLevel())
	else
		refueled = true
	end
	self.taskList:remove(currentTask)
	return refueled
end







function Miner:clearStaleLocks()
	-- clear old locks on stations to avoid waiting for noone
    local currentTime = osEpoch("utc")
    for id, station in pairs(config.stations.refuel) do
        if station.occupied and (currentTime - (station.lastClaimed or 0)) > 10000 then -- 10 seconds
            -- print("Clearing stale lock on station:", id)
            station.occupied = false
        end
    end
end

function Miner:requestRefuelStation()

	self.refuelClaim = {
		approvedByOwner = false,
		ok = false,
		occupiedStation = nil,
		waiting = false,
		lastClaimed = 0,
		priority = 0,
	}
	local refuelClaim = self.refuelClaim

	-- clear occupied stations
	for id,station in pairs(config.stations.refuel) do
		station.occupied = false
	end

	-- get all the occupied stations
	bluenet.openChannel(bluenet.modem, bluenet.default.channels.refuel)
	self.nodeRefuel:send(bluenet.default.channels.refuel, {"REQUEST_STATION"}, false, false) 
	sleep(1) -- handle responses in onReceive and onRequestAnswer in miner/receive.lua
	-- config should now be updated with occupied stations

	refuelClaim.waiting = true
	-- try to claim a station or wait for one
	local startTime = osEpoch("utc")
	repeat
		local ok = self:tryClaimStation()
		if not ok then 
			sleep(0.5 + math.random()) -- random offset so not every turtle requests at the same time
			self:clearStaleLocks()
		end
	until refuelClaim.ok or ( osEpoch("utc") - startTime )  > 1200000 -- 1200 seconds (20 minutes) for high contention scenarios

	refuelClaim.waiting = false

	if refuelClaim.ok and refuelClaim.occupiedStation then
		print("station claim successful:", refuelClaim.occupiedStation)
	else 
		print("station claim timeout - no stations available after waiting")
		refuelClaim.occupiedStation = nil
	end

	return refuelClaim.occupiedStation
end


function Miner:tryClaimStation()
	local refuelClaim = self.refuelClaim
	local result = false
	for id,station in pairs(config.stations.refuel) do
		if not station.occupied or station.occupied == false then
			refuelClaim.occupiedStation = id -- reserve it to deny other claim requests
			refuelClaim.lastClaimed = osEpoch("utc")
			print("attempting to claim station", id)
			refuelClaim.ok = true
			self.nodeRefuel:send(bluenet.default.channels.refuel, {"CLAIM_STATION", id}, false, false)
			sleep(1) -- wait for denying answers

			if refuelClaim.ok or refuelClaim.approvedByOwner then 
				print("claimed station", id, "owner approved:", refuelClaim.approvedByOwner)
				refuelClaim.ok = true
				result = true
				break
			else
				refuelClaim.occupiedStation = nil
				refuelClaim.lastClaimed = 0
				print("claim station failed - denied by owner", id)
			end
		end
	end
	return result
end

function Miner:releaseStation()
	if self.refuelClaim and self.refuelClaim.occupiedStation then
		--print("releasing station", self.refuelClaim, self.refuelClaim.occupiedStation)
		self.refuelClaim.isReleasing = true
		self.nodeRefuel:send(bluenet.default.channels.refuel, 
				{"RELEASE_STATION", self.refuelClaim.occupiedStation}, false, false)
		-- wait a bit (~1s) to solve claim conflicts using owner acks
		self:back()
		self:back()
		self:back()
		-- self:back()
		-- self:back()
		-- self:back()
		--sleep(1)
		
		self.refuelClaim = {occupiedStation = nil}
		--print(osEpoch("utc")/1000, "released station")
	end
	-- close channel to stop listening
	bluenet.closeChannel(bluenet.modem, bluenet.default.channels.refuel)
	
end

function Miner:getRefuelStation(random)
	local id 
	-- print("not random", not random, self.nodeRefuel)
	if not random and self.nodeRefuel then
		id = self:requestRefuelStation()
	end
	if id then 
		return id
	else
		-- count available stations
		local stationCount = 0
		for _,v in pairs(config.stations.refuel) do stationCount = stationCount + 1 end
		
		if stationCount == 1 then
			-- single station setup - return the only station and wait properly
			for stationId, station in pairs(config.stations.refuel) do
				print("using single station", stationId, "will wait for availability")
				return stationId
			end
		else
			-- multiple stations - use random fallback as before
			local index = math.random(1, stationCount)
			local ct = 0
			for stationId, station in pairs(config.stations.refuel) do
				ct = ct + 1
				if ct == index then 
					print("using random station", stationId)
					return stationId
				end
			end
		end
	end
end


function Miner:getFuel()

	-- default method:
	-- 1. move near to refuel stations based on config
	-- 2. ask turtles if stations are occupied 
	-- 3. claim station
	--    if occupied, wait for station
	-- 3. move to station and refuel
	-- 4. report station as free and leave

	-- no station available:
	-- wait in queue for station, but this would also require messaging etc...
	-- not nice
	-- could use home-stations as queue that is always available

	-- no host available:
	-- use config or ask other turtles if they are refueling

	-- TODO: advanced method:
	-- add support turtles that represent a temporary refuel station
	-- they act like a passive provider chest
	-- this way turtles dont have to return all the way home for big tasks
	-- different types of turtles
	-- general turtle with all the default methods like navigation etc.
	-- types: support(refuel, collect items), miner, "forester"

	-- TODO: change from config to internal variable?
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	
	self.gettingFuel = true
	local result = false
	
	local ok, err = pcall( function() 

		-- move near the refuel stations or create automatic queue

		local isInQueue = false
		
		if config.stations.refuelQueue and config.stations.refuelQueue.origin then 
			-- explicit queue configuration exists
			local tries = 0
			local origin = config.stations.refuelQueue.origin
			local maxDistance = config.stations.refuelQueue.maxDistance or 8
			repeat 
				tries = tries + 1
				local randomPosition = vector.new(
					math.random(origin.x-maxDistance, origin.x+maxDistance),
					origin.y,
					math.random(origin.z-maxDistance, origin.z+maxDistance)
				)
				print("moving to explicit queue", randomPosition)
				isInQueue = self:navigateToPos(randomPosition.x, randomPosition.y, randomPosition.z)
				if not isInQueue and tries > 3 then
					print("cant reach refuel queue")
					isInQueue = true -- set to true anyways, should be nearby the queue
					break
				end
			until isInQueue
		else
			-- no explicit queue - create automatic queue around refuel stations
			local stationCount = 0
			local avgX, avgY, avgZ = 0, 0, 0
			for stationId, station in pairs(config.stations.refuel) do
				stationCount = stationCount + 1
				avgX = avgX + station.pos.x
				avgY = avgY + station.pos.y
				avgZ = avgZ + station.pos.z
			end
			
			if stationCount > 0 then
				-- calculate center point of all refuel stations
				avgX = math.floor(avgX / stationCount)
				avgY = math.floor(avgY / stationCount)
				avgZ = math.floor(avgZ / stationCount)
				
				local maxDistance = 12 -- larger area for automatic queue
				local tries = 0
				repeat 
					tries = tries + 1
					local randomPosition = vector.new(
						math.random(avgX-maxDistance, avgX+maxDistance),
						avgY,
						math.random(avgZ-maxDistance, avgZ+maxDistance)
					)
					print("moving to auto queue near stations", randomPosition)
					isInQueue = self:navigateToPos(randomPosition.x, randomPosition.y, randomPosition.z)
					if not isInQueue and tries > 3 then
						print("cant reach auto queue area")
						isInQueue = true -- proceed anyway
						break
					end
				until isInQueue
			else
				print("no refuel stations configured")
				isInQueue = true -- skip queue logic if no stations
			end
		end

		local useRandomStation = not isInQueue
		-- print("using random station", useRandomStation)
		local id = self:getRefuelStation(useRandomStation)
		local station = config.stations.refuel[id]

		-- actually refuel
		if not self:navigateToPos(station.pos.x, station.pos.y, station.pos.z) then
			--print("unable to reach station")
			return false
		end

		if station.orientation then 
			self:turnTo(station.orientation) 
		end
		
		local hasInventory = false
		
		for k=1,4 do
		--check for chest
			local block = self:inspect(true) -- true for wrong map entries or new stations
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
	
	end )

	-- !! cancellation while getting fuel can result in no more refueling
	if not ok then
		self.gettingFuel = false
		bluenet.closeChannel(bluenet.modem, bluenet.default.channels.refuel)
		error(err,0) -- pass error
	end
	
	if not result then
		print("unable to refuel", result)
		result = false
	end

	-- done refueling
	self:releaseStation()

	if self:getEmptySlots() < 10 then -- 8
		-- already at home, also offload items
		self:offloadItemsAtHome() 
	end

	self:returnHome()

	self.gettingFuel = false
	
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
	-- NO, navigateToPos calls digToPos which could lead to recursive calls
	
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
	
	-- TODO: give turtle a bucket and gobble up lava to refuel

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
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name}, true)
	print("stripmining", "rows", rows, "levels", levels)

	local directionFactor = 1 -- -1 for right hand mining

	local taskState = currentTask.taskState
	if taskState then
		rowLength, rows, levels, rowFactor, levelFactor = tableunpack(taskState.args,1,taskState.args.n)
	else
		taskState = {
			stage = 1,
			ignorePosition = false,
			vars = {
				currentRow = 1,
				currentLevel = 1,
				rowOrientation = self.orientation,
				tunnelDirection = -1 * directionFactor,
				startPos = vector.new(self.pos.x, self.pos.y, self.pos.z),
				startOrientation = self.orientation,
			},
			args = tablepack(rowLength, rows, levels, rowFactor, levelFactor),
		}
	end
	local vars = taskState.vars
	currentTask.taskState = taskState
	self.checkPointer:save(self)
	-- prepare values

	if not levels then levels = 1 end
	local positiveLevel = true
	if levels < 0 then 
		positiveLevel = false 
		levels = levels * -1
	end


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



	if taskState.stage == 1 then
		-- try, catch
		local ok,err = pcall(function()

			if not rowFactor then rowFactor = 3 end
			if not levelFactor then levelFactor = 2 end
			
			for currentLevel = vars.currentLevel, levels do
				vars.currentLevel = currentLevel
				self.checkPointer:save(self)
				if currentLevel%2 == 0 and rows%2 == 0 then 
					vars.tunnelDirection = 1 * directionFactor
				else vars.tunnelDirection = -1 * directionFactor end
				
				for currentRow = vars.currentRow, rows do
					vars.currentRow = currentRow
					self.checkPointer:save(self) -- perhaps at start of for-loop
					self:tunnelStraight(rowLength)
					if currentRow < rows then
						self:turnTo(vars.rowOrientation + vars.tunnelDirection)
						self:tunnelStraight(rowFactor)
						if currentRow%2 == 1 then
							self:turnTo(vars.rowOrientation-2)
						else
							self:turnTo(vars.rowOrientation)
						end
					end
				end
				vars.currentRow = 1 -- reset row to start at 1 again, not saved state
				if currentLevel < levels then
					-- move up
					if positiveLevel then
						self:tunnelUp(levelFactor)
					else
						self:tunnelDown(levelFactor)
					end
					if self.orientation == vars.startOrientation or currentLevel%2 == 0 then
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
				vars.rowOrientation = self.orientation
			end
			
		end)
	
		if not ok then 
			if err == "TUNNEL FAIL" then
				print(ok, err)
			else
				-- pass error
				error(err)
			end
		end
		taskState.stage = 2
		taskState.ignorePosition = true
		self.checkPointer:save(self)
	end

--SINGLE LEVEL PART OF MULTILEVEL
--------------------
--	 * 	   *     *
-- * M * * M * * M *
--	 *     *     *
--------------------

	if taskState.stage == 2 then
		-- only needed for testing i guess
		self:navigateToPos(vars.startPos.x, vars.startPos.y, vars.startPos.z)
		self:turnTo(vars.startOrientation)
	end

	self.taskList:remove(currentTask)
	self.checkPointer:save(self)
end

function Miner:mineArea(start, finish) 
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name}, true)
	-- TODO: mine area within start and finish pos
	-- 8 corners = 8 possible starting locations, pick nearest
	-- determine how many rows and levels to mine and in which direction
	
	local taskState = currentTask.taskState
	if taskState then
		start, finish = tableunpack(taskState.args,1,taskState.args.n)
	else
		taskState = {
			stage = 1, -- Stage 1: Execute stripMine, Stage 2: Execute post-stripMine steps
			ignorePosition = true,
			vars = {
			},
			args = tablepack(start, finish),
		}
	end
	local vars = taskState.vars
	currentTask.taskState = taskState
	self.checkPointer:save(self)

	if taskState.stage == 1 then

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
			
			taskState.stage = 2
			taskState.ignorePosition = true
			self.checkPointer:save(self)

			self:stripMine(rowLength, rows, levels)
			
		end
	end

	-- Stage 2: Execute post-stripMine steps
	if taskState.stage == 2 then
		self:returnHome()
		self:condenseInventory()
		self:dumpBadItems()
		self:transferItems()
		--self:getFuel()
		--self.map:save()
	end 

	self.taskList:remove(currentTask)
	self.checkPointer:save(self)
end


function Miner:tunnel(length, direction)
	-- throws error
	local currentTask = self:addCheckTask({debug.getinfo(1, "n").name})
	
	local result = true
	local skipSteps = 0
	
	-- determine direction to mine
	local directionVector, digFunc

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
					local newPos = self.pos + directionVector * 2
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
	
	if not result then error("TUNNEL FAIL", 0) end
	return result
	
end

function Miner:tunnelStraight(length)
	local result = self:tunnel(length,"straight")
	return result
end

function Miner:tunnelUp(height)
	local result = self:tunnel(height,"up")
	return result
end

function Miner:tunnelDown(height)
	local result = self:tunnel(height,"down")
	return result
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
										result = false -- return false otherwise will continue with mining at home
										self:digToPos(self.home.x, self.home.y, self.home.z, true)
										
									end
									
								else
									print("GOAL POSSIBLE", goal, #path)
									result = self:followPath(path)
								end
							end
						end
					end
				else
					-- change, dont dig home, dig to target
					if not self:digToPos(goal.x, goal.y, goal.z, true) then
						--path was not safe
						print("NOT SAFE TO DIG TO POS")
						result = false
						countParts = maxParts
						sleep(0.5) -- give other turtles a chance to move out the way
					else result = true end
				end
			until result == true or countParts >= maxParts
		until result == true or ct >= maxTries
	end
	
	if self.pos ~= goal then result = false end
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

	for i,step in ipairs(path) do
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

			-- inspecting slows down movement, minimize it
			if i > 1 then
				if upDown ~= 1 then self:inspectUp() end
				if upDown ~= -1 then self:inspectDown() end
				if not newOr or newOr ~= self.orientation then self:inspect() end
			end

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
		end 
	end

	if result and #path > 0 then
		self:inspect()
		self:inspectUp()
		self:inspectDown()
	end

	--if not result and path[#path].pos == step.pos then
	--	self:error("GOAL IS BLOCKED")
	-- leads to infinite loop
	--end
	self.taskList:remove(currentTask)
	return result
	
end
