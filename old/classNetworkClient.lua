require("classList")

local default = {
	typeSend = 1,
	typeAnswer = 2,
	typeDone = 3,
	typeBroadcast = 4,
	typeRegister = 5,
	waitTime = 2,
}
--msg = { type, data, answer, task }

NetworkNode = {}

function NetworkNode:new(protocol)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self
	
	print("----INITIALIZING----")
	
	self.isHost = false
	self.protocol = protocol
	self.id = os.getComputerID()
	self.computers = {}
	self.host = nil
	
	self:initialize()
	print("--------------------")
	return self
end

--pseudo funcitons to be implemented by enduser
-- function NetworkNode:onReceive(sender,msg,protocol) end
-- function NetworkNode:onAnswer(sender,msg,protocol) end
-- function NetworkNode:onNoAnswer(sender,msg,protocol) end
-- function NetworkNode:onRequestAnswer(sender,msg,protocol) end

function NetworkNode:initialize()
	self:openRednet()
	
	self:hostProtocol()	
	self:lookupHost()
	self:notifyHost()
	print("myId:", self.id, "host:", self.host, "protocol:", self.protocol)
end

function NetworkNode:openRednet()
	if rednet.isOpen() then
		rednet.close()
	end
	peripheral.find("modem",rednet.open)
	assert(rednet.isOpen(),"no modem found")
end

function NetworkNode:notifyHost()
	--notify host that a new worker is available
	--could be replaced by regular lookups through host
	if self.host then
		if self.host >= 0 then
			local answerMsg = self:send(self.host, {"REGISTER"}, true)
			assert(answerMsg, "no host found")
		end
	end
end

function NetworkNode:hostProtocol()
	rednet.host(self.protocol, tostring(self.id))
end

function NetworkNode:setProtocol(protocol)
	if self.protocol then
		rednet.unhost(self.protocol)
	end
	self:hostProtocol()
end

function NetworkNode:beforeReceive(sender,msg,senderProtocol)
	if msg.data[1] == "RUN" then
		shell.run(msg.data[2])
	elseif msg.data[1] == "REBOOT" then
		os.reboot()
	end
end


function NetworkNode:onDone(sender, msg, senderProtocol)
	--self.worklist:removeTask(taskId)
	--remove and forward to user defined funciton
	--if self.onDone then
	--	self.onDone()
	--end
	--TODO: worklist mit auftragsnummer status etc.
	--multiple protocol support für host
	--startup animation "setting up rednet" etc.
	
end

function NetworkNode:listen(waitTime)
	local sender, msg, senderProtocol = rednet.receive(self.protocol,waitTime)
	if msg then
		self:handleMessage(sender,msg,senderProtocol)
	else
		if self.onNoAnswer then
			self.onNoAnswer()
		end
	end
	return msg
end
function NetworkNode:handleEvent(event)
	if event and event[1] == "rednet_message" then
		--local name, sender, msg, senderProtocol = event
		self:handleMessage(event[2],event[3],event[4])
	end
end

function NetworkNode:handleMessage(sender,msg,senderProtocol)
	if senderProtocol == self.protocol and msg then
		if msg.answer then
			if self.onRequestAnswer then
				--special handler exists
				self.onRequestAnswer(sender,msg,senderProtocol)
			else
				self:answer(sender,{"RECEIVED"},msg.task)
			end
		end
		
		if msg.type == default.typeSend or msg.type == default.typeBroadcast then
			self:beforeReceive(sender,msg,senderProtocol)
			if self.onReceive then
				self.onReceive(sender,msg,senderProtocol)
			end
		elseif msg.type == default.typeAnswer then
			if self.onAnswer then 
				self.onAnswer(sender,msg,senderProtocol)
			end
		elseif msg.type == default.typeDone then
			--not yet implemted
			--callback if task is done
			if self.onDone then
				self:onDone(sender,msg,senderProtocol)
			end
		elseif msg.type == default.typeRegister then
			if self.registerNode then
				self:registerNode(sender,msg,senderProtocol)
			end
		end
		
		--DOESNT WORK PROPERLY!
		--new variable msg.done for requesting done event?
		if msg.answer then 
			if self.onRequestDone then
				--special handler exists
				self.onRequestDone(sender,msg,senderProtocol)
			else
				self:sendDone(sender,{"DONE"},msg.task)
			end
		end
	--elseif senderProtocol == "dns" then
		--new friend
	end
end
		
function NetworkNode:sendDone(sender,data,answer)
	self:send(sender, data, default.typeDone, answer)
end

function NetworkNode:answer(sender,data,answer)
	rednet.send(sender, data, default.typeAnswer, false)
end

function NetworkNode:send(recipient,data,typ,answer)
	local retval
	if recipient ~= self.id then
		local msg = {}
		msg.type = typ
		msg.data = data
		msg.answer = answer
		rednet.send(recipient, msg, self.protocol)
		if answer then
			retval = self:listen(default.waitTime)
		end
	end
	return retval
end

function NetworkNode:broadcast(data,answer)
	local retval
	local msg = {}
	msg.type = default.typeBroadcast
	msg.data = data
	msg.answer = answer
	rednet.broadcast(msg, self.protocol)
	if answer then
		retval = self:listen(default.waitTime)
	end
	return retval
end

function NetworkNode:getHost()
	return self.host
end

function NetworkNode:lookupHost()
	self.host = rednet.lookup(self.protocol,"host") 
	return self.host
end

function NetworkNode:lookup()
	self.host = rednet.lookup(self.protocol,"host")
	self.computers = {rednet.lookup(self.protocol)}
end

function NetworkNode:close()
	rednet.unhost(self.protocol)
	if rednet.isOpen() then
		rednet.close()
	end
end