-- ======================================================================
-- Copyright (c) 2012 RapidFire Studio Limited 
-- All Rights Reserved. 
-- http://www.rapidfirestudio.com

-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:

-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- ======================================================================

module ( "astar", package.seeall )

----------------------------------------------------------------
-- local variables
----------------------------------------------------------------

local INF = 1/0
local cachedPaths = nil

----------------------------------------------------------------
-- local functions
----------------------------------------------------------------

function dist ( x1, y1, x2, y2 )
	
	return math.sqrt ( math.pow ( x2 - x1, 2 ) + math.pow ( y2 - y1, 2 ) )
end

function dist_between ( nodeA, nodeB )

	return dist ( nodeA.x, nodeA.y, nodeB.x, nodeB.y )
end

function heuristic_cost_estimate ( nodeA, nodeB )

	return dist ( nodeA.x, nodeA.y, nodeB.x, nodeB.y )
end

function is_valid_node ( node, neighbor )

	return true
end

function lowest_f_score ( set, f_score )

	local lowest, bestNode = INF, nil
	for _, node in ipairs ( set ) do
		local score = f_score [ node ]
		if score < lowest then
			lowest, bestNode = score, node
		end
	end
	return bestNode
end

function neighbor_nodes ( theNode, nodes )

	local neighbors = {}
	for _, node in ipairs ( nodes ) do
		if theNode ~= node and is_valid_node ( theNode, node ) then
			table.insert ( neighbors, node )
		end
	end
	return neighbors
end

function not_in ( set, theNode )

	for _, node in ipairs ( set ) do
		if node == theNode then return false end
	end
	return true
end

function remove_node ( set, theNode )

	for i, node in ipairs ( set ) do
		if node == theNode then 
			set [ i ] = set [ #set ]
			set [ #set ] = nil
			break
		end
	end	
end

function unwind_path ( flat_path, map, current_node )

	if map [ current_node ] then
		table.insert ( flat_path, 1, map [ current_node ] ) 
		return unwind_path ( flat_path, map, map [ current_node ] )
	else
		return flat_path
	end
end

----------------------------------------------------------------
-- pathfinding functions
----------------------------------------------------------------

function a_star ( start, goal, nodes, valid_node_func )

	local closedset = {}
	local openset = { start }
	local came_from = {}

	if valid_node_func then is_valid_node = valid_node_func end

	local g_score, f_score = {}, {}
	g_score [ start ] = 0
	f_score [ start ] = g_score [ start ] + heuristic_cost_estimate ( start, goal )

	while #openset > 0 do
	
		local current = lowest_f_score ( openset, f_score )
		if current == goal then
			local path = unwind_path ( {}, came_from, goal )
			table.insert ( path, goal )
			return path
		end

		remove_node ( openset, current )		
		table.insert ( closedset, current )
		
		local neighbors = neighbor_nodes ( current, nodes )
		for _, neighbor in ipairs ( neighbors ) do 
			if not_in ( closedset, neighbor ) then
			
				local tentative_g_score = g_score [ current ] + dist_between ( current, neighbor )
				 
				if not_in ( openset, neighbor ) or tentative_g_score < g_score [ neighbor ] then 
					came_from 	[ neighbor ] = current
					g_score 	[ neighbor ] = tentative_g_score
					f_score 	[ neighbor ] = g_score [ neighbor ] + heuristic_cost_estimate ( neighbor, goal )
					if not_in ( openset, neighbor ) then
						table.insert ( openset, neighbor )
					end
				end
			end
		end
	end
	return nil -- no valid path
end

----------------------------------------------------------------
-- exposed functions
----------------------------------------------------------------

function clear_cached_paths ()

	cachedPaths = nil
end

function distance ( x1, y1, x2, y2 )
	
	return dist ( x1, y1, x2, y2 )
end

function path ( start, goal, nodes, ignore_cache, valid_node_func )

	if not cachedPaths then cachedPaths = {} end
	if not cachedPaths [ start ] then
		cachedPaths [ start ] = {}
	elseif cachedPaths [ start ] [ goal ] and not ignore_cache then
		return cachedPaths [ start ] [ goal ]
	end

      local resPath = a_star ( start, goal, nodes, valid_node_func )
      if not cachedPaths [ start ] [ goal ] and not ignore_cache then
              cachedPaths [ start ] [ goal ] = resPath
      end

	return resPath
end





-------------------------------------------------------------
-------------------------------------------------------------







-- Positions must be a table (or metatable) where table.x and table.y are accessible.

local Vector = require( "vector" )
local Heap = require( "heap" )

local Luafinding = {}
Luafinding.__index = Luafinding

-- This instantiates a new Luafinding class for usage later.
-- "start" and "finish" should both be 2 dimensional vectors, or just a table with "x" and "y" keys. See the note at the top of this file.
-- positionOpenCheck can be a function or a table.
-- If it's a function it must have a return value of true or false depending on whether or not the position is open.
-- If it's a table it should simply be a table of values such as "pos[x][y] = true".
function Luafinding:Initialize( start, finish, positionOpenCheck )
    local newPath = setmetatable( { Start = start, Finish = finish, PositionOpenCheck = positionOpenCheck }, Luafinding )
    newPath:CalculatePath()
    return newPath
end

local function distance( start, finish )
    local dx = start.x - finish.x
    local dy = start.y - finish.y
    return dx * dx + dy * dy
end

local positionIsOpen
local function positionIsOpenTable( pos, check ) return check[pos.x] and check[pos.x][pos.y] end
local function positionIsOpenCustom( pos, check ) return check( pos ) end

local adjacentPositions = {
    Vector( 0, -1 ),
    Vector( -1, 0 ),
    Vector( 0, 1 ),
    Vector( 1, 0 ),
    Vector( -1, -1 ),
    Vector( 1, -1 ),
    Vector( -1, 1 ),
    Vector( 1, 1 )
}

local function fetchOpenAdjacentNodes( pos, positionOpenCheck )
    local result = {}

    for i = 1, #adjacentPositions do
        local adjacentPos = pos + adjacentPositions[i]
        if positionIsOpen( adjacentPos, positionOpenCheck ) then
            table.insert( result, adjacentPos )
        end
    end

    return result
end

-- This is the function used to actually calculate the path.
-- It returns the calcated path table, or nil if it cannot find a path.
function Luafinding:CalculatePath()
    local start, finish, positionOpenCheck = self.Start, self.Finish, self.PositionOpenCheck
    if not positionOpenCheck then return end
    positionIsOpen = type( positionOpenCheck ) == "table" and positionIsOpenTable or positionIsOpenCustom
    if not positionIsOpen( finish, positionOpenCheck ) then return end
    local open, closed = Heap(), {}

    start.gScore = 0
    start.hScore = distance( start, finish )
    start.fScore = start.hScore

    open.Compare = function( a, b )
        return a.fScore < b.fScore
    end

    open:Push( start )

    while not open:Empty() do
        local current = open:Pop()
        local currentId = current:ID()
        if not closed[currentId] then
            if current == finish then
                local path = {}
                while true do
                    if current.previous then
                        table.insert( path, 1, current )
                        current = current.previous
                    else
                        table.insert( path, 1, start )
                        self.Path = path
                        return path
                    end
                end
            end

            closed[currentId] = true

            local adjacents = fetchOpenAdjacentNodes( current, positionOpenCheck )
            for i = 1, #adjacents do
                local adjacent = adjacents[i]
                if not closed[adjacent:ID()] then
                    local added_gScore = current.gScore + distance( current, adjacent )

                    if not adjacent.gScore or added_gScore < adjacent.gScore then
                        adjacent.gScore = added_gScore
                        if not adjacent.hScore then
                            adjacent.hScore = distance( adjacent, finish )
                        end
                        adjacent.fScore = added_gScore + adjacent.hScore

                        open:Push( adjacent )
                        adjacent.previous = current
                    end
                end
            end
        end
    end
end

function Luafinding:GetPath()
    return self.Path
end

function Luafinding:GetDistance()
    local path = self.Path
    if not path then return end
    return distance( path[1], path[#path] )
end

function Luafinding:GetTiles()
    local path = self.Path
    if not path then return end
    return #path
end

function Luafinding:__tostring()
    local path = self.Path
    local string = ""

    if path then
        for k, v in ipairs( path ) do
            local formatted = ( k .. ": " .. v )
            string = k == 1 and formatted or string .. "\n" .. formatted
        end
    end

    return string
end

return setmetatable( Luafinding, { __call = function( self, ... ) return self:Initialize( ... ) end } )