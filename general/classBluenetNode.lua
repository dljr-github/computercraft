require("classList")
local bluenet = require("bluenet")

local default = {
	typeSend = 1,
	typeAnswer = 2,
	typeDone = 3,
	typeStream = 4,
	
	waitTime = 1,
	lookupWaitTime = 2,
	
	emptyStreamThreshold = 30,
	
	channels = {
		broadcast = 65401, 
		repeater = 65402,
		host = 65403,
		max = 65400
	}
}
--msg = { id, time, sender, recipient, protocol, type, data, answer, wait }

local timer -- does that work?
local osEpoch = os.epoch
local mathRandom = math.random
local peripheralCall = peripheral.call

NetworkNode = {}
NetworkNode.__index = NetworkNode

function NetworkNode:new(protocol,isHost)
	local o = o or {}
	setmetatable(o, self)
	
	-- Function Caching
    for k, v in pairs(self) do
       if type(v) == "function" then
           o[k] = v  -- Directly assign method to object
       end
    end

	--print("----INITIALIZING----")
	
	o.isHost = isHost or false
	o.protocol = protocol
	o.id = os.getComputerID()
	o.computers = {}
	o.waitlist = List:new()
	o.streamlist = List:new()
	o.streams = {}
	o.host = nil
	o.events = List:new()
	o.messages = List:new()
	
	o.opened = false
	o.channel = nil
	o.modem = nil

	o:initialize()
	--print("--------------------")
	return o
end

function NetworkNode:initialize()
	self.channel = self:idAsChannel()
	self.modem = bluenet.findModem()
	self:openBluenet()
	self:lookupHost(2, 3)
	print("myId:", self.id, "host:", self.host, "protocol:", self.protocol)
end

function NetworkNode:idAsChannel(id)
	local id = id or self.id
	if id ~= default.channels.broadcast and id ~= default.channels.host then
		return id % default.channels.max
	else
		return id
	end
end

function NetworkNode:openBluenet()
	self.opened = bluenet.open(self.modem)
	assert(bluenet.isOpen(),"no modem found")
	self:hostProtocol()	
	
	-- temporary for rednet lookup
	if rednet then 
		peripheral.find("modem", rednet.open)
		if self.isHost then 
			rednet.host(self.protocol, "host")
		end
	end
	
end
function NetworkNode:notifyHost()
	--notify host that a new worker is available
	--could be replaced by regular lookups through host
	if self.host then
		local answerMsg = self:send(self.host, {"REGISTER"}, true, true)
		assert(answerMsg, "no host found")
	end
end

function NetworkNode:hostProtocol()
	if self.isHost then
		local host = self:lookup(self.protocol,"host",1)
		if host then 
			print("protocol already hosted by", host, self.protocol)
		end
		bluenet.openChannel(self.modem, default.channels.host)
		-- TODO: notify protocol members so they can set their host if its nil
	end
end

function NetworkNode:unhostProtocol()
	-- host and unhost is not really protocol specific
	bluenet.closeChannel(self.modem, default.channels.host)
end

function NetworkNode:setProtocol(protocol)
	if self.protocol then
		self:unhostProtocol()
	end
	self.protocol = protocol
	self:hostProtocol()
end

function NetworkNode:getHost()
	return self.host
end

function NetworkNode:lookupHost(tries, waitTime)
	if self.isHost then 
		self.host = self.id
	else 
		if not tries then tries = 1 end
		local ct = 0
		repeat 
			self.host = self:lookup(self.protocol,"host", waitTime)
			ct = ct + 1
		until self.host or ct >= tries -- increase, if host is not found reliably
		-- TODO: give up and use stream open to wait for a host, then reboot
	end
	return self.host
end

function NetworkNode:lookup(protocol, name, waitTime)
	
	if not protocol or not name then 
		print("lookup, no protocol or name supplied", protocol, name)
		return nil
	end
	--print("lookup", protocol, name, waitTime)
	local answer, forMsg = self:send(default.channels.host, { "LOOKUP", name }, true,true, 
		waitTime or default.lookupWaitTime, protocol)
	if answer and answer.data[1] == "LOOKUP_RESPONSE" and answer.data[2] == name then
		--print(answer.data[1], answer.sender)
		return answer.sender 
	else
		--print(answer and answer.data[1], answer and answer.data[2], answer and answer.recipient, "lookup fail")
		return nil
	end
end


function NetworkNode:beforeReceive(msg)
	--if msg.data[1] == "RUN" then -- from now on, RUN is handled by the receiver
	--	shell.run(msg.data[2])
	--else

	if msg.data[1] == "LOOKUP" then
		--print(msg.data[1], msg.data[2], self.isHost, self.id, msg.protocol, self.protocol, msg.id)
		if self.isHost and msg.data[2] == "host" then 
			self:answer(msg, { "LOOKUP_RESPONSE", "host" })
		elseif msg.data[2] == self.id then --or msg.data[2] == self.label
			self:answer(msg, { "LOOKUP_RESPONSE", self.id })
		end
		return true
	elseif msg.data[1] == "REBOOT" then
		os.reboot()
	elseif msg.data[1] == "SHUTDOWN" then
		os.shutdown()
	end
	return nil
end

function NetworkNode:beforeSend(msg)
	-- add original message to waitlist
	if msg.answer and not msg.wait then
		self.waitlist:addFirst(msg)
	end
end

function NetworkNode:generateUUID()
	-- local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
	-- local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
	-- return string.gsub(template, '[xy]', function (c)
		-- local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
		-- return string.format('%x', v)
	-- end)	
	return mathRandom(1,2147483647)
end

function NetworkNode.checkValid(msg,waitTime)
	if (osEpoch() - msg.time)/(72000) > ( waitTime or msg.waitTime or default.waitTime) then
		--print("invalid", (osEpoch()-msg.time)/72000,msg.data[1], waitTime, msg.waitTime, osEpoch()/72000, msg.time/72000)
		return false
	end
	return true
end
local checkValid = NetworkNode.checkValid

function NetworkNode:findMessage(uuid)
	-- find original message to answer to
	-- more likely to be the oldest rather than the newest
	local msg = self.waitlist.last
	while msg do
		if msg.id == uuid then
			return msg
		end
		msg = msg._prev
	end
	return nil
end


function NetworkNode:addEvent(event)
	self.events:addFirst(event)
end

function NetworkNode:checkEvents()
	-- check all events, oldest first
	local event = self.events.last
	while event do
		local prv = self.events:removeLast(event)
		self:handleEvent(event)
		event = prv
	end
	self:checkWaitList()
end

function NetworkNode:handleEvent(event)
	if event and event[1] == "modem_message" then
		-- event, side, channel, replyChannel, message, distance
		event[5].distance = event[6]
		self:handleMessage(event[5])
	end
end

function NetworkNode:addMessage(msg)
	self.messages:addFirst(msg)
end

function NetworkNode:checkMessages()
	-- check all messages, oldest first
	local msg = self.messages.last
	while msg do
		local prv = self.messages:removeLast(msg)
		self:handleMessage(msg) -- potentially adds msg to another list
		msg = prv
	end
	self:checkWaitList()
end

function NetworkNode:handleMessage(msg)
	if msg then 
		--print(msg.type, msg.data and msg.data[1], msg.wait)
		
		if self:beforeReceive(msg) then 
			return
		end
		
		
		if msg.type == default.typeSend then
			if msg.answer then
				if self.onRequestAnswer then
					--special handler exists
					self.onRequestAnswer(msg)
				else 
					self:answer(msg,{"RECEIVED"})
				end
			end
			if self.onReceive then
				self.onReceive(msg)
			end
			
		elseif msg.type == default.typeAnswer then
			if not msg.wait then 
				-- check if the message that requested this answer is outdated
				local original = self:findMessage(msg.id)
				if original then
					self.waitlist:remove(original)
					if checkValid(original) then
						if self.onAnswer then 
							self.onAnswer(msg,original)
						end
					end
				else
					-- if self.onNoAnswer then
						-- self.onNoAnswer(nil)
					-- end
					-- discard the answer message
				end
			else
				-- msg is being waited for synchronously, do not handle here
			end
			
		elseif msg.type == default.typeStream then
		
			local previous = self:findMessage(msg.id)
			-- if msg.sender == 16 or msg.sender == 0 then 
			-- print(osEpoch()/72000, msg.id, not(not self.streams[msg.id]),
					-- msg.sender, msg.data[1], 
					-- previous and previous.id, previous and previous.time/72000,
					-- previous and previous.data[1])
			-- end
			if previous then 
				self.waitlist:remove(previous)
				
				if checkValid(previous) and self.streams[msg.id] then 
					--print(os.epoch("local"),"STREAM", msg.data[1], msg.waitTime)
					self.streamlist:addFirst(msg) -- continue the streaming cycle
					if self.onStreamMessage then
						self.onStreamMessage(msg,previous)
					end
					
				else
					-- stream broken
					print(os.epoch("local")/1000, "STREAM BROKEN", msg.id, msg.sender, "previous invalid")
					self.streams[msg.id] = nil
					
					if self.onStreamBroken then
						self.onStreamBroken(msg.id, msg.sender) -- discard the current answer
					end
				end
				
			else
				if msg.data[1] == "STREAM_OPEN" then
					self.streams[msg.id] = { id=msg.id, partner=msg.sender ,waitTime=msg.waitTime,protocol=msg.protocol }
					--local answer = self:sendStream(msg.sender,{"STREAM_OK"},msg.id,false,msg.waitTime,msg.protocol )
					local answer = self:answer(msg,{"STREAM_OK"})
					answer.waitTime = msg.waitTime
					answer.type = default.typeStream
					self.waitlist:addFirst(answer)
					print("STREAM REQUEST", msg.sender, msg.id, answer.data[1])
				else
					self.streams[msg.id] = nil
					print(os.epoch("local")/1000, "STREAM BROKEN", msg.id, msg.sender, "no previous", msg.data[1])
					if self.onStreamBroken then
						self.onStreamBroken(msg.id, msg.sender) -- discard the current answer
					end
				end
			end
		end
	end
end


function NetworkNode:checkWaitList()
	-- regularly check this list to trigger onNoAnswer events
	local msg = self.waitlist.last
	while msg do
		if not checkValid(msg) then
			self.waitlist:remove(msg)
			if msg.type == default.typeSend then 
				if self.onNoAnswer then
					self.onNoAnswer(msg)
				end
			elseif msg.type == default.typeStream then
				self.streams[msg.id] = nil
				print(os.epoch("local")/1000,"STREAM BROKEN", msg.id, msg.recipient, "timed out", msg.waitTime)
				if self.onStreamBroken then
					self.onStreamBroken(msg.id, msg.recipient)
					-- reopen stream? -> must be handled by client
				end
			end
				-- do something to let the send know the stream was broken
		end
		msg = msg._prev 
	end
end

function NetworkNode:listenForAnswer(forMsg,waitTime)
	-- ONLY FOR INTERNAL USE
	local startTime = osEpoch()
	local msg
	--print(osEpoch(),"waiting", forMsg.protocol,forMsg.id,waitTime)
	repeat 
		--print(osEpoch(),"waiting for a better life?")
		msg = bluenet.receive(forMsg.protocol,waitTime)
		--print(msg.id, msg.data[1], msg.protocol,waitTime)
		if msg then 
			if msg.id == forMsg.id then
				--self.waitlist:remove(forMsg)
				--print(msg.id, msg.data[1], msg.protocol,waitTime)
				break
			else
				-- print("different", forMsg.protocol, forMsg.id, forMsg.data[1])
				-- different message
				-- do not handle other messages, it came to the error below
				-- self:handleMessage(sender,msg,distance)
				--print("different answer", msg.sender, msg.protocol, msg.id, msg.data[1], forMsg.id, forMsg.data[1])
				msg = nil
				--forMsg = nil
			end
		else
			--print("fallback, no answer")
			--self.waitlist:remove(forMsg) -- this could trigger errors if it has already been removed from the list OR because its not the same table as when it was inserted
			--if self.onNoAnswer then
			--	self.onNoAnswer(forMsg)
			--end
			break
		end
		
		waitTime = waitTime - ( (osEpoch()-startTime)/72000 )
		
	until waitTime <= 0
	--print("done waiting", msg)
	if not msg then 
		if self.onNoAnswer then
			self.onNoAnswer(forMsg)
		else
			print("no answer", forMsg.id, forMsg.data[1])
		end
	end
	return msg, forMsg
end

function NetworkNode:listen(waitTime,subProtocol)
	-- listen for anything, not just answers
	--print("listening", waitTime, subProtocol or self.protocol)
	local msg = bluenet.receive(subProtocol or self.protocol,waitTime)
	--print("received", msg.data, msg.protocol, msg.id)
	if msg then
		self:handleMessage(msg)
	else
		self:checkWaitList()
	end
	return msg
end


function NetworkNode:answer(forMsg,data)
	local msg = {
		id = forMsg.id,
		time = osEpoch(),
		sender = self.id,
		recipient = forMsg.sender,
		protocol = forMsg.protocol or self.protocol,
		type = default.typeAnswer,
		data = data,
		--answer = false,
		wait = forMsg.wait,
	}
	
	
	--bluenet.resetTimer()
	local recipient = self:idAsChannel(msg.recipient)
	
	--print("answering",msg.sender,msg.recipient, recipient ,msg.id,msg.protocol)
	
	if self.opened then
		peripheralCall(self.modem, "transmit", recipient, self.channel, msg)
		-- needed?
		--peripheral.call(self.modem, "transmit", default.channels.repeater, self.channel, msg)
	end

	return msg
end


function NetworkNode:send(recipient,data,answer,wait,waitTime,subProtocol)
	if recipient ~= self.channel then
		-- TODO: add subProtocol as topic
		local msg = {
			--id = self:generateUUID(),
			id = mathRandom(1,2147483647),
			time = osEpoch(),
			sender = self.id,
			recipient = recipient,
			protocol = subProtocol or self.protocol,
			type = default.typeSend,
			data = data,
			answer = answer,
			wait = wait,
			waitTime = waitTime,
		}
		
		-- 2x faster to create tables without named variables
			-- self:generateUUID(),				-- id
			-- osEpoch(),						-- time
			-- self.id,							-- sender
			-- recipient,						-- recipient
			-- subProtocol or self.protocol,	-- protocol
			-- default.typeSend,				-- type
			-- data,							-- data
			-- answer,							-- answer
			-- wait,							-- wait
			-- waitTime,						-- waitTime
			
		-- to access the msg by index:
		-- local ID, TIME, SENDER, RECIPIENT, PROTOCOL, TYPE, DATA, ANSWER, WAIT, WAITTIME = 1,2,3,4,5,6,7,8,9,10

		-- local vals = { msg[ID], msg[TIME], msg[SENDER], msg[RECIPIENT], msg[PROTOCOL],
			 -- msg[TYPE], msg[DATA], msg[ANSWER], msg[WAIT], msg[WAITTIME] }
			 
			
		--print("sending", recipient, msg.id)
		
		self:beforeSend(msg)
		
		
		--bluenet.resetTimer()
		
		recipient = self:idAsChannel(recipient)
		
		if self.opened then
			peripheralCall(self.modem, "transmit", recipient, self.channel, msg)
			-- needed?
			--peripheral.call(self.modem, "transmit", default.channels.repeater, self.channel, msg)
		end

		if wait then
			-- wait for this exact answer
			return self:listenForAnswer(msg, waitTime or default.waitTime)
		else
			-- return the sent message
			return msg
		end
	end
	return nil
end

function NetworkNode:broadcast(data,answer)
	return self:send(default.channels.broadcast,data,answer,false)
end

function NetworkNode:receive(waitTime)
	-- TODO? statt bluenet.receive
end




function NetworkNode:close()
	bluenet.unhost(self.protocol)
	if bluenet.isOpen() then
		bluenet.close()
	end
end


-- pseudo stream functions
-- NetworkNode.onRequestStreamData(previousMessage)
-- NetworkNode.onStreamMessage(msg)
-- NetworkNode.onStreamBroken(previousMessage or nil)

function NetworkNode:hasStreamWith(computerId)
	for _,stream in pairs(self.streams) do
		if stream.partner == computerId then 
			return true
		end
	end
	return false
end

function NetworkNode:openStream(recipient,waitTime,subProtocol)
	
	if self:hasStreamWith(recipient) then 
		--print("STREAM ALREADY OPENED")
		return nil
	end
	
	local streamId = self:generateUUID()
	local answer = self:sendStream(recipient, { "STREAM_OPEN" }, streamId, 
		true, waitTime, subProtocol )
	if answer and answer.data[1] == "STREAM_OK" then
		print("OPENED STREAM", streamId, answer.id)
		answer.waitTime = waitTime
		self.streamlist:addFirst(answer)
		self.streams[streamId] = { id=answer.id, partner=answer.sender ,waitTime=waitTime, protocol=answer.protocol }
	else
		print("STREAM OPEN FAILED", streamId, answer and answer.data[1])
	end

	return answer
end

-- function NetworkNode:processStream()
	-- local msg = self.messages.last
	-- while msg do
		-- self.messages:remove(msg)
		-- self:handleMessage(msg)
		-- msg = msg._prev
		-- self.received = true
	-- end
	-- self:checkWaitList()
-- end

function NetworkNode:stream()
	-- implement in while true do loop 

	local previous = self.streamlist.last
	while previous do 
		self.streamlist:remove(previous)
		if self.streams[previous.id] then 
			-- only send if stream wasnt broken 
			
			local data = nil
			if self.onRequestStreamData then
				data = self.onRequestStreamData(previous)
				
			end
			--print(data.time)
			if not data or not data[1] then -- maybe remove second check
				if previous.data and previous.data[1] == "EMPTY_STREAM" then 
					if previous.data[2] >= default.emptyStreamThreshold then
						-- reopen stream in onRequestStreamData
						print("BROKE EMPTY STREAM", previous.id)
						self.streams[previous.id] = nil
						--print(textutils.serialize(self.streams))
					else
						data = { "EMPTY_STREAM", previous.data[2] + 1 }
					end
				else
					data = { "EMPTY_STREAM", 1}
				end
			end
			
			local msg = nil
			if data then 
				local start = osEpoch("local")
				msg = self:sendStream(previous.sender ,data, previous.id,
					false, previous.waitTime, previous.protocol)
				
				if osEpoch("local")-start > 50 then
					-- sleep / yield to allow processing answers
					sleep(0)
					--os.pullEvent(os.queueEvent("yield"))
				end
				
			end
		else
			print("STREAM DOES NOT EXIST", previous.id, previous.sender)
			-- break stream? onStreamBroken event? no, stream already broken
		end
		-- if not msg then 
			-- print("FAILED TO SEND STREAM")
		-- end
		
		previous = previous._prev
	end
		
end

function NetworkNode:sendStream(recipient,data,streamId,wait,waitTime,subProtocol)

	local msg = {
		id = streamId,
		time = osEpoch(),
		sender = self.id,
		recipient = recipient,
		protocol = subProtocol or self.protocol,
		type = default.typeStream, -- different types for open / close?
		data = data,
		wait = wait,
		waitTime = waitTime or default.waitTime
	}
	
	recipient = self:idAsChannel(recipient)
	
	if not wait then 
		self.waitlist:addFirst(msg)
	end
	
	if self.opened then
		peripheralCall(self.modem, "transmit", recipient, self.channel, msg)
	end
		
	if wait then 
		return self:listenForAnswer(msg, waitTime or default.waitTime)
	else
		return msg
	end
	
	return nil
	
end



-- function NetworkNode:closeStream(streamId)
	-- finish event queue and request close the next send stream
	-- trigger when streamresponse was not received in time
	-- needed? just dont answer and it will be closed by default
	-- TODO: yes it is needed sometimes
-- end


-- -- pseudo function for receiving messages
-- function Stream:receive()
	-- while true do
		-- msg = os.pullEvent()
		-- handler:addMessage(msg)
-- end

-- send -> receive -> process -> send