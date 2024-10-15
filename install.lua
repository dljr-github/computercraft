
-- installation using github for the host computer

local git = "https://raw.githubusercontent.com/helpmyRF24isntworking/computercraft/main"

files = {
	"startup.lua"
}
	
folders = {
	{ 
		name = "general",
		files = {
			"classHeap.lua",
			"classList.lua",
			"classLogger.lua",
			"classMap.lua",
			"classNetworkNode.lua",
			"classPathfinder.lua",
			"config.lua",
		}
	},
	{ 
		name = "gui",
		files = {
			"classBox.lua",
			"classButton.lua",
			"classCheckBox.lua",
			"classFrame.lua",
			"classGPU.lua",
			"classHostDisplay.lua",
			"classLabel.lua",
			"classMapDisplay.lua",
			"classMonitor.lua",
			"classTaskSelector.lua",
			"classToggleButton.lua",
			"classTurtleControl.lua",
			"classWindow.lua",
		}
	},
	{ 
	name = "host",
		files = {
			"display.lua",
			"global.lua",
			"initialize.lua",
			"main.lua",
			"receive.lua",
			"send.lua",
			"startup.lua",
			"testMonitor.lua",
		}
	},
	{ 
	name = "pocket",
		files = {
			"startup.lua",
			"update.lua",
		}
	},
	{ 
	name = "turtle",
		files = {
			"classMiner.lua",
			"global.lua",
			"initialize.lua",
			"main.lua",
			"receive.lua",
			"send.lua",
			"startup.lua",
			"testMine.lua",
			"update.lua",
		}
	},
}

local function downloadFile(filePath)
	local url = git.."/"..filePath
	if fs.exists(filePath) then
		fs.delete(filePath)
	end
	local file = http.get(url)
	local fileData = file.readAll()
	print("downloading", filePath)
	local f = fs.open(filePath, "w")
	f.write(fileData)
	f.close()
end

-- download folders
for _,folder in ipairs(folders) do
	print("downloading folder", folder.name)
	if not fs.exists(folder.name) then
		fs.makeDir(folder.name)
	end
	
	for _,fileName in ipairs(folder.files) do
		local filePath = folder.name.."/"..fileName
		downloadFile(filePath)
	end
end

-- download single files
for _,fileName in ipairs(files) do
	downloadFile(fileName)
end

os.reboot()