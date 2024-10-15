

-- COPY REQUIRED FILES
local folders = {
"general",
"gui",
"host",
}

local reboot = false

local function copyFolder(folderName, targetFolder)
	if not fs.exists(targetFolder) or not fs.isDir(targetFolder) then
		print("no such folder", folderName)
	end
	if fs.exists(folderName) and fs.isDir(folderName) then
		for _, fileName in pairs(fs.list('/' .. folderName)) do
			local targetData
			if fs.exists(targetFolder.."/"..fileName) then
				local file = fs.open(targetFolder.."/"..fileName, "r")
				targetData = file.readAll()
				file.close()
				fs.delete(targetFolder.."/"..fileName)
			end
			local file = fs.open(folderName.."/"..fileName, "r")
			local fileData = file.readAll()
			file.close()
			if (fileData == targetData) == false then reboot = true end
			fs.copy(folderName.."/"..fileName, targetFolder.."/"..fileName)
		end
	else
		print("no such folder", folderName)
	end
end

local function copyFiles()
	for _,folderName in ipairs(folders) do
		copyFolder(folderName, "runtime")
	end
	if fs.exists("startup.lua") then
		fs.delete("startup.lua")
	end
	fs.copy("runtime/startup.lua", "startup.lua")
	if reboot then
		os.reboot()
	end
end
-- END OF COPY

copyFiles()

-- add runtime as default environment
package.path = package.path ..";../runtime/?.lua"
--package.path = package.path .. ";../?.lua" .. ";../runtime/?.lua"
--require("classMonitor")
--require("../runtime/classMonitor")
--require("runtime/classMonitor")

os.loadAPI("/runtime/global.lua")
os.loadAPI("/runtime/config.lua")
os.loadAPI("/runtime/bluenet.lua")

shell.run("runtime/initialize.lua")

shell.openTab("runtime/display.lua")
shell.openTab("runtime/main.lua")
shell.openTab("runtime/receive.lua")
shell.openTab("runtime/send.lua")
--shell.openTab("runtime/send.lua")
--shell.openTab("runtime/update.lua")

--shell.run("runtime/testMonitor")