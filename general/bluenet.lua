
-- bluenet, a modified rednet for better performance

default = {
	typeSend = 1,
	typeAnswer = 2,
	typeDone = 3,
	waitTime = 1,
	
	channels = {
		broadcast = 65401, 
		repeater = 65402,
		max = 65400
	}
}
--msg = { id, time, sender, recipient, protocol, type, data, answer, wait, distance}

receivedMessages = {}
receivedTimer = nil -- does that work?
osEpoch = os.epoch
opened = false
modem = nil
ownChannel = nil
computerId = os.getComputerID()

function idAsChannel(id)
	return (id or os.getComputerID()) % default.channels.max
end

function findModem()
	for _,modem in ipairs(peripheral.getNames()) do
		if peripheral.getType(modem) == "modem" then
			return modem
		end
	end
	return nil
end

function open(modem)
	if not opened then 
		
		if not modem then
			print("NO MODEM")
			opened = false
		end
		peripheral.call(modem, "open", ownChannel)
		peripheral.call(modem, "open", default.channels.broadcast)
		print("opened",ownChannel,default.channels.broadcast,
		peripheral.call(modem, "isOpen", ownChannel),
		peripheral.call(modem, "isOpen", default.channels.broadcast), 
		"channel 0:", peripheral.call(modem, "isOpen", 0))
	
	end
	-- open rednet as well
	peripheral.find("modem",rednet.open)
	opened = true
	return true
end

function close(modem)
	if modem then
		if peripheral.getType(modem) == modem then
			peripheral.call(modem, "close", ownChannel)
			peripheral.call(modem, "close", default.channels.broadcast)
			opened = false
		end
	else
		for _,modem in ipairs(peripheral.getNames()) do
			if isOpen(modem) then
				close(modem)
			end
		end
	end
	rednet.close()
end

function isOpen(modem)
	if modem then
		if peripheral.getType(modem) == "modem" then
			return peripheral.call(modem, "isOpen", ownChannel)
				and peripheral.call(modem, "isOpen", default.channels.broadcast)
		end
	else
		for _,modem in ipairs(peripheral.getNames()) do
			if isOpen(modem) then
				return true
			end
		end
	end
	return false
end

function receive(protocol, waitTime)
	local timer = nil
	local eventFilter = nil
	
	if waitTime then
		timer = os.startTimer(waitTime)
		eventFilter = nil
	else
		eventFilter = "modem_message"
	end
	
	-- PROBLEM: infinitely receiving because the timer event was missed
	-- check >= timer 
	
	--print("receiving", protocol, waitTime, timer, eventFilter)
	while true do
		local event, modem, channel, sender, msg, distance = os.pullEvent(eventFilter)
		--if event == "modem_message" then print(event, modem,channel,sender,msg,distance) end
		--if event == "modem_message" then print(os.clock(),event, modem, channel, sender) end
		
		if event == "modem_message" 
			and ( channel == ownChannel or channel == default.channels.broadcast ) 
			and type(msg) == "table" 
			--and type(msg.id) == "number" and not receivedMessages[msg.id]
			and ( type(msg.recipient) == "number" and msg.recipient
			and ( msg.recipient == computerId or msg.recipient == default.channels.broadcast ) )
			and ( protocol == nil or protocol == msg.protocol )
			-- just to make sure its a bluenet message
			then
				msg.distance = distance
				-- event, modem, channel, replyChannel, message, distance
				--print("received", msg.id, msg.protocol)
				--receivedMessages[msg.id] = os.clock() + 9.5
				--resetTimer()
				return msg
				
		elseif event == "timer" then
			--print(os.clock(),event, modem, channel, sender, timer)
			if modem == timer then -- must be equal! >= geht nicht
				--print("returning nil")
				return nil
			end
		end
		
	end
	
end


-- use rednet for hosting related stuff
function host(protocol, hostName)
	return rednet.host(protocol, hostName)
end
function unhost(protocol)
	return rednet.unhost(protocol)
end
function lookup(protocol, hostName)
	--print(os.epoch("local")/1000,"lookup", protocol, hostName)
	return rednet.lookup(protocol, hostName)
end

function resetTimer()
	if not receivedTimer then receivedTimer = os.startTimer(10) end
end

function clearReceivedMessages()
	receivedTimer = nil
	local time, hasMore = os.clock(), nil
	for id, deadline in pairs(receivedMessages) do
		if deadline <= now then receivedMessages[id] = nil
		else hasMore = true end
	end
	receivedTimer = hasMore and os.startTimer(10)
end

modem = findModem()
ownChannel = idAsChannel()