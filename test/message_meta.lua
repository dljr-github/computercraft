
package.path = package.path ..";../runtime/?.lua"

os.loadAPI("general/bluenet.lua")
require("classBluenetNode")

local tinsert = table.insert

local node = NetworkNode:new("test", true)

local data = {}
		for k = 1, 500 do
			data[k] = tostring(k)
		end
--data = nil
local ct = 0

local buf = data
buf[0] = 500
local bufCount = 0

local turt = { buf = buf }
--print(#buf)
node.onStreamMessage = function(msg,previous)
	local data = msg.data	
	
	-- buf = msg.data
	
	local buf = turt.buf
	--local turt = turt
	for i=1, #data do
		
		--buf[0] = buf[0] + 1
		--buf[buf[0]] = data[i]
		--buf[#buf+1] = data[1]
		--bufCount = bufCount + 1
		--buf[bufCount] = data[i]
		buf[i] = data[i]
		--table.insert(buf, data[i])
	end

	
end


node.onRequestStreamData = function(previous)
	--print("requested data")
	local data = {}
	
	data = buf
	turt.buf = {}
	bufCount = 0
	buf[0] = 0
	
	
	return data
end

local function send()
	local ct = 0
	for a = 1, 10 do
		

		ct = ct + 1
		local start = os.epoch("local")
		for i = 1, 1000 do

			node:send(65,{"TEST", data},true,true,3)
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
		
		ct = ct + 1
		local start = os.epoch("local")
		node:openStream(65, 6)
		for i = 1, 1000 do
			node:stream()
			node:listen()
		end
		local t = os.epoch("local")-start
		print(ct, "stream", t/1000, #buf)
	end
end



local messageFields = { 
	id = 1, 
	time = 2, 
	sender = 3, 
	recipient = 4, 
	protocol = 5, 
	type = 6, 
	data = 7, 
	answer = 8, 
	wait = 9, 
	waitTime = 10 
}

local msg_mt = {
   __index = function(t, key)
      return t[messageFields[key]]
   end
}

local function createMessage(...)
	local msg = { ... }
	setmetatable(msg, msg_mt)
	return msg
end
local function setMessageMetatable(msg)
	setmetatable(msg, msg_mt)
	return msg
end

-- Usage
-- local msg = createMessage(self:generateUUID(), osEpoch(), self.id, recipient, subProtocol or self.protocol, default.typeSend, data, answer, wait, waitTime)
-- print(msg.id)  -- Access as if it had named fields

local ID, TIME, SENDER, RECIPIENT, PROTOCOL, TYPE, DATA, ANSWER, WAIT, WAITTIME = 1,2,3,4,5,6,7,8,9,10

local form = ">zLi3i3i3Bi3Bzz"
local pack = string.pack
local unpack = string.unpack
local tpack = table.pack
local tunpack = table.unpack

--local createPacket = function()
node.createPacket = function()
	local msg
	
	local createMessage = createMessage
	local start = os.epoch("local")
	for i = 1, 1000000 do
		
		msg = {
			12341243,
			start,
			234,
			2345,
			"protocol",
			2,
			{ "data" },
			true,
			false,
			5		
		}
		
		-- local vals = { msg[1],msg[2],msg[3],msg[4],
			-- msg[5],msg[6],msg[7],msg[8],msg[9],msg[10] }
		--local vals = { tunpack( packet) }
		
	end

	print(os.epoch("local")-start,"no index")
	print(#msg,table.unpack(msg))
	
	
	local start = os.epoch("local")
	for i = 1, 1000000 do
		local msg = { 
			id =  			12341243,
			time =  	    start,
			sender =  	    234,
			recipient =     2345,
			protocol =      "protocol",
			type =        	2,
			data =  	    { "data" },
			answer =  	    true,
			wait =  	    false,	
			waitTime =   	5
		}
		-- local vals = { msg.id, msg.time, msg.sender, msg.recipient, msg.protocol,
			-- msg.type, msg.data, msg.answer, msg.wait, msg.waitTime }
	end
	print(os.epoch("local")-start,"named")
	print(#msg,table.unpack(msg))
	
	
	local start = os.epoch("local")
	
		
	for i = 1, 1000000 do
		
		msg = {
			12341243,
			start,
			234,
			2345,
			"protocol",
			2,
			{ "data" },
			true,
			false,
			5		
		}
		--setmetatable(msg,msg_mt)
		-- msg.__index = function(t,key)
			-- return t[messageFields[key]]
		-- end
		-- msg = createMessage(
			-- 12341243,
			-- start,
			-- 234,
			-- 2345,
			-- "protocol",
			-- 2,
			-- { "data" },
			-- true,
			-- false,
			-- 5		
		-- )
		
		-- local vals = { msg.id, msg.time, msg.sender, msg.recipient, msg.protocol,
			 -- msg.type, msg.data, msg.answer, msg.wait, msg.waitTime }
		local vals = { msg[ID], msg[TIME], msg[SENDER], msg[RECIPIENT], msg[PROTOCOL],
			 msg[TYPE], msg[DATA], msg[ANSWER], msg[WAIT], msg[WAITTIME] }
	end
	print(os.epoch("local")-start,"metatable")
	local vals = { msg[ID], msg[TIME], msg[SENDER], msg[RECIPIENT], msg[PROTOCOL],
			 msg[TYPE], msg[DATA], msg[ANSWER], msg[WAIT], msg[WAITTIME] }
	print(#vals, table.unpack(vals))
	
	
	

	return packet 
end
local function unpackPacket(packet)
	print(string.unpack((form),packet))
	return string.unpack((form),packet)
end

--node.createPacket = createPacket
node.createPacket()
--_G.packet = createPacket()
--_G.vals = {unpackPacket(packet)}


--stream()