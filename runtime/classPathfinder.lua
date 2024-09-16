require("classList")

PathFinder = {}

function PathFinder:new()
	local o = o or {}
	setmetatable(o,self)
	self.__index = self
	
	self:initialize()
	return self
end

function PathFinder:initialize()

end

function PathFinder:getLowestScore(set,fScore)
	-- performance ... Fibonacci Heap besser
	local minScore, minNode = INF, nil
	for _, node in ipairs(set) do
		local score = fScore[node]
		if score < minScore then
			minScore = score
			minNode = node
		end
	end
	return minNode
end

function PathFinder:reconstructPath ( flatPath, cameFrom, currentNode )
	-- doesnt have to be recursive ...
	if cameFrom[currentNode] then
		table.insert ( flatPath, 1, cameFrom[currentNode] ) 
		return reconstructPath( flatPath, cameFrom, cameFrom[currentNode] )
	else
		return flatPath
	end
end

function PathFinder:calculateHeuristic(current,goal)
--manhattan = orthogonal
h = abs(current.x – goal.x) + 
     abs(current.y – goal.y) +
	 abs(current.z - goal.z)
return h
-- --diagonal = 8 richtigungen mit grid
-- dx = abs(current – goal.x)
-- dy = abs(current – goal.y)
-- dz = abs(current.z - goal.z)
-- -- D = length of node (cost) ... 
-- -- D2 is diagonal distance = sqrt(2) <-- 2D
-- h = D * (dx + dy) + (D2 - 2 * D) * min(dx, dy)

--euclidian = omnidirektional (ohne grid)
end
function PathFinder:posToString(pos, orientation)
    if orientation then
        return pos.x .. ',' .. pos.y .. ',' .. pos.z .. ':' .. orientation
    else
        return pos.x .. ',' .. pos.y .. ',' .. pos.z
    end
end
function PathFinder:posFromString(str) end

--REWRITE GETBLOCK BECAUSE ITS RELATIVE 
function PathFinder:getBlockForward(current)
	local block = { pos = current.pos + self.vectors[current.orientation], orientation = current.orientation }
	return block
end
function PathFinder:getBlockUp(current)
	--if not current then current = { pos = self.pos, orientation = self.orientation } end
	local block = { pos = vector.new(current.pos.x, current.pos.y+1, current.pos.z), orientation = current.orientation }
	return block
end
function PathFinder:getBlockDown(current)
	local block = { pos = vector.new(current.pos.x, current.pos.y-1, current.pos.z), orientation = current.orientation }
	return block
end
function PathFinder:getBlockLeft()
	local block = { pos = current.pos + self.vectors[(current.orientation-1)%4], orientation = (current.orientation-1)%4 }
	return block
end
function PathFinder:getBlockRight()
	local block = { pos = current.pos + self.vectors[(current.orientation+1)%4], orientation = (current.orientation+1)%4 }
	return block
end
function PathFinder:getBlockBack()
	local block = { pos = current.pos + self.vectors[(current.orientation+2)%4], orientation = (current.orientation+2)%4 }
	return block
end

function PathFinder:checkValidNode(block)
	--local blockName = getMapValue(block.x, block.y, block.z)
	--if blockName and ( blockName == 0 or badBlocks[blockName] or goodBlocks[blockName] ) then
	--UNCOMMENT: allow digging through unknown blocks.
		return true
	--end
	--return false
end

function PathFinder:getNeighbours(current, map)
	local neighbours = {}
	-- neighbour = { pos, orientation }
	local neighbour = PathFinder:getBlockForward(current)
	if self:checkValidNode(neighbour.pos) == true then
		table.insert(neighbours, neighbour)
	end
	neighbour = PathFinder:getneighbourUp(current)
	if self:checkValidNode(neighbour.pos) == true then
		table.insert(neighbours, neighbour)
	end
	neighbour = PathFinder:getneighbourDown(current)
	if self:checkValidNode(neighbour.pos) == true then
		table.insert(neighbours, neighbour)
	end
	neighbour = PathFinder:getneighbourLeft(current)
	if self:checkValidNode(neighbour.pos) == true then
		table.insert(neighbours, neighbour)
	end
	neighbour = PathFinder:getneighbourRight(current)
	if self:checkValidNode(neighbour.pos) == true then
		table.insert(neighbours, neighbour )
	end
	neighbour = PathFinder:getneighbourBack(current)
	if self:checkValidNode(neighbour.pos) == true then
		table.insert(neighbours, neighbour)
	end
	
	return neighbours
end

function PathFinder:findNode(set, fNode)
	for _, node in ipairs(set) do
		if node == fNode then 
			return true
		end
	end
	return false
end
function PathFinder:removeNode(set, rNode)
	for i, node in ipairs(set) do
		if node == rNode then 
			set [ i ] = set [ #set ] --move last entry to current to avoid holes
			set [ #set ] = nil
			break
		end
	end	
end

costOrientation = {
[0] = 1, 	-- forward, up, down
[2] = 1.5, 	-- back
[-2] = 1.5, -- back
[-1] = 1.5, -- left
[1] = 1.5,	-- right
}

function PathFinder:calculateCost(current,neighbour)
	local cost = costOrientation[(neighbour.orientation-current.orientation)]
	--local cost = costOrientation[neighbour.orientation]
	
	local blockName = getMapValue[neighbour.pos]
	if blockName 
		--block already explored
		if blockName == 0 then
			-- no extra cost
		else
			-- if block is mineable is checked in checkValidNode
			cost = cost + 1
			-- WARNING: we dont neccessarily know which block comes after this one...
		end
	else
		-- it is unknown what type of block is here
		-- could be air, could be a chest
		-- SOLUTION -> recalculate path when it is blocked by a disallowed block
		cost = cost + 1
	end
	return cost
end

function PathFinder:exampleCall()
	local goal = { x = 5, y = 5, z = 5 }
	self:aStar(self.pos, self.orientation, self.home, self.map, self.calculateCost)
end

function PathFinder:aStarCustom(startPos, startOrientation, goal, nodes, checkValidNodeFunc)
	local closedSet = {}
	local openSet = { { pos = startPos, orientation = startOrientation } }
	local cameFrom = {} --vorgängerListe
	
	if checkValidNodeFunc then self.checkValidNode = checkValidNodeFunc end
	
	local gScore, fScore = {}, {}
	gScore[startPos] = 0
	fScore[startPos] = gScore[startPos] + calculateHeuristic(startPos,goal)
	
	while #openSet > 0 do
	
		local current = getLowestScore(openSet, fScore)
		if current.pos == goal then -- geht das mit vector?
			local path = reconstructPath( {}, cameFrom, goal)
			table.insert(path,goal)
			print(path)
			return path
		end
		
		removeNode(openSet, current)		
		table.insert(closedSet, current)	
		
		local neighbours = getNeighbours(current, nodes)
		for _, neighbour in ipairs(neighbours) do
			if not findNode(closedSet, neighbour.pos) then
				
				local tentativeGScore = gScore[current] + calculateCost(current,neighbour)
				
				local notInOpenSet = ( findNode(openSet, neighbour) == false )
				if notInOpenSet == true or tentativeGScore < gScore[neighbour.pos] then
					cameFrom[neighbour.pos] = current.pos
					gScore[neighbour.pos] = tentativeGScore
					fScore[neighbour.pos] = gScore[neighbour.pos] + calculateHeuristic(neighbour.pos,goal)
					if notInOpenSet == true then
						table.insert(openSet, neighbour)
					end
				end
			end
		end
	end
	return nil
end