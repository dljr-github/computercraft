
node = global.node

node.onAnswer = function(answer,forMsg)
	if forMsg.data[1] == "MAP_UPDATE" then
		-- print("MAP ANSWER",answer.sender)
		global.turtles[answer.sender].mapBuffer = {}
	end
end

node.onNoAnswer = function(forMsg)
	if forMsg.data[1] == "MAP_UPDATE" then
		print("NO MAP ANSWER", forMsg.recipient)
	end
end

function sendMapLog()
	if node and node.host then
	for id,data in pairs(global.turtles) do
		-- append the entries
		local entry = table.remove(data.mapLog)
		while entry do
			table.insert(data.mapBuffer, entry)
			entry = table.remove(data.mapLog)
		end
		
		if #data.mapBuffer > 0 then
			print("sending map update", id, #data.mapBuffer)
			node:send(id,{"MAP_UPDATE",data.mapBuffer},true,false)
		end
	end
	end
end

while global.running do
	sendMapLog()
	sleep(0.2)
end