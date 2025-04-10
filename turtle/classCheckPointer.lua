require("classList")

local default = {
	fileName = "runtime/checkpoint.txt",
}

local CheckPointer = {}

local tpack = table.pack
local tableinsert = table.insert

function CheckPointer:new(o)
    o = o or {}
    setmetatable(o, self)  
	self.__index = self
	
	-- Function Caching
    for k, v in pairs(self) do
        if type(v) == "function" then
            o[k] = v  -- Directly assign method to object
        end
    end
	
	o.fileName = default.fileName
	o.index = 0
	o.checkpoint = { }
	
    return o
end

function CheckPointer:existsCheckpoint()
	if fs.exists(self.fileName) then
		return true
	end
	return false
end

function CheckPointer:load(miner)
	if not fs.exists(self.fileName) then 
		print("no checkpoint available")
		return nil
	end

	local file = fs.open(self.fileName, "r")
	self.checkpoint = textutils.unserialize(file.readAll())
	file.close()
	
	if not self.checkpoint then
		print("checkpoint file empty")
		fs.delete(self.fileName)
		return false
	end

	local taskList = miner.taskList
	for _, task in ipairs(self.checkpoint.tasks or {}) do
		local entry = { task.func, taskState = task.taskState }
		taskList:addLast(entry)
	end

	-- restore position seperately

	return true
end

function CheckPointer:executeTasks(miner)
	print("CONTINUE FROM CHECKPOINT")

	-- restore the miner position
	local pos, orientation = self.checkpoint.pos, self.checkpoint.orientation
	
	for k, task in ipairs(self.checkpoint.tasks) do
		if k == 1 and not task.taskState.ignorePosition then 
			-- only restore Position if needed
			if not miner:navigateToPos(pos.x, pos.y, pos.z) then 
				print("checkpoint position not reachable")
				return false
			end
			miner:turnTo(orientation)
		end
		local func = task.func
		local args = task.taskState.args
		miner[func](miner, table.unpack(args, 1, args.n))
	end

	-- remove the checkpoint file after restoration
	fs.delete(self.fileName)
	return true
end

local function getCheckpointableTasks(taskList)
	 -- save only checkpointable tasks

    local checkpointableTasks = {}
	local node = taskList.first
	while node do
		if node.taskState then
			-- checkpointable task
			tableinsert(checkpointableTasks, { func = node[1], taskState = node.taskState })
		end
		node = node._next
	end

    return checkpointableTasks
end

function CheckPointer:save(miner)

    local checkpoint = {
        tasks = getCheckpointableTasks(miner.taskList),
        pos = miner.pos,
        orientation = miner.orientation,
    }

	if #checkpoint.tasks == 0 then
		fs.delete(self.fileName)
	else
		--if not self.file then
			self.file = fs.open(self.fileName, "w")
		--end
		self.file.write(textutils.serialize(checkpoint))
		self.file.close()
		--self.file.flush()

		--print("CHP:", checkpoint.tasks[1].func)
		-- flush appends the file
	end
    
end

function CheckPointer:close()
	if self.file then 
		self.file.close()
	end
end

return CheckPointer