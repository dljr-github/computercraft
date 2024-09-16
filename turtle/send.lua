
tasks = global.tasks
taskList = global.list
miner = global.miner
nodeStatus = global.nodeStatus

local mapLog = {}

nodeStatus.onNoAnswer = function(forMsg)
	print("NO ANSWER")
end
nodeStatus.onAnswer = function(answer,forMsg)
	-- is not triggered because of inline waiting
	mapLog = {}
end

local function sendState()
	local state = {}
	state.id = os.getComputerID()
	state.label = os.getComputerLabel()
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
			print(entry.x,entry.y, entry.z, entry.data)
			entry = table.remove(miner.map.log)
		end
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
	
	if not nodeStatus.host then nodeStatus.host = 0 end
	local answer, forMsg = nodeStatus:send(nodeStatus.host, {"STATE", state}, true, true)
	if answer then
		mapLog = {}
	end
end

while true do
	sendState()
	sleep(0.2)
end