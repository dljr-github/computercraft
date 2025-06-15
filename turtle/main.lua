
local tasks = global.tasks
local list = global.list
local miner = global.miner

function openTab(task_2, task_3)
	--TODO: error handling has to be done by the file itself
	if not task_3 then
		shell.openTab("runtime/"..task_2)
	else
		shell.openTab("runtime/"..task_2, unpack(task_3))
	end
end
function callMiner(task_2, task_3)
	if miner then
		if not task_3 or #task_3 == 0 then
			local func = "return function(miner,task_2) miner:"..task_2.."() end"
			loadstring(func)()(miner,task_2)
			--miner[task_2](miner)
		else
			-- debug.getinfo not working when using miner[functionName]()
			--miner[task_2](miner, unpack(task_3))
			local func = "return function(miner,task_2,task_3) miner:"..task_2.."(unpack(task_3)) end"
			loadstring(func)()(miner,task_2,task_3)
		end
	end
end
function shellRun(task_2, task_3)
	--TODO: error handling has to be done by the file itself
	if not task_3 then
		shell.run("runtime/"..task_2)
	else
		shell.run("runtime/"..task_2, unpack(task_3))
	end
end
print("waiting for tasks...")
while true do
	while #tasks > 0 do
		local status,err = nil,nil
		task = table.remove(tasks, 1)
		if task[1] == "RUN" then
			--status,err = pcall(shellRun,task[2],task[3])
			global.err = nil
			openTab(task[2],task[3])
		elseif task[1] == "DO" then
			global.err = nil
			-- Pass all parameters from index 3 onwards
			local params = {}
			for i = 3, #task do
				params[i-2] = task[i]
			end
			status,err = pcall(callMiner,task[2],params)
			global.handleError(err,status)

		elseif task[1] == "UPDATE" then
			shell.run("update.lua")
		else
			print("something else")
		end
	end
	sleep(0.2)
end