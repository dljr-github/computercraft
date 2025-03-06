

while true do
	local event, p1, p2, p3, p4, p5 = os.pullEvent("rednet_message")
	print(event, p1, p2, p3, p4, p5)
end