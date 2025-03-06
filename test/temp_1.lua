
-- require("general/classBluenetNode")

-- local node = NetworkNode:new("test")
print(bluenet, global)
local global = global

while true do
	local event, time = os.pullEvent()
	if event == "test" then
		print(event,time,global.running)
	elseif event == "timer" then 
		--print(event,time)
	end
end