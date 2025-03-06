
local global = global
local display = global.display
local monitor = global.monitor

monitor:addObject(display)
monitor:redraw()

local frame = 0

while global.running do
	
	--local start = os.epoch("local")
	monitor:checkEvents()
	--local t1 = os.epoch("local")-start
	--start = os.epoch("local")
	if frame%5 == 0 then
		display:refresh()
		
	end
	-- display:refresh()
	-- local t2 = os.epoch("local")-start
	-- start = os.epoch("local")

	monitor:update()
	
	-- local t3 = os.epoch("local")-start
	-- print("events", t1, "refresh",t2, "update",t3)
	frame = frame + 1
	sleep(0.05)
	
end