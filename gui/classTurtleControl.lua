
local Button = require("classButton")
local Label = require("classLabel")
local Window = require("classWindow")
local Frame = require("classFrame")
local TaskSelector = require("classTaskSelector")

local default = {
	colors = {
		background = colors.black,
		border = colors.gray,
		good = colors.green,
		okay = colors.orange,
		bad = colors.red,
		neutral = colors.white,
	},
	expanded = {
		width = 50,
		height = 9,
	},
	collapsed = {
		width = 50,
		height = 1,
	},
}

local TurtleControl = Window:new()

function TurtleControl:new(x,y,data,node)
	local o = o or Window:new(x,y,default.collapsed.width,default.collapsed.height) or {}
	setmetatable(o,self)
	self.__index = self
	
	o.backgroundColor = default.colors.background
	o.borderColor = default.colors.background
	
	o.node = node or nil 
	o.data = data
	o.mapDisplay = nil -- needed to enable the map button
	o.hostDisplay = nil
	o.collapsed = true
	o.win = nil
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
		
		-- Check if turtle is stranded
		if self.data.stranded and self.data.stranded.active then
			self.onlineText = "STRANDED"
			self.onlineColor = colors.red
			self.backgroundColor = colors.red
			self.borderColor = colors.red
		elseif self.data.online then
			self.onlineText = "online"
			self.onlineColor = default.colors.good
			self.backgroundColor = default.colors.background
			self.borderColor = default.colors.background
		else
			self.onlineText = "offline" 
			self.onlineColor = default.colors.bad
			self.backgroundColor = default.colors.background
			self.borderColor = default.colors.background
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
		self.data.pos = vector.new(0,0,0)
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
function TurtleControl:collapse()
	if not self.collapsed then
		self.collapsed = true
		self:removeObject(self.win)
		self:addObject(self.winSimple)
		self.win = self.winSimple
		self:setHeight(default.collapsed.height)
		--self.monitor:redraw()
	end
	return true
end
function TurtleControl:expand()
	if self.collapsed then 
		self.collapsed = false
		self:removeObject(self.win)
		self:addObject(self.winDetail)
		self.win = self.winDetail
		self:setHeight(default.expanded.height)
		--self.monitor:redraw()
	end
	return true
end

function TurtleControl:addTask()
	self.taskSelector = TaskSelector:new(self.x+19,self.y-1)
	self.taskSelector:setNode(self.node)
	self.taskSelector:setData(self.data)
	self.taskSelector:setHostDisplay(self.hostDisplay)
	self.parent:addObject(self.taskSelector)
	self.parent:redraw()
	return true
	
end
function TurtleControl:cancelTask()
	if self.node then
		self.node:send(self.data.id, {"STOP"})
	end
end

function TurtleControl:openMap()
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
	
	self.win:fillParent()
	self.frmId:setWidth(self.width)
	self.frmId:setHeight(self.height)
	
end

function TurtleControl:redraw() -- super override
	self:refresh()
	
	Window.redraw(self) -- super
	
	if not self.collapsed then
		for i=3,5 do
			self:setCursorPos(18,i)
			self:blit("|",colors.toBlit(colors.lightGray),colors.toBlit(self.backgroundColor))
		end
		for i=3,5 do
			self:setCursorPos(34,i)
			self:blit("|",colors.toBlit(colors.lightGray),colors.toBlit(self.backgroundColor))
		end
	end
end

function TurtleControl:initialize()
	
	self:removeObject(self.btnClose) -- close button not needed
	
	self.winDetail = Window:new()
	self.winDetail:removeObject(self.winDetail.btnClose)
	
	self.winSimple = Window:new()
	self.winSimple:removeObject(self.winSimple.btnClose)
	
	if self.collapsed then
		self:addObject(self.winSimple)
		self.win = self.winSimple
	else 
		self:addObject(self.winDetail)
		self.win = self.winDetail
	end
	self.win:fillParent()
	
	-- simple
	self.btnExpand = Button:new("+",1,1,3,1)
	self.winSimple.lblId = Label:new(self.data.id .. " - " .. self.data.label,5,1)
	self.winSimple.lblTask = Label:new(self.data.lastTask,20,1)
	self.winSimple.lblOnline = Label:new(self.onlineText,36,1,self.onlineColor)
	
	self.btnExpand.click = function() return self:expand() end
	
	self.winSimple:addObject(self.btnExpand)
	self.winSimple:addObject(self.winSimple.lblId)
	self.winSimple:addObject(self.winSimple.lblTask)
	self.winSimple:addObject(self.winSimple.lblOnline)
	
	--self.winSimple.lblPosition = Label:new(self.data.pos,30,1)
	
	
	-- detail
	self.frmId = Frame:new(self.data.id .. " - " .. self.data.label ,1,1,self.width,self.height,default.borderColor)
	self.btnCollapse = Button:new("-",1,1,3,1)
	-- row 1 - 16
	print(self.data.pos, self.data.pos.x, self.data.pos.y)
	self.lblX = Label:new("X  " .. self.data.pos.x,3,3)
	self.lblY = Label:new("Y  " .. self.data.pos.y,3,4)
	self.lblZ = Label:new("Z  " .. self.data.pos.z,3,5)
	self.btnMap = Button:new("map",12,3,5,1)
	self.btnCallHome = Button:new("home",12,5,5,1)
	-- row 17 - 27
	self.lblTaskLast = Label:new(self.data.lastTask,20,3)
	self.lblTask = Label:new(self.data.task,20,4)
	self.btnAddTask = Button:new("add",20,5,6,1, colors.purple)
	self.btnCancelTask = Button:new("cancel",27,5,6,1)
	self.btnDeleteTurtle = Button:new("delete turtle",20,5,13,1)
	self.btnRecoverTurtle = Button:new("RECOVER",20,5,7,1, colors.yellow)
	-- row 28 - 
	self.lblFuel = Label:new(      "fuel      " .. self.data.fuelLevel,36,3)
	self.lblEmptySlots = Label:new("slots     " .. self.data.emptySlots,36,4)
	self.lblOnline = Label:new(self.onlineText,36,5,self.onlineColor)
	self.lblTime = Label:new("00:00.00", 46,5)
	
	-- Command buttons (row 6-7)
	self.lblCommands = Label:new("commands:",3,7)
	self.btnUpdateSoftware = Button:new("update software",12,7,15,1, colors.blue)
	self.lblResponse = Label:new("",3,8,colors.lightGray)
	
	self.btnAddTask.click = function() return self:addTask() end
	self.btnMap.click = function() self:openMap() end
	self.btnCancelTask.click = function() self:cancelTask() end
	self.btnCallHome.click = function() self:callHome() end
	self.btnDeleteTurtle.click = function() return self:deleteTurtle() end
	self.btnRecoverTurtle.click = function() return self:recoverTurtle() end
	self.btnUpdateSoftware.click = function() return self:updateSoftware() end
	self.btnCollapse.click = function() return self:collapse() end
	
	self.winDetail:addObject(self.frmId)
	self.winDetail:addObject(self.lblX)
	self.winDetail:addObject(self.lblY)
	self.winDetail:addObject(self.lblZ)
	self.winDetail:addObject(self.lblTaskLast)
	self.winDetail:addObject(self.lblTask)
	self.winDetail:addObject(self.lblFuel)
	self.winDetail:addObject(self.lblTime)
	self.winDetail:addObject(self.lblOnline)
	self.winDetail:addObject(self.lblEmptySlots)

	self.winDetail:addObject(self.btnCollapse)
	self.winDetail:addObject(self.btnAddTask)
	self.winDetail:addObject(self.btnMap)
	self.winDetail:addObject(self.btnCancelTask)
	self.winDetail:addObject(self.btnCallHome)
	self.winDetail:addObject(self.btnDeleteTurtle)
	self.winDetail:addObject(self.btnRecoverTurtle)
	
	self.winDetail:addObject(self.lblCommands)
	self.winDetail:addObject(self.btnUpdateSoftware)
	self.winDetail:addObject(self.lblResponse)
	
	self.btnDeleteTurtle.visible = self.data.online
	self.btnRecoverTurtle.visible = false -- Initially hidden, shown only for stranded turtles
end

function TurtleControl:refreshPos()
	self.lblX:setText("X  " .. self.data.pos.x)
	self.lblY:setText("Y  " .. self.data.pos.y)
	self.lblZ:setText("Z  " .. self.data.pos.z)
end

function TurtleControl:refresh()
	self:refreshPos()

	if self.collapsed then
		--self.winSimple.lblId:setText(self.data.id .. " - " .. self.data.label)
		self.winSimple.lblTask:setText(self.data.lastTask or "no task")
		self.winSimple.lblOnline:setText(self.onlineText)
		self.winSimple.lblOnline:setTextColor(self.onlineColor)
	else
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
		
		-- Button visibility logic
		local isStranded = self.data.stranded and self.data.stranded.active
		self.btnAddTask.visible = self.data.online and not isStranded
		self.btnCancelTask.visible = self.data.online and not isStranded
		self.btnCallHome.visible = self.data.online and not isStranded
		self.btnDeleteTurtle.visible = not self.data.online and not isStranded
		self.btnRecoverTurtle.visible = isStranded
		
		-- Show stranded info in task field if turtle is stranded
		if isStranded then
			self.lblTask:setText("STRANDED: " .. self.data.stranded.reason)
			self.lblTask:setTextColor(colors.red)
		else
			self.lblTask:setTextColor(colors.white)
		end
	end
end

function TurtleControl:deleteTurtle()
	-- TODO: shutdown and remove turtle from global.turtles
	if self.hostDisplay then
		self.hostDisplay:deleteTurtle(self.data.id)
	end
	return true
end

function TurtleControl:recoverTurtle()
	if self.data.stranded and self.data.stranded.active then
		local pos = self.data.stranded.pos
		print("Manual recovery needed for turtle", self.data.id)
		print("Last known position:", pos.x, pos.y, pos.z)
		print("Reason:", self.data.stranded.reason)
		print("Fuel level:", self.data.stranded.fuel)
		
		-- Clear stranded status (manual intervention assumed)
		self.data.stranded.active = false
		self.data.online = false -- Keep offline until turtle reconnects
		
		-- Show recovery instructions
		if self.hostDisplay then
			local message = string.format(
				"Turtle %s (%s) needs manual recovery:\n" ..
				"Position: %d, %d, %d\n" ..
				"Fuel: %d\n" ..
				"Reason: %s\n\n" ..
				"Go to the turtle and manually restart it or teleport it home.",
				self.data.id,
				self.data.stranded.label or "Unknown",
				pos.x, pos.y, pos.z,
				self.data.stranded.fuel,
				self.data.stranded.reason
			)
			-- If there's a way to show dialogs, use it
			-- Otherwise just print
			print(message)
		end
	end
	return true
end

function TurtleControl:sendShellCommand(command, description)
	if self.node and self.data.online then
		print("Executing", description, "on turtle", self.data.id, ":", command)
		
		-- Send shell command to turtle
		local success = self.node:send(self.data.id, {"SHELL_COMMAND", command}, false, false, 5)
		if success then
			self.lblResponse:setText("Sent: " .. description)
			self.lblResponse:setTextColor(colors.yellow)
		else
			self.lblResponse:setText("Failed to send " .. description)
			self.lblResponse:setTextColor(colors.red)
		end
		
		self.lblResponse:redraw()
	else
		self.lblResponse:setText("Turtle offline")
		self.lblResponse:setTextColor(colors.orange)
		self.lblResponse:redraw()
	end
	return true
end

function TurtleControl:updateSoftware()
	return self:sendShellCommand("install", "software update")
end


function TurtleControl:updateShellResponse(command, success, output)
	-- Update the response label with command result
	if self.lblResponse then
		local statusText = success and "✓" or "✗"
		local color = success and colors.green or colors.red
		local responseText = statusText .. " " .. command
		
		-- Include output if available and short enough
		if output and output ~= "" then
			if #output < 30 then
				responseText = responseText .. ": " .. output
			else
				responseText = responseText .. ": " .. string.sub(output, 1, 25) .. "..."
			end
		end
		
		-- Truncate if too long for display
		if #responseText > 45 then
			responseText = string.sub(responseText, 1, 42) .. "..."
		end
		
		self.lblResponse:setText(responseText)
		self.lblResponse:setTextColor(color)
		self.lblResponse:redraw()
		
		-- Store full response for potential future display
		self.lastShellResponse = {
			command = command,
			success = success,
			output = output,
			timestamp = os.epoch("utc")
		}
	end
end

return TurtleControl