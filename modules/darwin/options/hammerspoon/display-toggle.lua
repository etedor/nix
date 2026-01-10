-- toggle monitor input between HDMI and Thunderbolt
-- ctrl+alt+cmd+i

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "i", function()
	hs.execute(hs.configdir .. "/toggle-input.sh", true)
end)
