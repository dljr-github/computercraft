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

local default = {
	colors = {
		background = colors.black,
	},
}


HostDisplay = Window:new()

function HostDisplay:new(x,y,width,height)
	local o = o or Window:new(x,y,width,height)
	setmetatable(o,self)
	self.__index = self
	
	o.backgroundColor = default.colors.background
	
	o:initialize()
	
	return o
end

function HostDisplay:loadGlobals()
	if global then
		self.node = global.node
		self.map = global.map
		self.turtles = global.turtles
		self.pos = global.pos
	else
		print("GLOBALS NOT AVAILABLE")
	end
end

function HostDisplay:initialize()
	self:loadGlobals()
	
	-- init main window
	self.winMain = Window:new(1,1)
	self:addObject(self.winMain)
	self.winMain:fillParent()
	
	-- add main window objects
	self.winFunctions = Window:new(1,4,20,20)
	self.winData = Window:new(22,4,20,20)
	self.winMain.btnReboot = Button:new("REBOOT", self:getWidth()-9,4,11,3,colors.blue)
	self.winMain.btnTerminate = Button:new("STOP", self:getWidth()-9,1,10,3,colors.red)
	
	self.winMain.btnReboot.click = function() self:reboot() end
	self.winMain.btnTerminate.click = function() return self:terminate() end
	
	self.winMain:addObject(self.winFunctions)
	self.winMain:addObject(self.winData)
	self.winMain:addObject(self.winMain.btnReboot)
	self.winMain:addObject(self.winMain.btnTerminate)
	
	
	-- add functions window objects
	self.winFunctions.frmFunctions = Frame:new("Functions",1,1,20,20)
	self.winFunctions.btnMap = Button:new("Map",3,3)
	self.winFunctions.btnTurtles = Button:new("Turtles",3,7)
	
	self.winFunctions.btnMap.click = function() return self:displayMap() end
	self.winFunctions.btnTurtles.click = function() return self:displayTurtles() end
	
	self.winFunctions:addObject(self.winFunctions.frmFunctions)
	self.winFunctions:addObject(self.winFunctions.btnMap)
	self.winFunctions:addObject(self.winFunctions.btnTurtles)
	
	-- add data window objects
	self.winData.frmData = Frame:new("Data",1,1,20,20)
	self.winData.lblTime = Label:new("Time:",3,3)
	self.winData.lblTimeVal = Label:new("0",9,3)
	self.winData.lblId = Label:new("ID:   " .. os.getComputerID(),3,5)
	self.winData.btnPrintStatus = CheckBox:new(3,7, "print status", global.printStatus)
	self.winData.btnPrintEvents = CheckBox:new(3,9, "print events", global.printEvents)
	
	self.winData.btnPrintStatus.click = function()
		global.printStatus = self.winData.btnPrintStatus.active
	end
	self.winData.btnPrintEvents.click = function()
		global.printEvents = self.winData.btnPrintEvents.active
	end
	
	self.winData:addObject(self.winData.frmData)
	self.winData:addObject(self.winData.lblTime)
	self.winData:addObject(self.winData.lblTimeVal)
	self.winData:addObject(self.winData.lblId)
	self.winData:addObject(self.winData.btnPrintStatus)
	self.winData:addObject(self.winData.btnPrintEvents)
	
	-- init hidden windows
	self.mapDisplay = MapDisplay:new(4,4,32,16)
	self.winTurtles = Window:new()
	
	-- add map window data
	self.mapDisplay:setMap(self.map)
	self.mapDisplay:setMid(self.pos.x,self.pos.y,self.pos.z)
	
	-- add turtles window objects
	self.winTurtles.lblTurtles = Label:new("Turtles",1,1)
	self.winTurtles.turtleControls = {}
	self.winTurtles.turtleCt = 0
	
	self.winTurtles.refresh = function() self:updateTurtles() end
	
	self.winTurtles:addObject(self.winTurtles.lblTurtles)
	
	
	-- initial redraw
	-- self:redraw()
	
end

function HostDisplay:refresh()
	self.mapDisplay:checkUpdates()
	self:updateTurtles()
	self:updateTime()
end
function HostDisplay:redraw()
	-- only redraw the top window and set the rest invisible
	-- get first visible window
	local winTop = self.objects:getFirst()
	local o = winTop
	while o do
		if o.visible then
			winTop = o
			break
		end
		o = self.objects:getNext(o)
	end
	
	-- set other windows invisible
	local o = self.objects:getNext(winTop)
	while o do
		if o.setVisible then
			o:setVisible(false)
		else
			o.visible = false
		end
		o = self.objects:getNext(o)
	end
	
	-- make sure the window is set to visible
	if winTop.setVisible then
		winTop:setVisible(true)
	else
		winTop.visible = true
	end
	winTop:redraw()
end
function HostDisplay:updateTime()
	local lbl = self.winData.lblTimeVal
	local time = os.epoch("ingame") / 1000
	local timeTable = os.date("*t", time)
	local txt = string.format("%02d:%02d:%02d",timeTable.hour,timeTable.min,timeTable.sec)
	lbl:setText(txt)
	lbl:redraw()
end
function HostDisplay:getMapDisplay()
	return self.mapDisplay
end
function HostDisplay:displayMap()
	self:addObject(self.mapDisplay)
	self.mapDisplay:fillParent()
	self:redraw()
	return true
end
function HostDisplay:displayTurtles()
	self:addObject(self.winTurtles)
	self.winTurtles:fillParent()
	for _,turtleControl in pairs(self.winTurtles.turtleControls) do
		turtleControl:fillWidth()
	end
	self:updateTurtles()
	self:redraw()
	return true
end
function HostDisplay:updateTurtles()
	for id,data in pairs(self.turtles) do
		local turtleControls = self.winTurtles.turtleControls
		if not turtleControls[id] then 
			turtleControls[id] = TurtleControl:new(1,3+6*self.winTurtles.turtleCt,data.state,global.node)
			self.winTurtles:addObject(turtleControls[id])
			turtleControls[id]:fillWidth()
			turtleControls[id]:setHostDisplay(self)
			self.winTurtles.turtleCt = self.winTurtles.turtleCt + 1
		else
			turtleControls[id]:setData(data.state)
		end
	end
	self.winTurtles:redraw()
end
function HostDisplay:beforeTerminate()
	global.map:save()
	global.saveTurtles()
	global.saveStations()
end

function HostDisplay:reboot()
	self:beforeTerminate()
	self:clear()
    self:setCursorPos((self:getWidth()-10)/2,self:getHeight()/2)
    self:write("REBOOTING")
	-- self.node:broadcast({"REBOOT"},true)
    os.reboot()
end

function HostDisplay:terminate()
	self:beforeTerminate()
	global.running = false
	self:clear()
	self:setCursorPos((self:getWidth()-10)/2,self:getHeight()/2)
	self:write("TERMINATED")
	print("TERMINATED")
	return true
end

