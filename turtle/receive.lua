
local node = global.node
local nodeStream = global.nodeStream
local tasks = global.tasks
local miner = global.miner
local bluenet = bluenet

nodeStream.onStreamMessage = function(msg,previous) 
	-- reboot is handled in NetworkNode
	nodeStream._clearLog()
	
	local start = os.epoch("local")
	local ct = 0
	if msg and msg.data and msg.data[1] == "MAP_UPDATE" then
		if miner then 
			local mapLog = msg.data[2]
			for _,entry in ipairs(mapLog) do
				-- setData without log
				-- setChunkData should not result in the chunk being requested!
				miner.map:setChunkData(entry[1],entry[2],entry[3],false)
				ct = ct + 1
			end
		end
	end
	--print(os.epoch("local")-start,"onStream", ct)
end

node.onReceive = function(msg)
	-- reboot is handled in NetworkNode
	if msg and msg.data then
		if msg.data[3] then 
			--print("received:", msg.data[1], msg.data[2], unpack(msg.data[3]))
		else 
			--print("received:", msg.data[1], msg.data[2]) 
		end
		
		if msg.data[1] == "STOP" then
			if miner then 
				miner.stop = true
			end
		else
			table.insert(tasks, msg.data)
		end
	end
end

while true do
	
	local event, p1, p2, p3, msg, p5 = os.pullEvent("modem_message")
	if ( p2 == bluenet.ownChannel or p2 == bluenet.default.channels.broadcast ) 
		and type(msg) == "table"
		and ( type(msg.recipient) == "number" and msg.recipient
		and ( msg.recipient == bluenet.computerId or msg.recipient == bluenet.default.channels.broadcast ) )
		then
			msg.distance = p5
			local protocol = msg.protocol
			if protocol == "miner_stream" then
				--and ( not msg.data or msg.data[1] ~= "STREAM_OK" ) then
				nodeStream:handleMessage(msg)
				
			elseif protocol == "miner" or protocol == "chunk" then
				node:handleMessage(msg)
			end
	end
	
end