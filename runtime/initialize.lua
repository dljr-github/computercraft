
require("classNetworkNode")
require("classMonitor")
require("classHostDisplay")
require("classMap")


local function initNode()
	global.node = NetworkNode:new("miner",true)
end
local function initStatus()
	global.nodeStatus = NetworkNode:new("miner_status",true)
end
local function initUpdate()
	global.nodeUpdate = NetworkNode:new("update",true)
end

local function initPosition()
	local x,y,z = gps.locate()
	if x and y and z then
		global.pos = vector.new(x,y,z)
	else
		print("gps not working")
		global.pos = vector.new(0,70,0)
	end
	print("position:",global.pos.x,global.pos.y,global.pos.z)
end


-- quick boot
parallel.waitForAll(initNode,initStatus,initUpdate)

initPosition()
global.map = Map:new()
global.map:load()
global.loadTurtles()
global.loadStations()
global.monitor = Monitor:new()
global.display = HostDisplay:new(1,1,global.monitor:getWidth(),global.monitor:getHeight())

