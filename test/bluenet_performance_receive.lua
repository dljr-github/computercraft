
--package.path = package.path ..";../runtime/?.lua"

os.loadAPI("bluenet.lua")
require("classBluenetNode")


local data = {"TEST"}
local node = NetworkNode:new("test", false)


node.onRequestStreamData = function(previous)
	return previous.data
end

node.onStreamMessage = function(msg, previous)
	node:stream()
end

node.onRequestAnswer = function(forMsg)
	node:answer(forMsg,forMsg.data)
end

local ct = 0
local prvct = 0
while true do
	
	node:listen()
	-- if msg.data[1] - prvct > 1 then 
		-- print("hmm", msg.data[1], msg.id, "prvct", prvct)
	-- end 
	-- prvct = msg.data[1]
	--node:checkWaitList()
	-- local msg = node:listen()
	-- if msg then 
		-- node:answer(msg,msg.data)
	-- end
end


---################# RAW

local ID, TIME, SENDER, RECIPIENT, PROTOCOL, TYPE, DATA, ANSWER, WAIT, WAITTIME = 1,2,3,4,5,6,7,8,9,10
local DISTANCE = 11

local computerId = os.getComputerID()
local protocol = "test"
local eventFilter = "modem_message"
local pullEventRaw = os.pullEventRaw
-- print(bluenet.isOpen("top", 0))
-- print(bluenet.isOpen("top", 10))
-- print(bluenet.isOpen("top", 11))

local peripheralCall = peripheral.call
-- channels already opened by node 


while true do
	local event, side, channel, sender, msg, distance = pullEventRaw(eventFilter)
	--if event == "modem_message" then print(os.clock(),event, modem, channel, sender) end
	--print(event, modem, sender, channel, msg.sender, msg.recipient, msg.data[1], distance)
	if event == "modem_message"
		--type(msg) == "table" 
		-- and ( type(msg[4]) == "number" and msg[4]
		-- and ( msg[4] == computerId )
		-- and ( protocol == nil or protocol == msg[5] )
		then
			--msg.distance = distance
			peripheralCall(side, "transmit", sender, channel, msg)
			--native.call(side,"transmit",sender,channel,msg)
			
			--return msg
			
	elseif event == "timer" then
		--print(os.clock(),event, modem, channel, sender, timer)
		if modem == timer then -- must be equal! >= geht nicht
			--print("returning nil")
			return nil
		end
	elseif event == "terminate" then 
		error("Terminated",0)
	end
	
end
	
