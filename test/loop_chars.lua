

local sub = string.sub
local char = string.char
local byte = string.byte

local str = "aasdfasdfasdfadfkuahdpqzu8jhdöfkajshdfoauiszdflaksdfhöladshfalsdhf"
local x = 100

local function subs(str)
	local chars = {}
	--local sub = string.sub
	local y = x-1
	for i = x, #str+y do 
		local p = i-y
		chars[i] = sub(str,p,p)
		chars[i] = sub(str,p,p)
		chars[i] = sub(str,p,p)
	end
	return chars 
end


local function chart(str)
	--local char = string.char
	local y = x-1
	local chars = {}
	local bytes = {byte(str, 1, #str)}
	for i = x, #bytes+y do 
		local p = i-y
		chars[i] = char(bytes[p])
		chars[i] = char(bytes[p])
		chars[i] = char(bytes[p])
	end
	return chars 
end

local function testSub()
	for j = 1, 5 do
		local start = os.epoch("local")
		for k = 1, 20000 do
			local chars = subs("hallo")
		end
		local t = os.epoch("local")-start
		print(t,"sub")
		sleep(0)
	end
end

local function testChar()
	for j = 1, 5 do
		local start = os.epoch("local")
		for k = 1, 20000 do
			local chars = chart("hallo")
		end
		local t = os.epoch("local")-start
		print(t,"char")
		sleep(0)
	end
end

testSub() -- 350 long string -- 41 short string 
testChar() -- 305 long string -- 48 short string