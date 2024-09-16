local default =  {
	bedrockLevel = -60,
	file = "runtime/map.txt",
	minHeight = -64,
	maxHeight = 320,
}

Map = {}

function Map:new()
	local o = o or {}
	setmetatable(o, self)
	self.__index = self
	
	o.map = {}
	o.minedAreas = {} --TODO
	o.log = {}
	-- list of turtles: function: getNearestTurtle 
	
	o:initialize()
	return o
end

function Map:initialize()
	--self:load()
end

function Map:load(fileName)
	if not fileName then fileName = default.file end
	local f = fs.open(fileName,"r")
	if f then
		self.map = textutils.unserialize( f.readAll() )
		f.close()
	else
		print("FILE DOES NOT EXIST")
	end
end

function Map:save(fileName)
	if not fileName then fileName = default.file end
	local f = fs.open(fileName,"w")
	f.write(textutils.serialize(self.map))
	f.close()
end


function Map:getMap()
	-- used for transferring map via rednet
	return { map = self.map, minedAreas = self.minedAreas }
end
function Map:setMap(map)
	self.map = map.map
	self.minedAreas = map.minedAreas
end

function Map:logData(x,y,z,data)
	table.insert(self.log,{x=x,y=y,z=z,data=data})
end
function Map:readLog()
	return self.log
end
function Map:clearLog()
	self.log = {}
end

function Map:setData(x,y,z,data)
	--nil = not yet inspected
	--0 = inspected but empty or mined
	-- self:logData(x,y,z,data) -- logData is done by miner
	if not self.map then self.map = {} end
	if y > default.bedrockLevel then
		self.map[self:xyzToId(x,y,z)] = data
	else
		self.map[self:xyzToId(x,y,z)] = -1 --bedrock
	end
end

function Map:getData(x,y,z)
	if y <= default.bedrockLevel then
		return -1
	else
		local id = self:xyzToId(x,y,z)
		if self.map then --and self.map[id]
			return self.map[id]
		end
	end
	return nil
end

function Map:clear()
	self.map = {}
end

function Map:posToId(pos)
	return self:xyzToId(pos.x, pos.y, pos.z)
end
function Map:xyzToId(x,y,z)
	-- dont use string IDs for Tables, instead use numbers  
	-- Cantor pairing - natural numbers only to make it reversable
	
	--default.maxHeight - default.minHeight + 64
	
	--max length of id = 16 (then its 1.234234e23)
	-- x,y,z can be up to around 10000,320,10000
	-- if this is ever an issue, set the coordinates of turtles relative to their home
	
	if x < 0 then 
		x = -x 
		y = y + 448 
	end
	if z < 0 then 
		z = -z 
		y = y + 896 
	end
	y = y + 64 -- default.minHeight
	--------------------------------------------------------
	local temp = 0.5 * ( x + y ) * ( x + y + 1 ) + y
	return 0.5 * ( temp + z ) * ( temp + z + 1 ) + z 
	--------------------------------------------------------
end
function Map:idToXYZ(id)
	local w = math.floor( ( math.sqrt( 8 * id + 1 ) - 1 ) / 2 )
	local t = ( w^2 + w ) / 2
	local z = id - t
	local temp = w - z
	
	w =  math.floor( ( math.sqrt( 8 * temp + 1 ) - 1 ) / 2 )
	t = ( w^2 + w ) / 2
	local y = temp - t
	local x = w - y
	
	-- restore negative coordinates
	if y > 448 then
		-- x or z negative
		if y > 896 then 
			-- z negative
			z = -z
			y = y - 896
		end
		if y > 448 then
			-- x negative
			x = -x
			y = y - 448
		end
	end
	y = y - 64
	
	return x,y,z
end
function Map:idToPos(id)
	local x,y,z = self:idToXYZ(id)
	return vector.new(x,y,z)
end

function Map:getDistance(start,finish)
	return math.sqrt( ( finish.x - start.x )^2 + ( finish.y - start.y )^2 + ( finish.z - start.z )^2 )
end

function Map:findNextBlock(curPos, id, maxDistance)
	-- TODO if type(id) == "Table" then ...
	if not maxDistance then maxDistance = math.huge end
	local ores
	if not id then
		ores = oreBlocks
	elseif type(id) == "table" then
		ores = id
	else
		ores = { [id]=true }
	end
	
	local minDist = -1
	local minPos = nil
	
	for key,value in pairs(self.map) do
		if ores[value] then
			local pos = self:idToPos(key)
			local dist = self:getDistance(curPos, pos)
			if ( minDist < 0 or dist < minDist) and dist <= maxDistance then 
				minDist = dist
				minPos = pos
			end
		end
	end	
	return minPos
end