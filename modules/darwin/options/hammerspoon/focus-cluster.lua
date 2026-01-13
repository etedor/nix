-- helper to check window overlap
local function overlaps(a, b)
	local af, bf = a:frame(), b:frame()
	return af:intersect(bf).area > 0
end

-- cluster-based (transitive overlap)
local function getOverlappingCluster(win)
	local allWins = {}
	for _, w in ipairs(hs.window.allWindows()) do
		if w:isStandard() and w:isVisible() then
			table.insert(allWins, w)
		end
	end

	-- find cluster via flood fill
	local cluster = {}
	local seen = {}
	local queue = { win }

	while #queue > 0 do
		local current = table.remove(queue, 1)
		if not seen[current:id()] then
			seen[current:id()] = true
			table.insert(cluster, current)
			for _, w in ipairs(allWins) do
				if not seen[w:id()] and overlaps(current, w) then
					table.insert(queue, w)
				end
			end
		end
	end

	-- sort by window ID (stable order)
	table.sort(cluster, function(a, b)
		return a:id() < b:id()
	end)

	return cluster
end

local function findWindowIndex(list, win)
	for i, w in ipairs(list) do
		if w:id() == win:id() then
			return i
		end
	end
	return 1
end

-- shift+cmd+up/down: cycle overlapping cluster
hs.hotkey.bind({ "shift", "cmd" }, "up", function()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end
	local cluster = getOverlappingCluster(win)
	if #cluster > 1 then
		local idx = findWindowIndex(cluster, win)
		local prev = idx > 1 and idx - 1 or #cluster
		cluster[prev]:focus()
	end
end)

hs.hotkey.bind({ "shift", "cmd" }, "down", function()
	local win = hs.window.focusedWindow()
	if not win then
		return
	end
	local cluster = getOverlappingCluster(win)
	if #cluster > 1 then
		local idx = findWindowIndex(cluster, win)
		local next = idx < #cluster and idx + 1 or 1
		cluster[next]:focus()
	end
end)
