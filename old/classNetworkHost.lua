require("classList")
require("classNetworkClient")


NetworkHost = {}

function NetworkHost:new(protocol)
	local o = o or NetworkClient:new(protocol) {}
	setmetatable(o,self)
	self.__index = self
	print("----INITIALIZING----")
	
	self.isHost = true
	self.worklist = List:new()
	self.currentTask = 0 --UUID generator alternativ
	
	self:initialize()
	print("--------------------")
	return self
end

function NetworkHost:initialize()
	--super initialization NetworkNode already done
	self.host = self.id
	
	rednet.unhost(self.protocol)
	self:hostProtocol()
end

function NetworkHost:hostProtocol()
	rednet.host(self.protocol, "host")
end

function NetworkHost:registerNode(sender, msg, senderProtocol)
	
end

-- task = { computerId, taskName, taskId, startTime, endTime }
function NetworkNode:addTask(computerId, taskName) 
	local task = { computerId = computerId, 
					taskName = taskName, 
					taskId = self.currentTask, 
					startTime = os.clock(), 
					endTime = 0 }
	self.currentTask = self.currentTask + 1
	self.worklist:add(task)
	--self:lookup(self.protocol, taskName)
	local msg = self:broadcast({"RUN", taskName},true)
	print("added task", task.taskName, task.taskId)
	return msg, task
end

function NetworkNode:removeTask(taskId)
	--remove task according to taskId because Lua does not reference variables well
	local task = self:findTask(taskId)
	if task then
		task = self.worklist:remove(task)
		task = nil
	end
	return task
end

function NetworkNode:findTask(taskId)
	local task = nil
	local current = self.worklist:getFirst()
	while current do
		if current.taskId == taskId then
			task = current
			break
		end
		current = self.worklist.getNext(current)
	end
	--print("found task:", task.taskId, task.taskName)
	return task
end

function NetworkNode:lookupHost()
	self.host = self.id 
	return self.host
end

function NetworkHost:lookup()
	self.host = self.id
	self.computers = {rednet.lookup(self.protocol)}
end