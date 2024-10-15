local PathFinder = {}
PathFinder.__index = PathFinder

local Heap = require("classHeap")
-- local SimpleVector = require("classSimpleVector")

local abs = math.abs

local default = {
	distance = 10,
}

local vectors = {
	[0] = {x=0, y=0, z=1},  -- 	+z = 0	south
	[1] = {x=-1, y=0, z=0}, -- 	-x = 1	west
	[2] = {x=0, y=0, z=-1}, -- 	-z = 2	north
	[3] = {x=1, y=0, z=0},  -- 	+x = 3 	east
}

local costOrientation = {
	[0] = 1, 	-- forward, up, down
	[2] = 1.75, -- back
	[-2] = 1.75, -- back
	[-1] = 1.5, -- left
	[3] = 1.5,	-- left
	[1] = 1.5,	-- right
	[-3] = 1.5,	-- right
}

local function checkValid(block)
	if block then return false
	else return true end
end


local function newPathFinder(template, checkValidFunc)
    return setmetatable( {
        checkValid = checkValidFunc or checkValid,
    }, template )
end


local function reconstructPath(current,start)
	local path = {}
	while true do
		if current.previous then
			current.pos = vector.new(current.x, current.y, current.z)
			table.insert(path, 1, current)
			current = current.previous
		else
			start.pos = vector.new(start.x, start.y, start.z)
			table.insert(path, 1, start)
			return path
		end		
	end
end


local function calculateHeuristic(cur,goal)
	--manhattan = orthogonal
	return abs(cur.x - goal.x) + abs(cur.y - goal.y) + abs(cur.z - goal.z)
	-- return math.sqrt((current.x-goal.x)^2 + (current.y+goal.y)^2 + (current.z+goal.z)^2)
end

local function getNeighbours(cur)
	local neighbours = {}
	
	-- forward
	local vector = vectors[cur.o]
	table.insert(neighbours, { x = cur.x + vector.x, y = cur.y + vector.y, z = cur.z + vector.z, o = cur.o })
	-- up
	table.insert(neighbours, { x = cur.x, y = cur.y+1, z = cur.z, o = cur.o })
	-- down
	table.insert(neighbours, { x = cur.x, y = cur.y-1, z = cur.z, o = cur.o })
	-- left
	vector = vectors[(cur.o-1)%4]
	table.insert(neighbours, { x = cur.x + vector.x, y = cur.y + vector.y, z = cur.z + vector.z, o = (cur.o-1)%4 })
	-- right
	vector = vectors[(cur.o+1)%4]
	table.insert(neighbours, { x = cur.x + vector.x, y = cur.y + vector.y, z = cur.z + vector.z, o = (cur.o+1)%4 })
	-- back
	vector = vectors[(cur.o+2)%4]
	table.insert(neighbours, { x = cur.x + vector.x, y = cur.y + vector.y, z = cur.z + vector.z, o = (cur.o+2)%4 })

	return neighbours
end


--KEEP COSTS LOW BECAUSE HEURISTIC VALUE IS ALSO SMALL IN DIFFERENCE

local function calculateCost(current,neighbour)
	
	local cost = costOrientation[neighbour.o-current.o]
	
	if neighbour.block then
		--block already explored
		if neighbour.block == 0 then
			-- no extra cost
		else
			-- if block is mineable is checked in checkValidNode -> not yet
			cost = cost + 0.75 -- 0.75 fastest
			-- WARNING: we dont neccessarily know which block comes after this one...
		end
	else
		-- it is unknown what type of block is here could be air, could be a chest
		-- SOLUTION -> recalculate path when it is blocked by a disallowed block
		cost = cost + 1.5 -- 1.5 fastest
	end
	return cost
end

function PathFinder:aStarPart(startPos, startOrientation, finishPos, map, distance)
	-- very good path for medium distances
	-- e.g. navigateHome
	-- start and finish must be free!

	-- miner = global.miner; miner:aStarPart(miner.pos,miner.orientation,vector.new(1,1,1),miner.map,500)
	
	-- evaluation x+50 empty map
		-- default: 			5270    5000, 5040, 5200, 5240,5520,5800 ct 30107
		-- neighbours:			4850	ct 30446
		-- xyzToId: 			4700-4950
		-- cost + heuristic 	4250
		-- gScore				2750 - 2950	open: 48231	closed:	77421
		-- fScore				2900		open: 48231	closed:	77421
		-- closed checkSafe		
		-- with vectors			3714, 3594, 3579, 3485, 3669
		-- simple vectors 		3381, 3439, 3327, 3300
		-- no map access : -650
		-- no vectors			2850
		-- no xyzToId			2650 -- nur für lange distanzen?
		
	local startTime = os.epoch("local")
	
	
	local checkValid = self.checkValid
	local map = map
	local distance = distance or default.distance
	
	local start = { x=startPos.x, y=startPos.y, z=startPos.z, o = startOrientation, block = 0 }
	local finish = { x=finishPos.x, y=finishPos.y, z=finishPos.z }
	
	local startBlock = map:getData(finish.x, finish.y, finish.z)
	if not checkValid(startBlock) then
		print("ASTAR: FINISH NOT VALID", startBlock)
		map:setData(finish.x, finish.y, finish.z, 0)
		-- overwrite current map value
	end
	
	local fScore = {}
	local gScore = {}

	gScore[start.x] = {}
	gScore[start.x][start.y] = {}
	gScore[start.x][start.y][start.z] = 0

	
	start.gScore = 0
	start.fScore = calculateHeuristic(start, finish)
	
	local closed = {}
	if not closed[start.x] then closed[start.x] = {} end
	if not closed[start.x][start.y] then closed[start.x][start.y] = {} end
	
	local open = Heap()
	open.Compare = function(a,b)
		return a.fScore < b.fScore
	end
	open:Push(start)
	
	local ct = 0
	local closedCount = 0
	local openCount = 0
	
	while not open:Empty() do
		ct = ct + 1
		
		local current = open:Pop()
		--logger:add(tostring(current.pos))
		
		--local currentId = xyzToId(current.x, current.y, current.z)
		--print(currentId)

		
		if not closed[current.x][current.y][current.z] then
			if current.x == finish.x and current.y == finish.y and current.z == finish.z
			or abs(current.x - start.x) + abs(current.y - start.y) + abs(current.z - start.z) >= distance then
				-- check if current pos is further than threshold for max distance
				-- or use time/iteration based approach
				
				local path = reconstructPath(current,start)
				print(os.epoch("local")-startTime, "FOUND, MOV:", #path, "CT", ct)
				--print("open neighbours:", openCount, "closed", closedCount)
				return path

			end
			closed[current.x][current.y][current.z] = true
			
			local neighbours = getNeighbours(current)
			for i=1, #neighbours do
				local neighbour = neighbours[i]
				
				--local neighbourId = xyzToId(neighbour.x, neighbour.y, neighbour.z)
				if not closed[neighbour.x] then 
					closed[neighbour.x] = {} 
					gScore[neighbour.x] = {}
				end
				if not closed[neighbour.x][neighbour.y] then 
					closed[neighbour.x][neighbour.y] = {} 
					gScore[neighbour.x][neighbour.y] = {}
				end
				
				if not closed[neighbour.x][neighbour.y][neighbour.z] then

					neighbour.block = map:getData(neighbour.x, neighbour.y, neighbour.z)
					if checkValid(neighbour.block) then
					
						openCount = openCount + 1
							
						local addedGScore = current.gScore + calculateCost(current,neighbour)
						neighbour.gScore = gScore[neighbour.x][neighbour.y][neighbour.z]
						if not neighbour.gScore or addedGScore < neighbour.gScore then
							gScore[neighbour.x][neighbour.y][neighbour.z] = addedGScore
							neighbour.gScore = addedGScore
							
							neighbour.hScore = calculateHeuristic(neighbour,finish)
							neighbour.fScore = addedGScore + neighbour.hScore
							
							open:Push(neighbour)
							neighbour.previous = current
							
							-- -- previous = current could result in very long chains
							-- -- perhaps use a table to store paths?
						end
						
					else
						-- path not safe
						-- close this id? TEST
						closed[neighbour.x][neighbour.y][neighbour.z] = true
					end
				else
					closedCount = closedCount + 1
				end
			end
		end
		if ct > 1000000 then
			print("NO PATH FOUND")
			return nil
		end
		if ct%10000 == 0 then
			--sleep(0.001) -- to avoid timeout
			os.pullEvent(os.queueEvent("yield"))
		end
		if ct%1000 == 0 then
			-- maybe yield for longer for other tasks to catch up
			--> seems to solve all problems -> test interval and duration
			--sleep(0.5)
			-- print(os.epoch("local")-startTime, ct)
		end
	end
	return nil
	--https://github.com/GlorifiedPig/Luafinding/blob/master/src/luafinding.lua
end


function PathFinder:aStarId(startPos, startOrientation, finishPos, map, distance)
	-- very good path for medium distances
	-- e.g. navigateHome
	-- start and finish must be free!

	-- miner = global.miner; miner:aStarPart(miner.pos,miner.orientation,vector.new(1,1,1),miner.map,500)
	
	-- evaluation x+50 empty map
		-- default: 			5270    5000, 5040, 5200, 5240,5520,5800 ct 30107
		-- neighbours:			4850	ct 30446
		-- xyzToId: 			4700-4950
		-- cost + heuristic 	4250
		-- gScore				2750 - 2950	open: 48231	closed:	77421
		-- fScore				2900		open: 48231	closed:	77421
		-- closed checkSafe		
		-- with vectors			3714, 3594, 3579, 3485, 3669
		-- simple vectors 		3381, 3439, 3327, 3300
		-- no map access : -650
		-- no vectors			2850
		
	local startTime = os.epoch("local")
	
	local xyzToId = map.xyzToId
	
	local checkValid = self.checkValid
	local map = map
	local distance = distance or default.distance
	
	
	local start = { x=startPos.x, y=startPos.y, z=startPos.z, o = startOrientation, block = 0 }
	local finish = { x=finishPos.x, y=finishPos.y, z=finishPos.z }
	
	local startBlock = map:getData(finish.x, finish.y, finish.z)
	if not checkValid(startBlock) then
		print("ASTAR: FINISH NOT VALID", startBlock)
		map:setData(finish.x, finish.y, finish.z,0)
		-- overwrite current map value
	end
	
	local fScore = {}
	local gScore = {}
	local startId = xyzToId(start.x,start.y,start.z)
	gScore[startId] = 0
	
	start.gScore = 0
	start.fScore = calculateHeuristic(start, finish)
	fScore[startId] = start.fScore
	
	local closed = {}
	
	local open = Heap()
	open.Compare = function(a,b)
		return a.fScore < b.fScore
	end
	open:Push(start)
	
	local ct = 0
	local closedCount = 0
	local openCount = 0
	
	while not open:Empty() do
		ct = ct + 1
		
		local current = open:Pop()
		--logger:add(tostring(current.pos))
		
		local currentId = xyzToId(current.x, current.y, current.z)
		--print(currentId)
		if not closed[currentId] then
			if current.x == finish.x and current.y == finish.y and current.z == finish.z
			or abs(current.x - start.x) + abs(current.y - start.y) + abs(current.z - start.z) >= distance then
				-- check if current pos is further than threshold for max distance
				-- or use time/iteration based approach
				
				local path = reconstructPath(current,start)
				--print(os.epoch("local")-startTime, "FOUND, MOV:", #path, "CT", ct)
				--print("open neighbours:", openCount, "closed", closedCount)
				return path

			end
			closed[currentId] = true
			
			local neighbours = getNeighbours(current)
			for i=1, #neighbours do
				local neighbour = neighbours[i]
				
				local neighbourId = xyzToId(neighbour.x, neighbour.y, neighbour.z)
				if not closed[neighbourId] then

					neighbour.block = map:getData(neighbour.x, neighbour.y, neighbour.z)
					if checkValid(neighbour.block) then
					
						openCount = openCount + 1
							
						local addedGScore = current.gScore + calculateCost(current,neighbour)
						neighbour.gScore = gScore[neighbourId]
						if not neighbour.gScore or addedGScore < neighbour.gScore then
							gScore[neighbourId] = addedGScore
							neighbour.gScore = addedGScore
							
							neighbour.hScore = calculateHeuristic(neighbour,finish)
							neighbour.fScore = addedGScore + neighbour.hScore
							
							open:Push(neighbour)
							neighbour.previous = current
							
							-- -- previous = current could result in very long chains
							-- -- perhaps use a table to store paths?
						end
						
					else
						-- path not safe
						-- close this id? TEST
						closed[neighbourId] = true
					end
				else
					closedCount = closedCount + 1
				end
			end
		end
		if ct > 1000000 then
			print("NO PATH FOUND")
			return nil
		end
		if ct%10000 == 0 then
			--sleep(0.001) -- to avoid timeout
			os.pullEvent(os.queueEvent("yield"))
		end
		if ct%1000 == 0 then
			-- maybe yield for longer for other tasks to catch up
			--> seems to solve all problems -> test interval and duration
			--sleep(0.5)
			-- print(os.epoch("local")-startTime, ct)
		end
	end
	return nil
	--https://github.com/GlorifiedPig/Luafinding/blob/master/src/luafinding.lua
end

return setmetatable( PathFinder, { __call = function( self, ... ) return newPathFinder( self, ... ) end } )