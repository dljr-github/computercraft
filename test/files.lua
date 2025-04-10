
-- test how fast files can be written to

local fileName = "filetest.txt"


local f
local function createFile()
	--if fs.exists(fileName) then
		--fs.delete(fileName) -- extremely slow
	--end
	
	f.write(textutils.serialize(debug.traceback()))
	f.flush()
	--f.write("jooooooooo")
		
end

local function testFiles()
	local start = os.epoch("local")
	f = fs.open(fileName, "w")
	for i = 1, 1000 do
		createFile()
	end
	f.close()	
	print(os.epoch("local")-start)
end
testFiles()


-- delete is very slow (600ms)
-- keeping file open is fastest (6ms)
-- reopening file (200ms)
-- flush (6ms)