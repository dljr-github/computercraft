require("classMiner")

args = {...}


--error({real=false,text="test",func="lul"})

local monitors = {peripheral.find("monitor")}
local monitor = monitors[1]
if monitor then
	assert(monitor, "no monitor found")
	monitor.clear()
	monitor.setCursorPos(1,1)
	monitor.write("myID: " .. os.getComputerID())
	monitor.setCursorPos(1,2)
	monitor.write("status: working")
end

miner = global.miner

--miner:setHome(miner.pos.x, miner.pos.y, miner.pos.z)
--miner:mineVein("minecraft:iron_ore")


miner:navigateToPos(275, 70, -177)
--miner:stripMine(miner.pos.y, 3, 3)
miner:returnHome()
miner:condenseInventory()
miner:dumpBadItems()
miner:transferItems()
--miner:returnHome()
miner.map:save()

print("DONE")
sleep(30)

if monitor then
	monitor.clear()

	monitor.setCursorPos(1,1)
	monitor.write("myID: " .. os.getComputerID())
	monitor.setCursorPos(1,2)
	monitor.write("status: ready")
end