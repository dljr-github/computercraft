
local bluenet = bluenet
local ownChannel = bluenet.ownChannel
local computerId = os.getComputerID()

local running = global.running
local monitor = global.monitor

local node = global.node
local nodeStream = global.nodeStream
local nodeUpdate = global.nodeUpdate

local updateRate = 0.1
--local tmr = os.startTimer(updateRate)

while global.running do
	--local event = {os.pullEventRaw()}
	
	-- !! none of the functions called here can use os.pullEvent !!
	
	local event, p1, p2, p3, msg, p5 = os.pullEvent()
	if event == "modem_message"
		and ( p2 == ownChannel or p2 == bluenet.default.channels.broadcast ) 
		and type(msg) == "table" -- and type(msg.id) == "number" 
		--and not bluenet.receivedMessages[event[5].id]
		and ( type(msg.recipient) == "number" and msg.recipient
		and ( msg.recipient == computerId or msg.recipient == bluenet.default.channels.broadcast ) )
			-- just to make sure its a bluenet message
		then
			-- event, modem, channel, replyChannel, message, distance
			--bluenet.receivedMessages[event[5].id] = os.clock() + 9.5
			--bluenet.resetTimer()
			msg.distance = p5
			local protocol = msg.protocol
			if protocol == "miner_stream" then
				nodeStream:addMessage(msg)
				-- handle events immediately to avoid getting behind
				--nodeStream:handleEvent(event) 
				
			elseif protocol == "update" then
				nodeUpdate:addMessage(msg)
			elseif protocol == "miner" then
				node:addMessage(msg)
			elseif protocol == "chunk" then
				-- handle chunk requests immediately
				-- would be nice but seems to lead to problems
				node:handleMessage(msg)
				--node:addMessage(msg)
				
			end
	elseif event == "timer" then
		--if event[2] == bluenet.receivedTimer then 
			--bluenet.clearReceivedMessages()
		--end
		
	elseif event == "monitor_touch" or event == "mouse_up"
		or event == "mouse_click" then
		monitor:addEvent({event,p1,p2,p3,p4,p5})
	end
	if event and global.printEvents then
		if not (event == "timer") then
			print(event,p1,p2,p3,p4,p5)
		end
	end
end
