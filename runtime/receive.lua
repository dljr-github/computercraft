
require("classNetworkNode")

running = global.running
monitor = global.monitor

node = global.node
nodeStatus = global.nodeStatus
nodeUpdate = global.nodeUpdate

local updateRate = 0.1
--local tmr = os.startTimer(updateRate)

while global.running do
	--local event = {os.pullEventRaw()}
	local event = {os.pullEvent()}
	if event[1] == "timer" then
		if event[2] == tmr then 
			--tmr = os.startTimer(updateRate)
		end
	elseif event[1] == "monitor_touch" or event[1] == "mouse_up"
		or event[1] == "mouse_click" then
		monitor:addEvent(event)
	elseif  event[1] == "rednet_message" then --event[1] == "modem_message"
		if event[4] == "miner_status" then
			nodeStatus:addEvent(event)
			
		elseif event[4] == "update" then
			nodeUpdate:addEvent(event)
		else
			node:addEvent(event)
		end
	end
	if event and global.printEvents then
		if not (event[1] == "timer") then
			print(event[1],event[2],event[3],event[4])
		end
	end
end