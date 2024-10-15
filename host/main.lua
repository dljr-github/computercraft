
local node = global.node
local nodeStream = global.nodeStream
local nodeUpdate = global.nodeUpdate

local map = global.map
local turtles = global.turtles
local updates = global.updates

-- nodeStatus.onRequestAnswer = function(forMsg)
	-- -- check if state is outdated before answering
	-- no, best to go by newest only, not oldest first
	-- if node:checkValid(forMsg) then
	-- node:answer(forMsg,{"RECEIVED"})
-- end

nodeStream.onStreamMessage = function(msg,previous)
	if previous.data[1] == "MAP_UPDATE" then	
		if global.printSend then
			print(os.epoch(),"MAP STREAM",msg.sender)
		end
		turtles[msg.sender].mapBuffer = {}
	end
	if msg.data[1] == "STATE" then
		table.insert(updates, msg.data[2])
	end
end

nodeStream.onStreamBroken = function(previous)
	-- idk
end



function checkOnline(id)
	local turt = turtles[id]
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
	-- check already allocated stations
	for _,station in ipairs(config.stations.turtles) do
		if station.id == id then
			result = station
			station.occupied = true
			break
		end
	end
	-- check free stations
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
	-- reset offline station allocations
	if not result then
		for _,station in ipairs(config.stations.turtles) do
			if station.id and not checkOnline(station.id) then
				station.occupied = false
				station.id = nil
			end
			
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
			node:answer(forMsg,{"STATION",station})
		else
			node:answer(forMsg,{"STATIONS_FULL"})
		end
	elseif forMsg.data[1] == "REQUEST_MAP" then
		print("map request")
		if map then
			node:answer(forMsg,{"MAP", map:getMap()})
			os.pullEvent(os.queueEvent("yield"))
		else
			node:answer(forMsg,{"NO_MAP"})
		end
	elseif forMsg.data[1] == "REQUEST_CHUNK" then
		local start = os.epoch("local")
		if map then
			--print("request_chunk",textutils.serialize(forMsg.data))
			local chunkId = forMsg.data[2]
			node:answer(forMsg,{"CHUNK", map:accessChunk(chunkId,false,true)})
			-- mark the requested chunk as loaded, regardless if received?
			if not turtles[forMsg.sender] then 
				turtles[forMsg.sender] = {
				--state = {},
				mapLog = {},
				mapBuffer = {},
				loadedChunks = {}
				}
			end
			turtles[forMsg.sender].loadedChunks[chunkId] = true
			--print(id, forMsg.sender,"loaded chunk",chunkId)
			-- !!! os.pullEvent steals from receive if called by handleMessage directly !!!
			-- os.pullEvent(os.queueEvent("yield"))
		else
			node:answer(forMsg,{"NO_CHUNK"})
		end
		print(os.epoch("local")-start, "id", forMsg.sender, "chunk request", forMsg.data[2])
	end
end


-- node.onReceive = function(msg)

-- end

function checkUpdates()
	local update = table.remove(updates)
	
	
	while update do
		local turtle = turtles[update.id]
		if not turtle then 
			turtles[update.id] = {
				state = update,
				mapLog = {},
				mapBuffer = {},
				loadedChunks = {}
			}
			turtle = turtles[update.id]
		else
			--prevState = turtles[update.id].state
			turtle.state = update
			turtle.state.online = true
			turtle.state.timeDiff = 0
		end
		
		-- keep track of unloaded chunks
		-- could result in an infinite request loop, 
		-- if the turtle just unloaded but another sent an update for this chunk
		-- -> delay?
		if update.unloadedLog then
			for i=1,#update.unloadedLog do
				turtle.loadedChunks[update.unloadedLog[i]] = nil
			end
			-- for _,unloadedId in ipairs(update.unloadedLog) do
				-- turtle.loadedChunks[unloadedId] = nil
				-- --print(update.id,"unloaded chunk",unloadedId)
			-- end
		end
		
		for i=1,#update.mapLog do 
			local entry = update.mapLog[i]
		--for _,entry in ipairs(update.mapLog) do
			--print(textutils.serialize(entry))
			map:setChunkData(entry[1],entry[2],entry[3],true)
			if global.printStatus then
				print("chunkid,pos,data", entry[1],entry[2],entry[3])
			end			
			
			-- turtle sent update for this chunk so it is probably loaded
			turtle.loadedChunks[entry[1]]=true
			
			-- save data for distribution to other turtles
			-- alternative: not each entry but chunkwise logs
			-- loops should be reversed: turtles then entries
			for id,otherTurtle in pairs(turtles) do
				-- save data for distribution to other turtles
				if not (update.id == id) then
					if otherTurtle.loadedChunks[entry[1]] then
						table.insert(otherTurtle.mapLog, entry)
					end
				end
			end
			
		end
		
		
		if global.printStatus then
			local pos = update.pos
			local orientation = update.orientation
			local task = update.task
			local lastTask = update.lastTask
			print("state:", update.id, pos.x, pos.y, pos.z, orientation, lastTask, task)
		end
		
		update = table.remove(updates)
	end
	
	local logs
	
	
	
	-- for i=1,#updates do
		-- local update = updates[i]
		
		-- for id,turtle in pairs(turtles) do

			-- for chunkId,chunkLog in pairs(update.chunkLogs) do
				-- if turtle.loadedChunks[chunkId] then
					-- turtle.chunkLogs[#turtle.chunkLogs+1] = chunkLog
				-- end
			-- end
		-- end
	-- end
	
	--process logs seperately to reduce nested loops ?
	-- complexity = turtleCount*(turtleCount-1)*avgEntriesPerLog
	-- for id,turtle in pairs(turtles) do
		-- for i=1,#logs do 
			-- local log = logs[i]
			-- if not log.sender == id then
				-- for k=1,#log do
					-- local entry = log[k]
					-- local chunkId = entry[1]
					-- if turtle.loadedChunks[chunkId] then
						-- if not turtle.chunkLogs[chunkId] then
							-- turtle.chunkLogs[chunkId] = { entry[2] = entry[3] }
						-- else
							-- turtle.chunkLogs[chunkId]][entry[2]] = entry[3]
						-- end
					-- end
					
				-- end
			-- end
		-- end
	-- end
		
		
		-- for senderId,log in ipairs(logs) do
			-- if not (senderId == id) then
				-- for _,entry in ipairs(log) do
					-- if turtle.loadedChunks[entry[1]] then
						-- table.insert(turtle.maplog,entry)
					-- end
				-- end
			-- end
		-- end
	-- end
	
end

function refreshState()
	-- refresh the online state of the turtles
	for id,turtle in pairs(turtles) do
		turtle.state.timeDiff = os.epoch("ingame") - turtle.state.time
		if turtle.state.timeDiff > 144000 then
			turtle.state.online = false
		else
			turtle.state.online = true
		end
	end
end


while global.running do
	local start = os.epoch("local")
	local s = os.epoch("local")
	--node:checkEvents()
	node:checkMessages()
	--print(os.epoch("local")-s,"events")
	s = os.epoch("local")
	--nodeStream:checkEvents()
	nodeStream:checkMessages()
	--print(os.epoch("local")-s,"nodeStream:checkEvents")
	s = os.epoch("local")
	--nodeUpdate:checkEvents()
	nodeUpdate:checkMessages()
	--print(os.epoch("local")-s,"nodeUpdate:checkEvents")
	s = os.epoch("local")
	checkUpdates()
	--print(os.epoch("local")-s,"checkUpdates")
	s = os.epoch("local")
	refreshState()
	--print(os.epoch("local")-s, "refreshState")
	--monitor:checkEvents()
	if global.printMainTime then 
		print(os.epoch("local")-start, "done")
	end
	sleep(0)
end

print("eeeh how")