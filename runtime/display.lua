
display = global.display
monitor = global.monitor

monitor:addObject(display)
monitor:redraw()
local frame = 0

while global.running do
	
	local start = os.epoch("local")
	monitor:checkEvents()
	
	if frame%5 == 0 then
		display:refresh()
	end
	--print(os.epoch("local")-start,"display")
	
	frame = frame + 1
	sleep(0.05)
	
end