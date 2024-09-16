
node = global.node
nodeStatus = global.nodeStatus
nodeUpdate = global.nodeUpdate

nodeStatus.onReceive = function(msg)
	if msg.data[1] == "STATE" then
		table.insert(global.updates, msg.data[2])
	end
end

function checkOnline(id)
	local turt = global.turtles[id]
	local online = false
	if turt then
		local timeDiff = os.epoch("ingame") - turt.state.time
		if timeDiff > 144000 then
			online = false
		else
			online = true
		end
	end
	return online
end

function getStation(id)
	local result
	for _,station in ipairs(config.stations.turtles) do
		if station.id == id then
			result = station
			station.occupied = true
			break
		else
			-- reset offline station allocations
			if station.id and not checkOnline(station.id) then
				station.occupied = false
				station.id = nil
			end
		end
	end
	if not result then
		for _,station in ipairs(config.stations.turtles) do
			if station.occupied == false then
				result = station
				station.occupied = true
				station.id = id
				break
			end
		end
	end
	return result
end

node.onRequestAnswer = function(forMsg)
	if forMsg.data[1] == "REQUEST_STATION" then
		print("station request")
		local station = getStation(forMsg.sender)
		if station then
			node:answer(forMsg.sender,{"STATION",station},forMsg.id)
		else
			node:answer(forMsg.sender,{"STATIONS_FULL"},forMsg.id)
		end
	elseif forMsg.data[1] == "REQUEST_MAP" then
		print("map request")
		if global.map then
			node:answer(forMsg.sender,{"MAP", global.map:getMap()},forMsg.id)
		else
			node:answer(forMsg.sender,{"NO_MAP"},forMsg.id)
		end
	end
end


-- node.onReceive = function(msg)

-- end

function checkUpdates()
	local update = table.remove(global.updates)
	while update do
		if not global.turtles[update.id] then 
			global.turtles[update.id] = {
				state = update,
				mapLog = {},
				mapBuffer = {}
			}
		else
			--prevState = global.turtles[update.id].state
			global.turtles[update.id].state = update
		end
		
		
		local pos = update.pos
		local orientation = update.orientation
		local task = update.task
		local lastTask = update.lastTask
		
		for _,entry in ipairs(update.mapLog) do
			global.map:setData(entry.x,entry.y,entry.z,entry.data)
			global.map:logData(entry.x,entry.y,entry.z,entry.data)
			if global.printStatus then
				print("x,y,z,data", entry.x, entry.y, entry.z, entry.data)
			end
			for id,data in pairs(global.turtles) do
				-- save data for distribution to other turtles
				if not (update.id == id) then
					table.insert(global.turtles[id].mapLog, entry)
				end
			end
		end
		
		if global.printStatus then
			print("state:", update.id, pos.x, pos.y, pos.z, orientation, lastTask, task)
		end
		
		update = table.remove(global.updates)
	end
end



while global.running do
	
	node:checkEvents()
	nodeStatus:checkEvents()
	nodeUpdate:checkEvents()
	checkUpdates()
	--monitor:checkEvents()
	sleep(0.05)
end