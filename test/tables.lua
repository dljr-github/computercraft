local tinsert = table.insert

function testInsertPerformance()
    local iterations = 10000000 -- Number of insertions to test
    local data = 1 -- Example data to insert

    -- Test table.insert
    local buf1 = {}
    local start = os.epoch("utc")
    for i = 1, iterations do
        table.insert(buf1, data)
    end
    local timeTableInsert = os.epoch("utc") - start
    print("table.insert:", timeTableInsert, "ms")

    -- Test local tinsert = table.insert
    local buf2 = {}
    
    start = os.epoch("utc")
    for i = 1, iterations do
        tinsert(buf2, data)
    end
    local timeLocalTInsert = os.epoch("utc") - start
    print("local tinsert:", timeLocalTInsert, "ms")

    -- Test buf[#buf+1] = data
    local buf3 = {}
    start = os.epoch("utc")
    for i = 1, iterations do
        buf3[#buf3 + 1] = data
    end
    local timeDirectInsert = os.epoch("utc") - start
    print("buf[#buf+1]:", timeDirectInsert, "ms")
end

testInsertPerformance()