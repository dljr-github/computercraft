
-- bluenet, a modified rednet for better performance


local bluenet = {

	default = {
		typeSend = 1,
		typeAnswer = 2,
		typeDone = 3,
		waitTime = 1,
		
		channels = {
			broadcast = 65401, 
			repeater = 65402,
			host = 65403,
			max = 65400
		}
	},
	--msg = { id, time, sender, recipient, protocol, type, data, answer, wait, distance}

	receivedMessages = {},
	receivedTimer = nil, -- does that work?
	osEpoch = os.epoch,
	opened = false,
	modem = nil,
	ownChannel = nil,
	computerId = os.getComputerID(),

	idAsChannel = function(id)
		return (id or os.getComputerID()) % default.channels.max
	end,

	findModem = function()
		for _,modem in ipairs(peripheral.getNames()) do
			if peripheral.getType(modem) == "modem" then
				return modem
			end
		end
		return nil
	end,

	open = function(modem)
		if not opened then 
			
			if not modem then
				print("NO MODEM")
				opened = false
			end
			peripheral.call(modem, "open", ownChannel)
			peripheral.call(modem, "open", default.channels.broadcast)
			print("opened",ownChannel,default.channels.broadcast)
			
		end
		opened = true
		return true
	end,

	close = function(modem)
		if modem then
			if peripheral.getType(modem) == "modem" then
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
	end,

	isOpen = function(modem)
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
	end,

	openChannel = function(modem, channel)
		if not isChannelOpen(modem, channel) then 
			if not modem then
				print("NO MODEM")
				return false
			end
			peripheral.call(modem, "open", channel)
			print("opened", channel)
		end
		return true
	end,

	closeChannel = function(modem, channel)
		if not modem then 
			print("NO MODEM", modem)
			return false
		end
		if isChannelOpen(modem, channel) then 
			return peripheral.call(modem, "close", channel)
		end
		return true
	end,

	isChannelOpen = function(modem, channel)
		if not modem then 
			print("NO MODEM", modem)
			return false
		end
		return peripheral.call(modem, "isOpen", channel)
	end,

	-- local functions perhaps outside bluenet? -> no apparently doesnt matter
	startTimer = os.startTimer,
	cancelTimer = os.cancelTimer,
	osClock = os.clock,
	timerClocks = {},
	timers = {},
	pullEventRaw = os.pullEventRaw,
	type = type,

	receive = function(protocol, waitTime)
		local timer = nil
		local eventFilter = nil
		
		-- CAUTION: if bluenet is loaded globally, 
		--	TODO:	the timers must be distinguished by protocol/coroutine
		-- 			leads to host being unable to reboot!!!
		
		if waitTime then
			local t = osClock()
			if timerClocks[waitTime] ~= t then 
				--cancel the previous timer and create a new one
				cancelTimer((timers[waitTime] or 0))
				timer = startTimer(waitTime)
				--print( protocol, "cancelled", timers[waitTime], "created", timer, "diff", timer - (timers[waitTime]or 0))
				timerClocks[waitTime] = t
				timers[waitTime] = timer
			else
				timer = timers[waitTime]
				--print( protocol, "reusing", timer)
			end
			
			eventFilter = nil
		else
			eventFilter = "modem_message"
		end
		
		--print("receiving", protocol, waitTime, timer, eventFilter)
		while true do
			local event, modem, channel, sender, msg, distance = pullEventRaw(eventFilter)
			--if event == "modem_message" then print(os.clock(),event, modem, channel, sender) end
			
			if event == "modem_message"
				--and ( channel == ownChannel or channel == default.channels.broadcast 
				--	or channel == default.channels.host ) 
				and type(msg) == "table" 
				--and type(msg.id) == "number" and not receivedMessages[msg.id]
				and ( type(msg.recipient) == "number" and msg.recipient
				and ( msg.recipient == computerId or msg.recipient == default.channels.broadcast 
					or msg.recipient == default.channels.host ) )
				and ( protocol == nil or protocol == msg.protocol )
				-- just to make sure its a bluenet message
				then
					msg.distance = distance
					-- event, modem, channel, replyChannel, message, distance
					--print("received", msg.id, msg.protocol)
					--receivedMessages[msg.id] = os.clock() + 9.5
					--resetTimer()
					--cancelTimer(timer)
					-- if osEpoch() > t then 
						-- print("cancel old timer")
						-- cancelTimer(timer)
					-- end
					return msg
					
			elseif event == "timer" then
				--print(os.clock(),event, modem, channel, sender, timer)
				
				if modem == timer then -- must be equal! >= geht nicht
					--print("returning nil")
					return nil
				end
			elseif event == "terminate" then 
				error("Terminated",0)
			end
			
		end
		
	end,

	resetTimer = function()
		if not receivedTimer then receivedTimer = os.startTimer(10) end
	end,

	clearReceivedMessages = function()
		receivedTimer = nil
		local time, hasMore = os.clock(), nil
		for id, deadline in pairs(receivedMessages) do
			if deadline <= now then receivedMessages[id] = nil
			else hasMore = true end
		end
		receivedTimer = hasMore and os.startTimer(10)
	end,

	modem = findModem(),
	ownChannel = idAsChannel(),

}
return bluenet