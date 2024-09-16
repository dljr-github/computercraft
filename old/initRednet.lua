
require("classNetworkNode")

local node = NetworkNode:new("miner",true)

while true do
	local msg = node:broadcast({"RUN","testMine"},true)
	if msg then
		print(msg.data[1])
	end
	print("sent")
	sleep(1)
end
