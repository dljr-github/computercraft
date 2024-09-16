--Class Variables

require("classList")

local defaultBackgroundColor = colors.black
local defaultTextColor = colors.white
local defaultTextScale = 0.5

Monitor = {}

local function findMonitor()
    local monitors = {peripheral.find("monitor")}
    if monitors[1] == nil then
        error("no monitor found",0)
    end
    return monitors[1]
end

--Class Initialization
function Monitor:new(m)
    local m = m or findMonitor() or {}
    setmetatable(m, self)
    self.__index = self
	if m.setTextScale then
		m.setTextScale(defaultTextScale)
	end
    m.setBackgroundColor(defaultBackgroundColor)
    m.setTextColor(defaultTextColor)
    m.clear()
	m.visible = true
    m:initialize()
    
    return m
end

--Class Functions
function Monitor:initialize()
    --DoStuff
    self.objects = List:new()
	self.events = List:new()
end

function Monitor:handleEvent(event)
	if event[1] == "monitor_touch" or event[1] == "mouse_up" then
		local x = event[3]
		local y = event[4]
		local o = self:getObjectByPos(x,y)
		if o and o.handleClick then
			o:handleClick(x,y)
		end
	end
end

function Monitor:pullEvent(eventName)
	local event
	if eventName then
		event = {os.pullEvent(eventName)}
	else --too much?
		event = {os.pullEvent()}
	end
	self:handleEvent(event)
end
function Monitor:addEvent(event)
	self.events:add(event)
end
function Monitor:checkEvents()
	local event = self.events:getFirst()
	if event then
		self.events:remove(event)
		self:handleEvent(event)
	end
end

function Monitor:setVisible(isVisible)
	self.visible = isVisible
	local node = self.objects:getFirst()
    while node do
		if node.setVisible then
			node:setVisible(isVisible)
		else
			node.visible = isVisible
		end
		node = self.objects:getNext(node)
	end
end

function Monitor:getObjectByPos(x,y)
    local node = self.objects:getNext()
    while node do
        if node.width and node.height and node.visible then
            if x >= node.x and x <= (node.x + node.width - 1)
                and y >= node.y and y <= (node.y + node.height - 1) then
                return node
            end
        end
        node = self.objects:getNext(node)
    end
    return nil
end
function Monitor:getBackgroundColorByPos(x,y)
    local o = self:getObjectByPos(x,y)
	if o and o.visible then
		if o.getBackgroundColorByPos then
			return o:getBackgroundColorByPos(x,y)
		elseif o.getBackgroundColor then
			return o:getBackgroundColor()
		elseif o.backgroundColor then
			return o.backgroundColor
		end
	elseif self.visible then
		return self.getBackgroundColor()
	end
    return nil
end
function Monitor:updateSize()
    self.width, self.height = self.getSize()
end

function Monitor:getWidth()
    self:updateSize()
    return self.width
end

function Monitor:getHeight()
    self:updateSize()
    return self.height
end

function Monitor:setBackgroundCol(color) -- obsolete
    self.prvBackgroundColor = self.getBackgroundColor()
    if color == nil then
        color = defaultBackgroundColor
    end
    self.setBackgroundColor(color)
end
function Monitor:setTextCol(color)
    self.prvTextColor = self.getTextColor()
    if color == nil then
        color = defaultTextColor
    end
    self.setTextColor(color)
end

function Monitor:restoreBackgroundColor() -- obsolete
    local color = self.prvBackgroundColor
    if color == nil then
        color = defaultBackgroundColor
    end
    self.setBackgroundColor(color)
end

function Monitor:restoreTextColor()
    local color = self.prvTextColor
    if color == nil then
        color = defaultTextColor
    end
    self.setTextColor(color)
end

function Monitor:restoreColor()
    self:restoreBackgroundColor()
    self:restoreTextColor()
end

function Monitor:addObject(o)
    self.objects:add(o)
	if o.setVisible then
		o:setVisible(true)
	else
		o.visible = true
	end
	o.monitor = self
	if o.onAdd then o:onAdd(self) end
    return o
end

function Monitor:removeObject(o)
    self.objects:remove(o)
	if o.setVisible then
		o:setVisible(false)
	else
		o.visible = false
	end
	o.monitor = nil
	if o.onRemove then o:onRemove(self) end
    return o
end

function Monitor:redraw()
	--if self.visible then -- not needed?
    self.clear()
    --draw oldest first -> inverse list
    
    local node = self.objects:getPrev()
    while node do
        node:redraw()
        node = self.objects:getPrev(node)
    end
end

function Monitor:drawText(x,y,text,color)
    self.setCursorPos(x,y)
	if not color then
		color = defaultTextColor
	end
	local backgroundColor = self:getBackgroundColorByPos(x,y)
	if not backgroundColor then
		backgroundColor = defaultBackgroundColor
	end
	self:setBackgroundCol(backgroundColor)
    self:setTextCol(color)
	self.setCursorPos(x,y)
	self.write(text)
    --TODO: check backgroundColor for each char (with blit)
    self:restoreColor()
end

function Monitor:drawLine(x,y,endX,endY,color)
    self:setBackgroundCol(color)
    local old = term.redirect(self)
    paintutils.drawLine(x,y,endX,endY,color)
    term.redirect(old)
    self:restoreBackgroundColor()
end

function Monitor:drawBox(x,y,width,height,color)
    -- self:setBackgroundCol(color)
    -- self.setCursorPos(x,y)
    -- for c=1,height do
        -- if c == 1 or c == height then
            -- for ln=1,width do
                -- self.write(" ")
            -- end
        -- else
            -- self.write(" ")
            -- if width > 1 then
                -- self.setCursorPos(x+width-1, y+c-1)
                -- self.write(" ")
            -- end
        -- end
        -- self.setCursorPos(x, y+c)
    -- end
    -- self:restoreBackgroundColor()
	
	color = colors.toBlit(color)
    for c=1,height do
		self.setCursorPos(x,y+c-1)
        if c == 1 or c == height then
			local text, textColor, backgroundColor = {},{},{}
            for ln=1,width do
				text[ln] = " "
				textColor[ln] = 0
				backgroundColor[ln] = color
            end
			self.blit(table.concat(text),table.concat(textColor),table.concat(backgroundColor))
        else
            self.blit(" ","0",color)
            if width > 1 then
                self.setCursorPos(x+width-1, y+c-1)
                self.blit(" ","0",color)
            end
        end
    end
	
	-- self:setBackgroundCol()
    -- local old = term.redirect(self)
    -- paintutils.drawBox(x,y,x+width-1,y+height-1,color)
    -- term.redirect(old)
	-- self:restoreBackgroundColor()

end

function Monitor:drawFilledBox(x,y,width,height,color)
	-- three options to draw a box
	
	-- self:setBackgroundCol(color)
    -- self.setCursorPos(x,y)
    -- for c=1,height do
        -- for ln=1,width do
            -- self.write(" ")
        -- end
        -- self.setCursorPos(x,y+c)
    -- end
    -- self:restoreBackgroundColor()
	
	color = colors.toBlit(color)
    for c=1,height do
		self.setCursorPos(x,y+c-1)
		local text, textColor, backgroundColor = {},{},{}
		for ln=1,width do
			text[ln] = " "
			textColor[ln] = 0
			backgroundColor[ln] = color
		end
		self.blit(table.concat(text), table.concat(textColor), table.concat(backgroundColor))
	end
	
	-- self:setBackgroundCol()
    -- local old = term.redirect(self)
    -- paintutils.drawFilledBox(x,y,x+width-1,y+height-1,color)
    -- term.redirect(old)
	-- self:restoreBackgroundColor()

end
