

if rednet then
	os.loadAPI("/runtime/bluenet.lua")
	shell.run("runtime/update.lua")

	shell.run("runtime/killRednet.lua")
	return
end


os.loadAPI("/runtime/global.lua")
os.loadAPI("/runtime/config.lua")


shell.run("runtime/initialize.lua")


-- initialize miner should run before openTab
-- otherwise turtle.forward can get stuck indefinetely

tabMain = shell.openTab("runtime/main.lua")
tabReceive = shell.openTab("runtime/receive.lua")
tabSend = shell.openTab("runtime/send.lua")


multishell.setTitle(tabMain, "main")
multishell.setTitle(tabReceive, "receive")
multishell.setTitle(tabSend, "send")

if global.miner then 
	local status,err = pcall(function() 
		global.miner:finishInitialization()
	end )
	global.handleError(err,status) 
end

-- MultiShell tests: 
-- shell.openTab("/multi/multi_1.lua")
-- shell.openTab("multi/multi_2")

--shell.openTab better than multishell.launch because it does not disable some global functionalities like require()