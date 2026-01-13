-- cmd+arrows: pure spatial nav
hs.hotkey.bind({ "cmd" }, "up", function()
	local win = hs.window.focusedWindow()
	if win then
		win:focusWindowNorth(nil, true, true)
	end
end)

hs.hotkey.bind({ "cmd" }, "down", function()
	local win = hs.window.focusedWindow()
	if win then
		win:focusWindowSouth(nil, true, true)
	end
end)

hs.hotkey.bind({ "cmd" }, "right", function()
	local win = hs.window.focusedWindow()
	if win then
		win:focusWindowEast(nil, true, true)
	end
end)

hs.hotkey.bind({ "cmd" }, "left", function()
	local win = hs.window.focusedWindow()
	if win then
		win:focusWindowWest(nil, true, true)
	end
end)
