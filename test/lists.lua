package.path = package.path ..";../?/?.lua" .. ";../general/?.lua"

require("classList")
--require("classListNew")


-- local list = List:new()

-- local function addTask(task)
	-- return list:addFirst(task)
-- end
local runs = 5

-- local function testList()
	-- local sum = 0
	-- for j = 1, runs do
		-- local list = List:new()
		-- local start = os.epoch("local")
		-- for k = 1, 100000 do
			-- local n = list:addFirst({"preset"})
			-- --list:remove(n)
		-- end
		
		-- local n = list:getLast()
		-- while n do 
			-- local tmp = list:getPrev(n)
			-- list:remove(n)
			
			-- n = tmp
		-- end
		
		-- local t = os.epoch("local")-start
		-- print(t,"List")
		-- sum = sum + t
		-- sleep(0)
	-- end
	-- print("avg", sum/runs)
-- end

local function testListNew()
	local sum = 0
	for j = 1, runs do
		local list = List:new()
		local start = os.epoch("local")
		for k = 1, 100000 do
			local n = list:addFirst({"preset"})
			--list:remove(n)
		end
		
		-- local n = list.last
		-- while n do 
			-- --local tmp = n._prev
			-- list:remove(n) -- does not set ._prev to nil
			-- n = n._prev
		-- end
		local n = list.last
		while n do 
			--local prv = n._prev
			-- if prv then
				-- prv._next = nil
				-- list.last = prv
			-- else
				-- list.first = nil
				-- list.last = nil
			-- end
			-- list.count = list.count - 1
			-- n = prv
			local prv = list:removeLast(n)
			n = prv
			-- local prv = n._prev
			-- list:remove(n)
			-- n = prv
		end
		
		-- local n = list.last
		-- for i = 1, list.count do
			-- -- stuff
			-- n = n._prev
		-- end
		-- list:clear()
		
		local t = os.epoch("local")-start
		print(t,"ListNew")
		sum = sum + t
		sleep(0)
	end
	print("avg", sum/runs)
end

--			 	prepend 		remove	assert	if		count,clear 
--testList()		-- 128			320		
testListNew()	-- 118			212		247		222		135