--Includes

require("classMonitor")
require("classButton")
require("classGPU")
require("classBox")
require("classToggleButton")
require("classFrame")
require("classLabel")
require("classNetworkNode")
require("classCheckBox")
require("classWindow")
require("classMap")
require("classMapDisplay")
require("classTurtleControl")

--Functions

--Declaration
monitor = global.monitor
node = global.node
nodeUpdate = global.nodeUpdate
nodeStatus = global.nodeStatus
map = global.map
lastUpdates = global.lastUpdates

--Initialization

local x = 0
local time = 0

--Code
local winMain = Window:new(1,1)
monitor:addObject(winMain)
--winMain:setWidth(monitor:getWidth())
winMain:fillParent()

box = Box:new(18,7,5,5,colors.white)
winMain:addObject(box)
box:setWidth(15)
winMain:removeObject(box)
box = nil

frmText = Frame:new("Data",22,4,20,20,colors.lightGray)
winMain:addObject(frmText)


lblTime = Label:new("Time:",24,6)
winMain:addObject(lblTime)
lblTimeVal = Label:new("0",30,6)
winMain:addObject(lblTimeVal)

lblID = winMain:addObject(Label:new("ID:   " .. os.getComputerID(),24,8))

btnCheck = CheckBox:new(24,10, "print status", global.printStatus)
winMain:addObject(btnCheck)
btnCheck.click = function()
	global.printStatus = btnCheck.active
end

frmBtn = Frame:new("Functions",1,4,20,20,colors.gray)
winMain:addObject(frmBtn)

btnMap = Button:new("Map",3,6)
winMain:addObject(btnMap)

btnTurtles = Button:new("Turtles",3,10)
winMain:addObject(btnTurtles)


-- example Toggle Button
-- btnToggle = ToggleBtn:new(3,14)
-- winMain:addObject(btnToggle)

-- example disabled Button
-- btnDisabled = Button:new("Disabled",3,6)
-- winMain:addObject(btnDisabled)
-- btnDisabled:setEnabled(false)


btnCount = winMain:addObject(Button:new("0",3,18,10,3,colors.purple))
btnCount:setEnabled(true)
btnCount.click = function()
    local ct = tonumber(btnCount.text) + 1
    btnCount:setText(tostring(ct))
end

btnStop = Button:new("STOP",monitor:getWidth()-9, 1, 10,3,colors.red)
winMain:addObject(btnStop)
btnStop.click = function()
    global.running = false
end


btnReboot = winMain:addObject(Button:new("REBOOT", monitor:getWidth()-9,4,11,3,colors.blue))
btnReboot.click = function()
    monitor.clear()
    monitor.setCursorPos((monitor:getWidth()-10)/2,monitor:getHeight()/2)
    monitor.write("REBOOTING")
	node:broadcast({"REBOOT"},true)
	--global.map:save()
    os.reboot()
    --edit startup
end

btnAddTask = winMain:addObject(Button:new("addTask",44,8,11,3,colors.purple))
btnRemoveTask = winMain:addObject(Button:new("removeTask",44,12,11,3,colors.purple))
btnReturnHome = winMain:addObject(Button:new("returnHome",44,16,11,3,colors.yellow))

local taskId = -1

btnAddTask.click = function()
	print("SENT")
	-- local msg, task = node:addTask(1, "testMine")
	-- if task then 
		-- print("sent task", task.taskId)
		-- taskId = task.taskId
	-- end
	-- if msg then	print(msg.type, msg.data[1]) end
	--local msg = node:broadcast({"DO","error",{"test",false}},true)
	--local msg = node:broadcast({"DO","navigateToPos",{275, 70, -177}},true)
	local msg = node:broadcast({"DO","transferItems"},true)
	--local msg = node:broadcast({"DO","turnTo",{1}},true)
	--local msg = node:broadcast({"RUN","testMine",{"1",2}},true)
	if msg then
		print(msg.type, msg.data[1])
	end
end

btnRemoveTask.click = function()
	local task = node:removeTask(taskId)
	if not task then
		print("deleted successfully")
	else
		print("task not deleted")
	end
end

local mapDisplay
mapDisplay = MapDisplay:new(4,4,32,16)
mapDisplay:setMid(275, 70, -177)
mapDisplay:setMap(map)
	
btnMap.click = function()
	-- display Map

	monitor:addObject(mapDisplay)
	mapDisplay:fillParent()
	map:setData(275,70,-177,"aaa")
	monitor:redraw()
	return true
end






-- Turtle Management
-- needed vars
winTurtles = Window:new()
lblTurtles = Label:new("Turtles",1,1)
winTurtles:addObject(lblTurtles)
turtleControls = {}
turtleCt = 0
local function refreshTurtles()
	for sender,msg in pairs(lastUpdates) do
		if not turtleControls[sender] then 
			turtleControls[sender] = TurtleControl:new(1,3+6*turtleCt,msg.status,global.node)
			winTurtles:addObject(turtleControls[sender])
			turtleControls[sender]:fillWidth()
			turtleCt = turtleCt + 1
		else
			turtleControls[sender]:setData(msg.status)
		end
	end
	winTurtles:redraw()
end


btnTurtles.click = function()
	monitor:addObject(winTurtles)
	winTurtles:fillParent()
	for _,turtleControl in pairs(turtleControls) do
		turtleControl:fillWidth()
	end
	refreshTurtles()
	monitor:redraw()
	return true
end



btnReturnHome.click = function()
	-- call mine home
    print("SENT")
    local msg = node:broadcast({"DO","returnHome"},true)
	if msg then
		print(msg.type, msg.data[1])
	end
end

monitor:redraw() -- draw initial monitor

local function updateTime()
    time = time + 1
	if time%1 == 0 then
		lblTimeVal:setText(time/20)
		--lblTimeVal:redraw()
	end
	--to remove blinking http://www.computercraft.info/forums2/index.php?/topic/22397-surface-api-162/
end

local wasWindowVisible = true

while global.running do
	
	monitor:checkEvents()
	
	if mapDisplay and mapDisplay.visible then
		winMain:setVisible(false)
		wasWindowVisible = winMain.visible
	elseif wasWindowVisible == false then
		winMain:setVisible(true)
		wasWindowVisible = winMain.visible
		monitor:redraw()
	end
	updateTime()
	if time%5 == 0 and mapDisplay then
		mapDisplay:checkUpdates()
		refreshTurtles()
	end
	
	sleep(0.05)
	
end



monitor.clear()
monitor.setCursorPos((monitor:getWidth()-10)/2,monitor:getHeight()/2)
monitor.write("TERMINATED")
print("TERMINATED")
