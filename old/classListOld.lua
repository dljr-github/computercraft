List = {
first,
last,
count,
}
function List:new(o)
    local o = o or {}
    setmetatable(o, {__index = self})
    self.__index = self
    o.first = nil
    o.last = nil
    o.count = 0
    return o
end

function List:clear()
    self.first = nil
    self.last = nil
    self.count = 0
end

function List:add(n)
    --assert(n)
    if self.first then
        self.first._prev = n
        n._next = self.first
        self.first = n
    else
        self.first = n
        self.last = n
        n._next = nil
        n._prev = nil
    end
    self.count = self.count + 1
	return n
end

function List:remove(n)
  	
	--assert(n)
    if n._next then
        if n._prev then
            n._next._prev = n._prev
            n._prev._next = n._next
        else
            assert(n == self.first)
            n._next._prev = nil
            self.first = n._next
        end
    else
        if n._prev then
            assert(n == self.last)        
            n._prev._next = nil
            self.last = n._prev -- n._next holy maccaroni
        else
			if n ~= self.first and n ~= self.last then	
				f = fs.open("trace.txt", "r")
				local text = ""
				if f then 
					text = f.readAll() 
					f.close()
				end
				
				f = fs.open("trace.txt", "w")
				f.write(text.." END")
				f.write(textutils.serialize(debug.traceback()))
				f.close()
				--print(debug.traceback())
				--error("asd")
			end
            assert(n == self.first and n == self.last)
            self.first = nil
            self.last = nil
        end
    end
    n._next = nil
    n._prev = nil
    self.count = self.count - 1
	--n = nil
    return n
end

function List:getFirst()
    return self.first
end
function List:getLast()
    return self.last
end

function List:getNext(n)
    if n then
        return n._next
    else
        return self.first
    end
end
function List:getPrev(n)
    if n then
        return n._prev
    else
        return self.last
    end
end   

function List:toString()
	local text = ""
	node = self:getFirst()
	while node do
		text = text .. ":" .. textutils.serialize(node[1])
		node = self:getNext(node)
	end
	return text
end

function List:moveToFront(n)
	-- for least recently used functionality. not used
	if n == self.first then
		return
	end
	if n._prev then
		n._prev._next = n._next
	end
	if n._next then
		n._next._prev = n._prev
	end
	if n == self.last then
		self.last = n._prev
	end
	self.count = self.count - 1
	return self:add(n)
end