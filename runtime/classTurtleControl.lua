
require("classButton")
require("classLabel")
require("classWindow")
require("classFrame")
require("classTaskSelector")

local default = {
	colors = {
		background = colors.black,
		border = colors.gray,
		good = colors.green,
		okay = colors.orange,
		bad = colors.red,
		neutral = colors.white,
	},
	width = 50,
	height = 7,
}

TurtleControl = Window:new()

function TurtleControl:new(x,y,data,node)
	local o = o or Window:new(x,y,default.width,default.height) or {}
	setmetatable(o,self)
	self.__index = self
	
	o.backgroundColor = default.colors.background
	o.borderColor = default.colors.border
	
	o.node = node or nil 
	o.data = data
	o.mapDisplay = nil -- needed to enable the map button
	o.hostDisplay = nil
	o:initialize()
	
	o:setData(data)
	
	return o
end

function TurtleControl:setNode(node)
	self.node = node
end

function TurtleControl:setData(data)
	if data then
		self.data = data
		self.data.timeDiff = os.epoch("ingame") - self.data.time
		if self.data.timeDiff > 144000 then
			self.data.online = false
			self.onlineText = "offline" 
			self.onlineColor = default.colors.bad
		else 
			self.data.online = true 
			self.onlineText = "online"
			self.onlineColor = default.colors.good
		end
		
		if self.data.fuelLevel <= 0 then
			self.fuelColor = default.colors.bad
		elseif self.data.fuelLevel <= 128 then
			self.fuelColor = default.colors.okay
		else self.fuelColor = default.colors.neutral end
		
		self.data.pos = vector.new(self.data.pos.x, self.data.pos.y, self.data.pos.z)
		-- self:refresh()
		
	else
		--pseudo data
		self.data = {}
		self.data.id = "no data"
		self.data.label = ""
		self.data.pos = vector.new(275,70,-177)
		self.data.taskLast = "no task"
		self.data.task = "no task"
		self.data.fuelLevel = 123
		self.data.online = false
		self.data.time = 283473834
		self.onlineText = "offline"
	end
end
function TurtleControl:setHostDisplay(hostDisplay)
	self.hostDisplay = hostDisplay
	if self.hostDisplay then
		self.mapDisplay = self.hostDisplay:getMapDisplay()
	end
end

function TurtleControl:addTask()
	self.taskSelector = TaskSelector:new(self.x+19,self.y-1)
	self.taskSelector:setNode(self.node)
	self.taskSelector:setData(self.data)
	self.taskSelector:setHostDisplay(self.hostDisplay)
	self.parent:addObject(self.taskSelector)
	self.parent:redraw()
	return true
	
	-- if self.node then
		-- --self.node:send(self.data.id, {"STOP"})
		-- --self.node:send(self.data.id, {"DO","navigateToPos",{275, 70, -177}})
		-- --self.node:send(self.data.id, {"DO","stripMine",{3,2,3}})
		-- self.node:send(self.data.id, {"DO", "mineArea", {vector.new(275, 70, -177) ,vector.new(268, 60, -170)}}) --vector.new(267, 74, -192)
	-- end
end
function TurtleControl:cancelTask()
	if self.node then
		self.node:send(self.data.id, {"STOP"})
	end
end
function TurtleControl:openMap()
	-- TODO: add setFocus function in mapdisplay
	-- if self.display then
		-- self.display:openMap()
		-- self.display:setFocus()
	-- end
	if self.hostDisplay and self.mapDisplay then
		self.mapDisplay:setFocus(self.data.id)
		self.hostDisplay:displayMap()
	end
end
function TurtleControl:callHome()
	if self.node then
		self.node:send(self.data.id, {"DO", "returnHome"})
	end
end

function TurtleControl:onResize() -- super override
	Window.onResize(self) -- super
	
	self.frmId:setWidth(self.width)
end

function TurtleControl:redraw() -- super override
	self:refresh()
	
	Window.redraw(self) -- super
	
	for i=3,5 do
		self:setCursorPos(18,i)
		self:blit("|",colors.toBlit(colors.lightGray),colors.toBlit(self.backgroundColor))
	end
	for i=3,5 do
		self:setCursorPos(34,i)
		self:blit("|",colors.toBlit(colors.lightGray),colors.toBlit(self.backgroundColor))
	end
end

function TurtleControl:initialize()
	
	self:removeObject(self.btnClose) -- close button not needed
	self.frmId = Frame:new(self.data.id .. " - " .. self.data.label ,1,1,self.width,self.height,self.borderColor)
	
	-- row 1 - 16
	self.lblX = Label:new("X  " .. self.data.pos.x,3,3)
	self.lblY = Label:new("Y  " .. self.data.pos.y,3,4)
	self.lblZ = Label:new("Z  " .. self.data.pos.z,3,5)
	self.btnMap = Button:new("map",12,3,5,1)
	self.btnCallHome = Button:new("home",12,5,5,1)
	-- row 17 - 27
	self.lblTaskLast = Label:new(self.data.taskLast,20,3)
	self.lblTask = Label:new(self.data.task,20,4)
	self.btnAddTask = Button:new("add",20,5,6,1)
	self.btnCancelTask = Button:new("cancel",27,5,6,1)
	-- row 28 - 
	self.lblFuel = Label:new(      "fuel      " .. self.data.fuelLevel,36,3)
	self.lblEmptySlots = Label:new("slots     " .. self.data.emptySlots,36,4)
	self.lblOnline = Label:new(self.onlineText,36,5,self.onlineColor)
	self.lblTime = Label:new("00:00.00", 46,5)
	
	self.btnAddTask.click = function() return self:addTask() end
	self.btnMap.click = function() self:openMap() end
	self.btnCancelTask.click = function() self:cancelTask() end
	self.btnCallHome.click = function() self:callHome() end
	
	self:addObject(self.frmId)
	
	self:addObject(self.lblX)
	self:addObject(self.lblY)
	self:addObject(self.lblZ)
	self:addObject(self.lblTaskLast)
	self:addObject(self.lblTask)
	self:addObject(self.lblFuel)
	self:addObject(self.lblTime)
	self:addObject(self.lblOnline)
	self:addObject(self.lblEmptySlots)
	
	self:addObject(self.btnAddTask)
	self:addObject(self.btnMap)
	self:addObject(self.btnCancelTask)
	self:addObject(self.btnCallHome)
	
end

function TurtleControl:refreshPos()
	self.lblX:setText("X  " .. self.data.pos.x)
	self.lblY:setText("Y  " .. self.data.pos.y)
	self.lblZ:setText("Z  " .. self.data.pos.z)
end

function TurtleControl:refresh()
	self:refreshPos()
	
	self.lblTaskLast:setText(self.data.lastTask or "no task")
	self.lblTask:setText(self.data.task)

	self.lblFuel:setTextColor(self.fuelColor)
	self.lblFuel:setText("fuel      " .. self.data.fuelLevel)
	self.lblEmptySlots:setText("slots     " .. self.data.emptySlots.."/16")
	-- 1 tick = 3600 ms
	-- 1 day = 24000 ticks
	-- 1 real second = 72000 ms
	local seconds = math.floor(self.data.timeDiff/72000)%60
	local minutes = math.floor(self.data.timeDiff/72000/60)
	local ticks = math.floor((self.data.timeDiff % 72000)/3600/20*100)
	local lastSeen = string.format("%02d:%02d.%02d",minutes,seconds,ticks)
	self.lblTime:setText(lastSeen)
	self.lblOnline:setText(self.onlineText)
	
	self.lblOnline:setTextColor(self.onlineColor)
	
	
	self.btnAddTask:setEnabled(self.data.online)
	self.btnCancelTask:setEnabled(self.data.online)
	self.btnCallHome:setEnabled(self.data.online)
end

function TurtleControl:deleteTurtle()
	-- TODO: shutdown and remove turtle from global.turtles
end
