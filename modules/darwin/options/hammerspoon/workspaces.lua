-- get user spaces for current screen
local function getSpaces()
	local screen = hs.screen.mainScreen()
	local uuid = screen:getUUID()
	local allSpaces = hs.spaces.allSpaces()[uuid] or {}
	local userSpaces = {}
	for _, spc in ipairs(allSpaces) do
		if hs.spaces.spaceType(spc) == "user" then
			table.insert(userSpaces, spc)
		end
	end
	return userSpaces
end

-- switch to workspace n: ctrl+alt+n
for i = 1, 9 do
	hs.hotkey.bind({ "ctrl", "alt" }, tostring(i), function()
		local spaces = getSpaces()
		if spaces[i] then
			hs.spaces.gotoSpace(spaces[i])
		end
	end)
end
