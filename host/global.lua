
running = true
monitor = {}
display = {}
node = nil
nodeStatus = nil
nodeUpdate = nil
printStatus = false
printEvents = false

map = {}
updates = {}

-- turtles: state, mapLog, mapBuffer
turtles = {}

pos = {}


function saveStations(fileName)
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
	if not fileName then fileName = "runtime/turtles.txt" end
	local f = fs.open(fileName,"w")
	f.write(textutils.serialize(global.turtles))
	f.close()
end

function loadTurtles(fileName)
	if not fileName then fileName = "runtime/turtles.txt" end
	local f = fs.open(fileName,"r")
	if f then
		global.turtles = textutils.unserialize( f.readAll() )
		f.close()
	else
		global.turtles = {}
		print("FILE DOES NOT EXIST", fileName)
	end
end