-- cmd+arrows: pure spatial nav
hs.hotkey.bind({ "cmd" }, "up", function()
	hs.window.focusedWindow():focusWindowNorth(nil, true, true)
end)

hs.hotkey.bind({ "cmd" }, "down", function()
	hs.window.focusedWindow():focusWindowSouth(nil, true, true)
end)

hs.hotkey.bind({ "cmd" }, "right", function()
	hs.window.focusedWindow():focusWindowEast(nil, true, true)
end)

hs.hotkey.bind({ "cmd" }, "left", function()
	hs.window.focusedWindow():focusWindowWest(nil, true, true)
end)
