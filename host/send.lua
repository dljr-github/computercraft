
local nodeStream = global.nodeStream

local turtles = global.turtles
local running = global.running

nodeStream.onRequestStreamData = function(previous)
	
	local start = os.epoch("local")
	
	local turtle = turtles[previous.sender]
	-- append the entries
	local entry = table.remove(turtle.mapLog)
	while entry do
		table.insert(turtle.mapBuffer, entry)
		entry = table.remove(turtle.mapLog)
	end
	if #turtle.mapBuffer > 0 and turtle.state.online then
		if global.printSend then 
			print(os.epoch("local"), "sending map update", id, #turtle.mapBuffer)
		end

		return {"MAP_UPDATE",turtle.mapBuffer}
		--print("id", id, "time", timeSend .. " / " .. os.epoch("local")-start, "count", #data.mapBuffer)
	end
	
	return nil
end


while running do
	-- PROBLEM: node:send probably yields and lets other processes work
	-- processes (probably of turtles) should wait until send is done
	-- problem lies on the receiving end of turtles or size of the payload
	-- to avoid high payloads being sent unnecessarily -> only send to online turtles
	-- offline turtle buffer gets filled but only sent if turtle comes back
	
	-- mapBuffer is not cleared if sending takes too long
	-- yield while sending (current implementation) or checkValid not with
	-- current time, rather compare originalMsg with answerMsg
	
	--print(os.epoch("local"),"sending")
	local startTime = os.epoch("local")
	nodeStream:stream()
	--sendMapLog()
	print(os.epoch("local")-startTime,"done")
	local delay = (os.epoch("local")-startTime) / 1000
	if delay < 0.2 then delay = 0.2 
	elseif delay > 1 then delay = 1 end
	--else delay = delay * 2 end
	--print("delay", delay)
	-- if running into performance problems again -> set sleep time dynamically
	-- based on duration of sendMapLog
	--sleep(delay) --0.2
	sleep(delay)
	--os.pullEvent(os.queueEvent("yield"))
	
end