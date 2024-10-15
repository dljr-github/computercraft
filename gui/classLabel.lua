local default = {
	textColor = colors.white,
	backgroundColor = colors.black,
}

Label = {}

function Label:new(text,x,y,textColor)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self
	
	o.text = tostring(text) or ""
	o.x = x or 0
	o.y = y or 0
	o.textColor = textColor or default.textColor
	
	return o
end

function Label:getTextColor()
	return self.textColor
end

function Label:setTextColor(color)
	self.textColor = color
end
function Label:setPos(x,y)
	self.x = x
	self.y = y
end

function Label:setText(text)
	self.text = tostring(text)
end
function Label:getText()
	return self.text
end
function Label:redraw()
	if self.monitor and self.visible then
		self.monitor:drawText(self.x, self.y, self:getText(), self.textColor)
	end
end