
package.path = package.path ..";../general/?.lua" --";../runtime/?.lua"

local required = require("bluenet")
os.loadAPI("old/bluenet.lua")
local bluenet = bluenet
require("classBluenetNode")

local tinsert = table.insert

local resetTimer = bluenet.resetTimer
NetworkNode.resetTimer = bluenet.resetTimer

local node = NetworkNode:new("test", true)
--node.resetTimer = bluenet.resetTimer


local computerId = os.getComputerID()
local protocol = "joo"
local eventFilter = "modem_message"
local pullEventRaw = os.pullEventRaw
local side = bluenet.findModem()


local function handle(event)
	local p1, p2, p3, msg, p5 = event[1], event[2], event[3], event[4], event[5]
	if --( p2 == ownChannel or p2 == channelBroadcast ) 
		type(msg) == "table"
		
		then 
			--local recipient = msg.recipient
			if ( msg.recipient and type(msg.recipient) == "number"
				and ( msg.recipient == computerId or msg.recipient == channelBroadcast
				or msg.recipient == channelHost ) )
			then
				msg.distance = p5
				local protocol = msg.protocol
				if protocol == "miner_stream" then
					--and ( not msg.data or msg.data[1] ~= "STREAM_OK" ) then
					node:handleMessage(msg)
					
				elseif protocol == "miner" or protocol == "chunk" then
					node:handleMessage(msg)
				end
			end
	elseif p1 == "terminate" then 
			error("Terminated",0)
	end
end

local function testBluenetVariants(node, iterations)
    local osEpoch = os.epoch -- Cache os.epoch for performance
    local startTime = osEpoch("utc") -- Start time for the test
    for i = 1, iterations do
		bluenet.resetTimer()
    end
    local endTime = osEpoch("utc") -- End time for the test
    print("local global", endTime - startTime, "ms for", iterations, "iterations")

	local startTime = osEpoch("utc") -- Start time for the test
    for i = 1, iterations do
		required.resetTimer()
    end
    local endTime = osEpoch("utc") -- End time for the test
    print("required", endTime - startTime, "ms for", iterations, "iterations")

	local startTime = osEpoch("utc") -- Start time for the test
    for i = 1, iterations do
		resetTimer()
    end
    local endTime = osEpoch("utc") -- End time for the test
    print("node", endTime - startTime, "ms for", iterations, "iterations")

	local event = {
		"modem_message",
		side,
		protocol,
		protocol,
		{
			protocol = protocol,
			sender = computerId,
			distance = 0,
			recipient = computerId,
			data = { "test" },
		},
		0
	}
	local msg = {
		protocol = protocol,
		sender = computerId,
		distance = 0,
		recipient = computerId,
		data = { "test" },
	}

	local startTime = osEpoch("utc") -- Start time for the test
    for i = 1, iterations do
		--node:handleMessage(msg)
		--node:handleEvent(event)
		handle(event)
    end
    local endTime = osEpoch("utc") -- End time for the test
    print("node", endTime - startTime, "ms for", iterations, "iterations")

end



testBluenetVariants(node, 10000000)
















local startTimer = os.startTimer
local cancelTimer = os.cancelTimer
local osClock = os.clock
local timerClocks = {}
local timers = {}
local pullEventRaw = os.pullEventRaw
local type = type

--local timings = { [protocol] = { clocks = {}, timers = {} }}
--timerClocks[protocol] = {}
--timers[protocol] = {}

local function timerTest(protocol, waitTime)
	local timer = nil
	local eventFilter = nil
	
	-- CAUTION: if bluenet is loaded globally, 
	--	TODO:	the timers must be distinguished by protocol/coroutine
	-- 			leads to host being unable to reboot!!!
	
	if waitTime then
		local t = osClock()
		--print(timerClocks[protocol])
		--local clocks, tmrs = timings[protocol].clocks, timings[protocol].timers
		local clocks, tmrs = timerClocks[protocol], timers[protocol]
		if not clocks then 
			clocks = {}
			tmrs = {}
			timerClocks[protocol] = clocks
			timers[protocol] = tmrs
		end
		if clocks[waitTime] ~= t then 
			--cancel the previous timer and create a new one
			cancelTimer((tmrs[waitTime] or 0))
			timer = startTimer(waitTime)
			print( protocol, "cancelled", timers[protocol][waitTime], "created", timer, "diff", timer - (timers[waitTime]or 0))
			clocks[waitTime] = t
			tmrs[waitTime] = timer
		else
			timer = tmrs[waitTime]
			--print( protocol, "reusing", timer)
		end
	end
end

local clocks = {}
local tmrs = {}

local function timerTestNormal(protocol, waitTime)
	local timer = nil
	local eventFilter = nil
	
	-- CAUTION: if bluenet is loaded globally, 
	--	TODO:	the timers must be distinguished by protocol/coroutine
	-- 			leads to host being unable to reboot!!!

	if waitTime then
		local t = osClock()
		--print(timerClocks[protocol])
		if clocks[waitTime] ~= t then 
			--cancel the previous timer and create a new one
			cancelTimer((tmrs[waitTime] or 0))
			timer = startTimer(waitTime)
			print( protocol, "cancelled", tmrs[waitTime], "created", timer, "diff", timer - (timers[waitTime] or 0))
			clocks[waitTime] = t
			tmrs[waitTime] = timer
		else
			timer = tmrs[waitTime]
			--print( protocol, "reusing", timer)
		end
	end
end



local function testTimerPerformance(iterations)
    local osEpoch = os.epoch -- Cache os.epoch for performance
    local startTime = osEpoch("utc") -- Start time for the test
	local protocol = protocol
    for i = 1, iterations do
		timerTest(protocol, 3) -- Call the timerTest function
    end

    local endTime = osEpoch("utc") -- End time for the test
    print("Test completed in", endTime - startTime, "ms for", iterations, "iterations")

	local startTime = osEpoch("utc") -- Start time for the test
    for i = 1, iterations do
		timerTestNormal(protocol, 3) -- Call the timerTest function
    end
    local endTime = osEpoch("utc") -- End time for the test
    print("Test completed in", endTime - startTime, "ms for", iterations, "iterations")

end

--testTimerPerformance(1000000)