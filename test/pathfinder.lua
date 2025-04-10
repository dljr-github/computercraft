

-- add to classMiner
function Miner:testPathfinding(distance)
	
	local goal = vector.new(self.pos.x + distance, self.pos.y, self.pos.z)
	self.map:setMaxChunks(800)
	local pathFinder = PathFinder()
	pathFinder.checkValid = checkSafe
	local path = pathFinder:aStarPart(self.pos, self.orientation, goal , self.map, 10000)
end

-- execute in terminal
global.miner:testPathfinding(50)