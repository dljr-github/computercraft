
package.path = package.path ..";../?/?.lua" .. ";../general/?.lua"
require("classChunkyMap")
local translation = require("blockTranslation")
local nameToId = translation.nameToId

local type = type

local tableconcat = table.concat
local function serializenew(chunk)
    local parts = {"return {"} -- Use a table to build the string
	local index = 1
	local txt
    for id, data in pairs(chunk) do

		local idtype, datatype = type(id), type(data)
		if idtype == "number" then 
			if datatype == "number" then 
				txt = "[".. id .. "] = " .. data .. ",\n"
			elseif datatype == "string" then
				txt = "[".. id .. "] = \"" .. data .. "\",\n"
			elseif datatype == "boolean" then
				txt = "[".. id .. "] = " .. tostring(data) .. ",\n"
			end
		else 
			if datatype == "number" then 
				txt = "[\"" .. id .. "\"] = " .. data .. ",\n"
			elseif datatype == "string" then
				txt = "[\"" .. id .. "\"] = \"" .. data .. "\",\n"
			elseif datatype == "boolean" then
				txt = "[\"" .. id .. "\"] = " .. tostring(data) .. ",\n"
			end
		end

        parts[index] = txt
		index = index + 1
    end
    parts[index] = "}"
    return tableconcat(parts) -- Concatenate all parts into a single string
end

local function serialize(chunk)
	local txt = "return {"
	for id, data in pairs(chunk) do
		local idtype, datatype = type(id), type(data)
		if idtype == "number" then 
			if datatype == "number" then 
				txt = txt .. "[".. id .. "] = " .. data .. ",\n"
			elseif datatype == "string" then
				txt = txt .. "[".. id .. "] = \"" .. data .. "\",\n"
			elseif datatype == "boolean" then
				txt = txt .. "[".. id .. "] = " .. tostring(data) .. ",\n"
			end
		else 
			if datatype == "number" then 
				txt = txt .. "[\"" .. id .. "\"] = " .. data .. ",\n"
			elseif datatype == "string" then
				txt = txt .. "[\"" .. id .. "\"] = \"" .. data .. "\",\n"
			elseif datatype == "boolean" then
				txt = txt .. "[\"" .. id .. "\"] = " .. tostring(data) .. ",\n"
			end
		end
	end
	return txt .. "}"
end

local function serialize2(chunk)
	local txt = "return {"
	for id, data in pairs(chunk) do
		txt = txt .. "[".. id .. "] = " .. data .. ",\n"
	end
	return txt .. "}"
end

local function unserialize2(data)
	local func = load(data)
	if func then 
		return func()
	end
end

local stringpack = string.pack
local stringunpack = string.unpack
local function serialize3(chunk)
	local data = ""
	local format = ">I2z" --int 2, string


	for id, value in pairs(chunk) do
		if type(id) == "number" then 
			data = data .. stringpack("zz", id, value)
		else
			data = data .. stringpack("zz", id, value)
		end
		--data = data .. string.pack("I4", id)
		--data = data .. string.pack("I4", value)
	end
	return data
end
local function unserialize3(data)

	local offset = 1
	local format = "zz" --int 2, string
	local chunk = {}
	print(data)
    while offset <= #data do
        local id, value
        id, value, offset = stringunpack(format, data, offset)
        chunk[id] = value
    end

	return textutils.serialize(chunk)
end

local function testChunkyMapPerformance()
    -- Create a new ChunkyMap instance
    local map = ChunkyMap:new(false)

    -- Define test parameters
    local iterations = 1000000 -- Number of operations to test
    local chunkSize = ChunkyMap.chunkSize
	local x,y,z = 2234, 72, -2664
    local testChunkId = map.xyzToChunkId(x,y,z)
	local relativeId = map.xyzToRelativeChunkId(x,y,z)
    local testData = "minecraft:stone"
	local translated = map:nameToId(testData)

    -- Pre-fill the chunk with some data
    --for x = 0, chunkSize - 1 do
    --    for y = 0, chunkSize - 1 do
    --        for z = 0, chunkSize - 1 do
    --            map:setData(x, y, z, testData, true)
    --        end
    --    end
    --end
	--local x = math.random(0, chunkSize - 1)
	--local y = math.random(0, chunkSize - 1)
	--local z = math.random(0, chunkSize - 1)

    -- Test setData performance
	
	local xyzToChunkId = map.xyzToChunkId
	local xyzToRelativeChunkId = map.xyzToRelativeChunkId

	local value = (nameToId[testData] or testData)
	local chunk = map:accessChunk(testChunkId,false, true)

	for id, data in pairs(chunk) do
		if type(id) ~= "number" then
			--chunk[id] = nil
		end
	end

	local textutilsserialize = textutils.serialize
	--print(textutilsserialize(chunk))
	local startSet = os.epoch("local")
    for i = 1, iterations do
		--txt = serialize(chunk)
    end
    local endSet = os.epoch("local")
    print("serialize Performance:", iterations, "operations in", endSet - startSet, "ms")
	local ser = serialize(chunk)
	local startSet = os.epoch("local")
    for i = 1, iterations do
		--txt = unserialize2(ser)
    end
    local endSet = os.epoch("local")
    print("utils serialize Performance:", iterations, "operations in", endSet - startSet, "ms")



	local textutilsserialize = textutils.serialize
	local textutilsunserialize = textutils.unserialize
	local opts = {compact = true, allow_repetitions = true }
	local startSet = os.epoch("local")
    for i = 1, iterations do
		--txt = textutils.serialize(chunk,opts)
    end
    local endSet = os.epoch("local")
    print("serialize Performance:", iterations, "operations in", endSet - startSet, "ms")
	local ser = textutilsserialize(chunk)
	local startSet = os.epoch("local")
    for i = 1, iterations do
		--txt = textutilsunserialize(ser)
    end
    local endSet = os.epoch("local")
    print("utils serialize Performance:", iterations, "operations in", endSet - startSet, "ms")

	local startSet = os.epoch("local")
    for i = 1, iterations do
		local chunkId = xyzToChunkId(x,y,z)
		--local relativeId = xyzToRelativeChunkId(x,y,z)
    end

    local endSet = os.epoch("local")
    print("access Performance:", iterations, "operations in", endSet - startSet, "ms")

	


	local startSet = os.epoch("local")
    for i = 1, iterations do
        map:setChunkData(testChunkId,relativeId, translated, true)
    end
    local endSet = os.epoch("local")
    print("chunkData Performance:", iterations, "operations in", endSet - startSet, "ms")


    local startSet = os.epoch("local")
    for i = 1, iterations do
        map:setData(x, y, z, testData, true)
    end
    local endSet = os.epoch("local")
    print("setData Performance:", iterations, "operations in", endSet - startSet, "ms")

    -- Test getData performance
    local startGet = os.epoch("local")
    for i = 1, iterations do
        map:getData(x, y, z)
    end
    local endGet = os.epoch("local")
    print("getData Performance:", iterations, "operations in", endGet - startGet, "ms")
	print(#map.log)
end



-- Run the test
testChunkyMapPerformance()