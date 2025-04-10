
local utilsSerialize = {
	serialize = function(chunk)
		if chunk then
			local txt = "{"
			for id, data in pairs(chunk) do
				local idtype, datatype = type(id), type(data)
				if idtype == "number" then 
					if datatype == "number" then 
						txt = txt .. "[".. id .. "] = " .. data .. ",\n"
					elseif datatype == "string" then
						txt = txt .. "[".. id .. "] = \"" .. data .. "\",\n"
					elseif datatype == "boolean" then
						txt = txt .. "[".. id .. "] = " .. tostring(data) .. ",\n"
					end
				else 
					if datatype == "number" then 
						txt = txt .. "[\"" .. id .. "\"] = " .. data .. ",\n"
					elseif datatype == "string" then
						txt = txt .. "[\"" .. id .. "\"] = \"" .. data .. "\",\n"
					elseif datatype == "boolean" then
						txt = txt .. "[\"" .. id .. "\"] = " .. tostring(data) .. ",\n"
					end
				end
			end
			return txt .. "}"
		--else
		--	print(textutils.serialize(debug.traceback()))
		--	error("no chunk")
		end
	end,

	unserialize = function(data)
		local func = load("return " .. data)
		if func then 
			return func()
		end
	end
}

return utilsSerialize