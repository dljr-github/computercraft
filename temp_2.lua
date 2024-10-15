
require("runtime/global")
local glob = global

while true do
	
	local event, time = os.pullEvent()
	if event == "test" then
		print(event,time)
	end
	
	-- global.running = ( glob.running == false )
	-- print(os.epoch("local"), glob.running)
	-- sleep(0.2)
end