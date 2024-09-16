function Miner:aStarSLOW(startPos, startOrientation, goal, nodes, checkValidNodeFunc)
	local closedSet = {}
	local openSet = { { pos = startPos, orientation = startOrientation } }
	local predecessors = {}
	
	if checkValidNodeFunc then self.checkValidNode = checkValidNodeFunc end
	
	local gScore, fScore = {}, {}
	local strPosStart = self:posToString(startPos)
	gScore[strPosStart] = 0
	fScore[strPosStart] = gScore[strPosStart] + self:calculateHeuristic(startPos,goal)
	
	local i = 0
	local logBook = {}
	
	while #openSet > 0 do
		i = i + 1
		
		-- problem: removeNode, findNode, getLowestScore
		
		local current = self:getLowestScore(openSet, fScore)
		table.insert(logBook, tostring(current.pos))
		
		if current.pos == goal then 
			local path = self:reconstructPath( {}, predecessors, goal)
			table.insert(path,goal)
			print("FOUND PATH, MOVES:", #path, "ITERATIONS:", i)
			
			
			
			return path
		end
		
		self:removeNode(openSet, current)
		table.insert(closedSet, current)
		
		local neighbours = self:getNeighbours(current, nodes)
		for _, neighbour in ipairs(neighbours) do
			--table.insert(logBook, "nei " .. tostring(neighbour.pos))
			if not self:findNode(closedSet, neighbour) then
				local strPosNeighbour = self:posToString(neighbour.pos)
				local tentativeGScore = gScore[self:posToString(current.pos)] + self:calculateCost(current,neighbour)
				local notInOpenSet = ( self:findNode(openSet, neighbour) == false )
				
				if notInOpenSet == true or tentativeGScore < gScore[strPosNeighbour] then
					predecessors[strPosNeighbour] = current.pos --add orientation if needed
					gScore[strPosNeighbour] = tentativeGScore
					fScore[strPosNeighbour] = gScore[strPosNeighbour] + self:calculateHeuristic(neighbour.pos,goal)
					if notInOpenSet == true then
						table.insert(openSet, neighbour)
					end
				end
			end
		end
		if i > 1000000 then
			print("NO PATH FOUND")
			return nil
		end
	end
	return nil
end
--############################################
function Miner:aStarFAST(startPos, startOrientation, finishPos, map, checkValidNodeFunc)

	if checkValidNodeFunc then self.checkValidNode = checkValidNodeFunc end

	local start = { pos = startPos, orientation = startOrientation }
	local finish = { pos = finishPos }
	
	start.gScore = 0
	start.hScore = self:calculateHeuristic(start.pos, finish.pos)
	start.fScore = start.hScore
	
	local open = Heap()
	local closed = {}
	open.Compare = function(a,b)
		return a.fScore < b.fScore
	end
	open:Push(start)
	
	local logBook = {}
	
	
	local ct = 0
	
	while not open:Empty() do
		ct = ct + 1
		
		local current = open:Pop()
		
		local currentId = self:posToId(current.pos)
		if not closed[currentId] then
			if current.pos == finish.pos then
				local path = {}
				while true do
					if current.previous then
						table.insert(path, 1, current)
						current = current.previous
					else
						table.insert(path, 1, start)
						print("FOUND PATH, MOVES:", #path, "ITERATIONS:", ct)
						return path
					end		
				end
			end
			closed[currentId] = true
			--print(current.pos, current.gScore, current.hScore, current.fScore)
			
			--works BUT neighbours does not work properly because when having the same "neighbour" the addresses are different.
			--must create connection with map! -> store 
				
			local neighbours = self:getNeighbours(current, map)
			for i=1, #neighbours do
				local neighbour = neighbours[i]				
				if not closed[self:posToId(neighbour.pos)] then
					local addedGScore = current.gScore + self:calculateCost(current,neighbour)					
					if not neighbour.gScore or addedGScore < neighbour.gScore then
						neighbour.gScore = addedGScore
						
						if not neighbour.hScore then
							neighbour.hScore = self:calculateHeuristic(neighbour.pos,finish.pos)
						end
						neighbour.fScore = addedGScore + neighbour.hScore

						open:Push(neighbour)
						neighbour.previous = current
					end
				end
			end
		end
		if ct > 1000000 then
			print("NO PATH FOUND")
			return nil
		end
		if ct%10000 == 0 then
			--print(ct) -- to avoid timeout
			sleep(0.001)
		end
	end
	return nil
	--https://github.com/GlorifiedPig/Luafinding/blob/master/src/luafinding.lua
	-- noch besser ? https://www.love2d.org/wiki/Jumper
end

function Miner:findNode(set, fNode)
	for _, node in ipairs(set) do
		if node.pos == fNode.pos then 
			return true
		end
	end
	return false
end

function Miner:removeNode(set, rNode)
	for i, node in ipairs(set) do
		if node == rNode then 
			set [ i ] = set [ #set ] --move last entry to current to avoid holes
			set [ #set ] = nil
			break
		end
	end	
end
function Miner:getLowestScore(set,fScore)
	-- performance ... Fibonacci Heap besser
	local minScore, minNode = math.huge, nil
	for _, node in ipairs(set) do
		local score = fScore[self:posToString(node.pos)]
		if score < minScore then
			minScore = score
			minNode = node
		end
	end
	return minNode
end


function Miner:breadthFirstSearch(startPos, startOrientation, goal, nodes)
	-- optimal path for short distances, not weighted
	-- e.g. veinMine
	local queue = { { pos = startPos, orientation = startOrientation } }
    local explored = {}
	local predecessors = {}
	explored[self:posToString(startPos)] = true
	
	local i = 0

	while #queue > 0 do
		i = i + 1

		local current = table.remove(queue,1)
		if current.pos == goal then
			local path = self:reconstructPath( {}, predecessors, goal)
			table.insert(path,goal)
			print("FOUND PATH, MOVES:", #path, "ITERATIONS:", i)
			return path
		end
		
		local neighbours = self:getNeighbours(current, nodes)
		for _, neighbour in ipairs(neighbours) do
			local blockName = self:getMapValue(neighbour.pos.x, neighbour.pos.y, neighbour.pos.z)

			local strPosNeighbour = self:posToString(neighbour.pos)
			if not explored[strPosNeighbour] then --and (not map or map[strPosNeighbour]
				explored[strPosNeighbour] = true
				predecessors[strPosNeighbour] = current.pos
				table.insert(queue, neighbour)
			end
		end
		if i > 1000000 then
			print("NO PATH FOUND")
			return nil
		end
		if i%1000 == 0 then
			sleep(0.001)
		end
	end
	return nil
end