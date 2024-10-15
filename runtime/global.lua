
running = true
monitor = {}
display = {}
node = nil
nodeStream = nil
nodeUpdate = nil
printStatus = false
printEvents = false
printSend = false
printMainTime = false

map = {}
updates = {}

-- turtles: state, mapLog, mapBuffer
turtles = {}

pos = {}
taskGroups = {}

function saveStations(fileName)
	print("saving stations")
	if not fileName then fileName = "runtime/stations.txt" end
	local f = fs.open(fileName,"w")
	f.write(textutils.serialize(config.stations))
	f.close()
end
function loadStations(fileName)
	if not fileName then fileName = "runtime/stations.txt" end
	local f = fs.open(fileName,"r")
	if f then
		config.stations = textutils.unserialize( f.readAll() )
		f.close()
	else
		-- no problem if this file does not exist yet
		print("FILE DOES NOT EXIST", fileName)
	end
end

function saveTurtles(fileName)
	-- problem: two turtles have the same entry in their outgoing mapLog
	-- e.g. 3 sends mapupdate
	-- 		update is stored in maplog of 1 and 2
	--		update has the same reference in both tables
	--		-> repeated entries error
	-- solution: 
	--		1	save turtles seperately/sequentially or without maplog
	--		2	create shollow/deep copy of maplog
	print("saving turtles")
	if not fileName then fileName = "runtime/turtles.txt" end
	local f = fs.open(fileName,"w")
	f.write("{\n")
	for id,turtle in pairs(global.turtles) do
		f.write("[ "..id.." ] = { state = "..textutils.serialise(turtle.state).."\n},\n")
		print("written", id)
	end
	f.write("}")
	--f.write(textutils.serialize(global.turtles))
	f.close()
end

function loadTurtles(fileName)
	if not fileName then fileName = "runtime/turtles.txt" end
	local f = fs.open(fileName,"r")
	if f then
		global.turtles = textutils.unserialize( f.readAll() )
		f.close()
		for id,turtle in pairs(global.turtles) do
			turtle.mapLog = {}
			turtle.mapBuffer = {}
			turtle.loadedChunks = {}
		end
	else
		print("FILE DOES NOT EXIST", fileName)
	end
	if not global.turtles then
		global.turtles = {}
	end
end

function saveGroups(fileName)
	print("saving groups")
	if not fileName then fileName = "runtime/taskGroups.txt" end
	for _,taskGroup in pairs(global.taskGroups) do
		taskGroup.turtles = nil
	end
	local f = fs.open(fileName,"w")
	f.write(textutils.serialize(global.taskGroups))
	f.close()
	for _,taskGroup in pairs(global.taskGroups) do
		taskGroup:setTurtles(global.turtles)
	end
end

