-- cmd+tab: toggle last two | cmd+`: focus ghostty | cmd+shift+tab: disabled

local ghosttyFilter = hs.window.filter.new("Ghostty")

cmdTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
	local flags = e:getFlags()
	local chars = e:getCharacters()

	-- cmd+shift+tab: disabled, eat the event
	if chars == string.char(25) and flags:containExactly({ "cmd", "shift" }) then
		return true
	end

	-- cmd+tab: toggle between last two
	if chars == "\t" and flags:containExactly({ "cmd" }) then
		local wins = hs.window.orderedWindows()
		if #wins > 1 then
			wins[2]:focus()
		end
		return true
	end

	-- cmd+`: focus most recent Ghostty window
	if chars == "`" and flags:containExactly({ "cmd" }) then
		local focused = hs.window.focusedWindow()
		if focused and focused:application():name() == "Ghostty" then
			return true -- already on Ghostty, do nothing
		end

		local ghosttyWins = ghosttyFilter:getWindows(hs.window.filter.sortByFocusedLast)
		if #ghosttyWins > 0 then
			ghosttyWins[1]:focus()
		else
			hs.application.launchOrFocus("Ghostty")
		end
		return true
	end

	return false
end)

cmdTap:start()
