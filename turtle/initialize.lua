
-- initialize the required globals

require("classList")
require("classMiner")
require("classNetworkNode")

tasks = {}
global.list = List:new()
-- global.defaultHost = 0

--os.setComputerLabel(tostring(os.getComputerID()))

local function initNode()
	global.node = NetworkNode:new("miner")
end
local function initStatus()
	global.nodeStatus = NetworkNode:new("miner_status")
end

parallel.waitForAll(initNode,initStatus)

local status,err = pcall(function() 
	global.miner = Miner:new()
	global.map = global.miner.map
end )
global.handleError(err,status)