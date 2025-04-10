local CheckPointer = {}
CheckPointer.__index = CheckPointer


-- Standard method call (via metatable)
function CheckPointer:new(o)
    o = o or {}
    setmetatable(o, self)  -- Uses __index for function lookup
    return o
end

-- Optimized method call (direct assignment)
function CheckPointer:newOptimized(o)
    o = o or {}
    setmetatable(o, self)  
    --o.exampleMethod = self.exampleMethod  -- Direct reference
	-- **Automate function caching: Copy all methods from prototype to object**
    for k, v in pairs(self) do
        if type(v) == "function" then
            o[k] = v  -- Directly assign method to object
        end
    end
	
    return o
end

-- Example method
function CheckPointer.exampleMethod(x)
    return x * 2
end
local exampleMethod = CheckPointer.exampleMethod

-- Local definition
local LocalCheckPointer = {}
LocalCheckPointer.__index = LocalCheckPointer

function LocalCheckPointer:exampleMethod(x)
    return x * 2
end

function LocalCheckPointer:new()
    local o = {}
    setmetatable(o, self)
	--o.exampleMethod = self.exampleMethod
    return o
end

-- Create objects
local obj1 = CheckPointer:new()           -- Uses __index lookup
local obj2 = CheckPointer:newOptimized()  -- Direct function reference
local obj3 = LocalCheckPointer:new()

-- Benchmarking
local iterations = 10^7  -- 10 million iterations
local start, stop

-- Test standard method call
start = os.epoch("local")
for i = 1, iterations do
    obj1.exampleMethod(i)
end
stop = os.epoch("local")
print("Standard method call time:", stop - start)

-- Test optimized method call
start = os.epoch("local")
for i = 1, iterations do
    obj2.exampleMethod(i)  -- No __index lookup
end
stop = os.epoch("local")
print("Optimized method call time:", stop - start)

-- Test standard method call
start = os.epoch("local")
for i = 1, iterations do
    obj3:exampleMethod(i)
end
stop = os.epoch("local")
print("Local object call time:", stop - start)

-- Test standard method call
start = os.epoch("local")
for i = 1, iterations do
    exampleMethod(i)
end
stop = os.epoch("local")
print("Local method call time:", stop - start)

-- standard: 	993
-- local class: 960
-- optimized: 	845

