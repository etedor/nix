-- toggle monitor input between HDMI and Thunderbolt
-- ctrl+alt+cmd+i
-- requires: m1ddc (brew install m1ddc)

-- configure these for your monitor (run: m1ddc get input)
local HDMI = 17
local THUNDERBOLT = 25

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "i", function()
	local result = hs.execute("/opt/homebrew/bin/m1ddc get input")
	local currentInput = tonumber(result:match("%d+"))

	if currentInput == HDMI then
		hs.execute("/opt/homebrew/bin/m1ddc set input " .. THUNDERBOLT)
		hs.alert.show("Switched to Thunderbolt")
	else
		hs.execute("/opt/homebrew/bin/m1ddc set input " .. HDMI)
		hs.alert.show("Switched to HDMI")
	end
end)
