sleepTime = 3
moves = 5

function redo(func)
    sleep(sleepTime)
    start = os.epoch("ingame")
    for i = 1, moves do
        func()
    end
    return os.epoch("ingame")-start
end

function minerBack()
    for i = 1, moves do
        global.miner:back()
    end
end

function back()
    for i = 1, moves do
        turtle.back()
    end
end

function test_general()
	diff_1 = redo(turtle.inspect)
	diff_2 = redo(turtle.detect)
	print("inspect vs detect", diff_1, diff_2)

	diff_3 = redo( function()
		turtle.inspect()
		turtle.forward()
	end)
	back()
	diff_4 = redo( function()
		turtle.detect()
		turtle.forward()
	end)
	back()
	sleep(sleepTime)
	diff_5 = redo( function()
		turtle.forward()
	end)
	back()
	sleep(sleepTime)
	diff_5_2 = redo(function() 
		global.miner:inspect(true) 
		global.miner:forward()
		end)
	print("movement",diff_3, diff_4, diff_5, diff_5_2)

	sleep(sleepTime)
	start = os.epoch()
	turtle.inspect()
	turtle.forward()
	diff_6 = os.epoch()-start
	sleep(sleepTime)
	start = os.epoch()
	turtle.detect()
	turtle.forward()
	diff_7 = os.epoch()-start
	sleep(sleepTime)
	start = os.epoch()
	turtle.forward()
	diff_8 = os.epoch()-start
	print("single",diff_6, diff_7, diff_8)
	sleep(sleepTime)
	back()
	back()
end

-- dig then move vs digMove
diff_1 = redo( function()
    global.miner:inspect()
    global.miner:dig()
    global.miner:forward()
end)
back()
global.miner:inspect()
moves = 1000000
diff_2 = redo( function()
    --print(os.epoch("ingame"))
    global.miner:inspect()
    --global.miner:digMove(true)
end)
--back()
print("dig vs move", diff_1, diff_2)