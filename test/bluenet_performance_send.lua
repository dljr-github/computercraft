
package.path = package.path ..";../general/?.lua" --";../runtime/?.lua"

os.loadAPI("general/bluenet.lua")
require("classBluenetNode")

local tinsert = table.insert

local node = NetworkNode:new("test", true)

local data = {}
		for k = 1, 0 do
			data[k] = 2147483647 --tostring(k)
		end
--data = nil
local ct = 0

local buf = data
-- buf[0] = 500
local bufCount = 0

local turt = { buf = buf }



---################# RAW

local ID, TIME, SENDER, RECIPIENT, PROTOCOL, TYPE, DATA, ANSWER, WAIT, WAITTIME = 1,2,3,4,5,6,7,8,9,10
local DISTANCE = 11

local computerId = os.getComputerID()
local protocol = "test"
local eventFilter = "modem_message"
local pullEventRaw = os.pullEventRaw
local side = bluenet.findModem()

local native = term.native() -- to avoid peripheral.call
-- channels already opened by node 


local function receive()

	
	while true do
		local event, modem, channel, sender, msg, distance = pullEventRaw(eventFilter)
		if event == "modem_message"
			--type(msg) == "table" 
			-- and ( type(msg[4]) == "number" and msg[4]
			-- and ( msg[4] == computerId )
			-- and ( protocol == nil or protocol == msg[5] )
			then
				--msg.distance = distance
				--peripheral.call(side, "transmit", sender, channel, msg)
				-- for i=1, #msg do
					-- buf[i] = msg[i]
				-- end
				--print(channel, sender, #msg)
				
				return channel, sender, msg
				
				--return msg
				
		elseif event == "timer" then
			if modem == timer then
				return nil
			end
		elseif event == "terminate" then 
			error("Terminated",0)
		end
	end
	
end

local function rawSend()
	local perCall = peripheral.call
	for a = 1, 10 do
		local start = os.epoch("local")
		for i = 1, 10000 do
			--local data = buf
			--buf = {}
			perCall(side,"transmit",65,computerId,data)
			receive()
		end
		local t = os.epoch("local")-start
		print(a, "rawSend", t/1000)
	end	
end
	
--######################### ENDRAW



--print(#buf)
node.onStreamMessage = function(msg,previous)
	local data = msg.data	
	
	-- buf = msg.data
	
	--local buf = turt.buf
	--local turt = turt
	for i=1, #data do
		-- bufCount 0,71 1,23
		-- #buf+1	0,71 1,24
		-- insert 	0,84 1,50
		-- buf[0]	0,76 1,32
		-- tinsert		 1,31
		
		--buf[0] = buf[0] + 1
		--buf[buf[0]] = data[i]
		--buf[#buf+1] = data[1]
		--bufCount = bufCount + 1
		--buf[bufCount] = data[i]
		buf[i] = data[i]
		--table.insert(buf, data[i])
	end
	
	-- local entry = table.remove(data)
	-- while entry do
		-- table.insert(buf,entry)
		-- entry = table.remove(data)
	-- end
	
end


node.onRequestStreamData = function(previous)
	--print("requested data")
	local data = {}
	
	-- data = buf
	-- buf = {}
	-- local ct = #buf+1
	-- local buf = buf
	-- for i = #buf, 1, -1 do
		-- data[ct-i] = buf[i]
		-- buf[i] = nil
	-- end
	
	-- for i = 1, #buf do
		-- data[i] = buf[i]
		-- --buf[i] = nil
	-- end
	data = buf
	buf = {}
	--bufCount = 0
	--buf[0] = 0
	
	-- local entry = table.remove(buf)
	-- while entry do
		-- --print(entry)
		-- table.insert(data,entry)
		-- entry = table.remove(buf)
	-- end
	
	return data
end

local function send()
	local ct = 0
	node.streams = {}
	for a = 1, 10 do
		
		-- no data:		0,2 ms
		-- 500 data: 	0,5 ms
		
		local prvAnswer, prvMsg

		ct = ct + 1
		local start = os.epoch("local")
		for i = 1, 10000 do

			node:send(65,data,true,true,3) --, {"TEST",data}
			--local answer, forMsg = 
			-- if not answer then 
				-- print("no answer",i, prvAnswer.id, prvMsg.id, forMsg.id, forMsg.protocol)
			-- else
				-- prvAnswer = answer
				-- prvMsg = forMsg
			-- end
			--local answer = node:listen()
		end
		local t = os.epoch("local")-start
		print(ct, "send", t/1000)
	end
end

local function stream()
	node.streams = {}
	local ct = 0
	for a = 1, 10 do
		
		-- without buffer: 		0,6 ms
		-- with buffer insert:	1,04 ms
		-- with buffer set:		0,65 ms
		-- dual insert			1,53
		-- dual set				0,71
		
		ct = ct + 1
		
		local start = os.epoch("local")
		node:openStream(65, 6)
		for i = 1, 10000 do
			node:stream()
			node:listen()
		end
		local t = os.epoch("local")-start
		print(ct, "stream", t/1000, #buf)
	end
end

local form = ">zLi3i3i3Bi3Bzz"
local pack = string.pack
local unpack = string.unpack
local tpack = table.pack
local tunpack = table.unpack
local function createPacket()
	local packet
	
	-- way faster: 
	local start = os.epoch("local")
	for i = 1, 10000 do
		
		
		packet = {
			"label",
			start,
			-123,
			1234567,
			5000,
			255,
			100000,
			16,
			"task",
			"lastTask"
			}
		local vals = { packet[1],packet[2],packet[3],packet[4],
			packet[5],packet[6],packet[7],packet[8],packet[9],packet[10] }
		--local vals = { tunpack( packet) }
		
	end
	upack = function(packet)
		local label,time,x,y,z,orientation,fuel,slots,task,lastTask = tunpack(packet)
		return label,time,x,y,z,orientation,fuel,slots,task,lastTask
	end
		print(os.epoch("local")-start,"pack, unpack")
	print(#packet,table.unpack(packet))
	
	
	local start = os.epoch("local")
	for i = 1, 10000 do
		local msg = { 
			label = 		"label",
			time = 			start,
			x = 			-123,
			y = 			1234567,
			z = 			5000,
			orientation = 	255,
			fuel = 			100000,
			slots = 		16,
			task = 			"task",
			lastTask = 		"lastTask"
		}
		local vals = { packet[1],packet[2],packet[3],packet[4],
			packet[5],packet[6],packet[7],packet[8],packet[9],packet[10] }
	end
	print(os.epoch("local")-start,"named packet")
	print(#packet,table.unpack(packet))
	
	
	local start = os.epoch("local")
	for i = 1, 10000 do
		packet = pack((form),
			"label",
			start,
			-123,
			1234567,
			5000,
			255,
			100000,
			16,
			"task",
			"lastTask"
			)
		local vals = {unpack((form),packet)}
	end
	print(os.epoch("local")-start,"pack, unpack")
	print(#packet, "."..tostring(packet)..".")
	
	
	

	return packet 
end
local function unpackPacket(packet)
	print(string.unpack((form),packet))
	return string.unpack((form),packet)
end

--_G.packet = createPacket()
--_G.vals = {unpackPacket(packet)}

--rawSend()
--send()
stream()

-- no payload
-- raw: 	0,145  -- 0.140 no peripheralcall
-- send: 	0,185
-- stream:	0,225
-- newList+timers 0,165 (10% overhead)

-- payload costs:										time/number
-- no payload: 1850				0				
-- send 5 * max = 1860			10		1		0,5		2
-- send 50 * max = 2600			750		7,5		0,07	15
-- send 50 * max = 2100			240		2,4		0,21	4,8
-- send: 500 * max = 4500		2650	26,5	0,18	5,3
-- send: 5000 * max = 38200		36350	363,5	0,137	7,27

--> ~5,5ms per max number
--> 0,0005 ms / number 
--> 0,0005 ms / 8 bytes



-- 10000
-- raw: 0.370
-- send: 0.435
-- stream: 0.495