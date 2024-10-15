
local tasks = global.tasks
local taskList = global.list
local miner = global.miner
local nodeStream = global.nodeStream

local id = os.getComputerID()
local label = os.getComputerLabel() or id

local waitTime = 3 -- to not overload the host
local mapLog = {}
local unloadedLog = {}

nodeStream.onStreamBroken = function(previous)
	--print("STREAM BROKEN")
end

-- called by onStreamMessage
nodeStream._clearLog = function()
	mapLog = {}
	unloadedLog = {}
end

nodeStream.onRequestStreamData = function(previous)
	local state = {}
	state.id = id
	state.label = label
	state.time = os.epoch("ingame") --ingame milliseconds
	
	if miner and miner.pos then -- somethings broken
		
		state.pos = miner.pos
		state.orientation = miner.orientation
		state.home = miner.home
		
		state.fuelLevel = miner:getFuelLevel()
		state.emptySlots = miner:getEmptySlots()
	
		--state.inventory = miner:
		
		local entry = table.remove(miner.map.log)
		while entry do
			table.insert(mapLog,entry)
			--print(entry[1],entry[2],entry[3])
			entry = table.remove(miner.map.log)
		end
		
		-- maybe just inform the host about loadedChunks?	
		-- send unloadedChunks
		local unloadedId = table.remove(miner.map.unloadedChunks)
		while unloadedId do
			table.insert(unloadedLog,unloadedId)
			unloadedId = table.remove(miner.map.unloadedChunks)
		end
		
		state.unloadedLog = unloadedLog
		state.mapLog = mapLog
		
		if miner.taskList:getFirst() then
			state.task = miner.taskList:getFirst()[1]
			state.lastTask = miner.taskList:getLast()[1]
			--print(state.pos, state.task, state.lastTask)
		end
	else
		state.pos = vector.new(-1,-1,-1)
		state.home = state.pos
		state.orientation = -1
		state.fuelLevel = -1
		state.emptySlots = -1
		if global.err then
			state.lastTask = global.err.func
			state.task = global.err.text
		else
			state.lastTask = "ERROR"
			state.task = ""
		end
		state.mapLog = {}
	end	
	if global.err then
		state.lastTask = global.err.func
		state.task = global.err.text
	end

	return {"STATE", state }
end

while true do
	--sendState()
	nodeStream:openStream(nodeStream.host,3)
	nodeStream:stream()
	nodeStream:checkWaitList()
	sleep(0.2) --0.2
end

print("how did we end up here...")