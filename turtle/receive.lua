
node = global.node
tasks = global.tasks

node.onReceive = function(msg) 
	-- reboot is handled in NetworkNode
	if msg then
		
		if msg.data then
			if msg.data[3] then 
				print("received:", msg.data[1], msg.data[2], unpack(msg.data[3]))
			else print("received:", msg.data[1], msg.data[2]) end
			
			if msg.data[1] == "STOP" then
				if global.miner then 
					global.miner.stop = true
				end
			elseif msg.data[1] == "MAP_UPDATE" then
				if global.miner then 
					for _,entry in ipairs(msg.data[2]) do
						-- setData without log
						global.miner.map:setData(entry.x,entry.y,entry.z,entry.data)
					end
				end
			else
				table.insert(tasks, msg.data)
			end
		end
	end
end

while true do
	if node then
		node:listen()
		-- node:checkEvents()
	else
		print("NODE OFFLINE")
		sleep(0.05)
	end
end