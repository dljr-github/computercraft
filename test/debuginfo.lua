
package.path = package.path ..";../runtime/?.lua"

require("classList")
local list = List:new()
local debuginfo = debug.getinfo

local function addTask(task)
	return list:addFirst(task)
end

local function testInfo()
	for j = 1, 5 do
		list = List:new()
		local start = os.epoch("local")
		for k = 1, 100000 do
			local info = addTask(debug.getinfo(1,"n"))
		end
		local t = os.epoch("local")-start
		print(t,"debug.getinfo")
	end
end

local function testChar()
	for j = 1, 5 do
		list = List:new()
		local start = os.epoch("local")
		for k = 1, 100000 do
			local info = addTask(debuginfo(1,"n"))
			--list:addFirst(debuginfo(1,"n"))
			
		end
		local t = os.epoch("local")-start
		print(t,"debuginfo")
	end
end

local function testPreset()
	for j = 1, 5 do
		list = List:new()
		local start = os.epoch("local")
		for k = 1, 100000 do
			local info = addTask({"preset"})
		end
		local t = os.epoch("local")-start
		print(t,"preset")
	end
end

--			 without addTask	with
testInfo()		--115			340	
testChar()		--90			310
testPreset()	--15			200