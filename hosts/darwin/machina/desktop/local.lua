-- QuadStream macros:
--   M4  = Hyper+F4 → bounce all instances, preserve window positions,
--                    reset per-stream fullscreen flags, mute all streams
--   M9  = Hyper+F9 → spawn one additional new instance (Fn1+M4),
--                    reset per-stream fullscreen flags, mute all streams
--
-- QuadStream is App Store sandboxed: hs.application:kill() and
-- :launchOrFocus() don't work, so we send SIGKILL via pkill and relaunch
-- via /usr/bin/open. -n forces a new instance on each invocation.

local APP = "QuadStream"
local HYPER = { "ctrl", "alt", "cmd", "shift" }
local PLIST = os.getenv("HOME") .. "/Library/Containers/fi.alivemedia.QuadStream/Data/Library/Preferences/fi.alivemedia.QuadStream.plist"

local function instances()
  local out = {}
  for _, app in ipairs(hs.application.runningApplications()) do
    if app:name() == APP then table.insert(out, app) end
  end
  return out
end

local function standardWindows()
  local wins = {}
  for _, app in ipairs(instances()) do
    for _, win in ipairs(app:allWindows()) do
      if win:isStandard() then table.insert(wins, win) end
    end
  end
  return wins
end

-- clear stuck per-stream fullscreen flags + force-mute all streams.
-- one PlistBuddy invocation rewrites the plist with all 8 keys in a
-- single disk write. cfprefsd is killed with SIGKILL — SIGTERM would
-- let it flush its dirty in-memory cache (the just-killed app's old
-- state) on top of our writes.
local function resetPrefs()
  local cmd = "/usr/libexec/PlistBuddy"
  for i = 0, 3 do
    cmd = cmd .. " -c 'Set :stream" .. i .. ".fullscreen false' -c 'Set :stream" .. i .. ".muted true'"
  end
  hs.execute(cmd .. " '" .. PLIST .. "' && /usr/bin/killall -9 cfprefsd")
end

-- filter subscription stays active for the lifetime of Hammerspoon —
-- subscribe/unsubscribe cycles can be slow (filter resync, AX observer
-- rebinding), and we hit them on every bounce. _pending is the per-
-- bounce state the callback consults to decide whether to act.
local _pending = nil
local _safety

local _filter = hs.window.filter.new(APP)
_filter:subscribe(hs.window.filter.windowVisible, function(win)
  if not _pending then return end
  _pending.restored = _pending.restored + 1
  local f = _pending.frames[_pending.restored]
  if f then win:setFrame(f) end
  if _pending.restored >= #_pending.frames then
    _pending = nil
    if _safety then _safety:stop(); _safety = nil end
  end
end)

local function bounceCleanup()
  _pending = nil
  if _safety then _safety:stop(); _safety = nil end
end

local function bounce()
  bounceCleanup()

  -- 1. snapshot window positions
  local frames = {}
  for _, win in ipairs(standardWindows()) do
    table.insert(frames, win:frame())
  end
  local n = math.max(1, #frames)

  -- 2. hard kill: SIGKILL skips QS's SIGTERM cleanup (writing per-stream
  -- state we're about to overwrite anyway), removing the main source of
  -- variable shutdown latency.
  hs.execute("/usr/bin/pkill -9 -x " .. APP)

  -- 3. normalize prefs
  resetPrefs()

  -- 4. arm the callback before relaunching
  _pending = { frames = frames, restored = 0 }
  _safety = hs.timer.doAfter(5, bounceCleanup)

  -- 5. launch
  for _ = 1, n do
    hs.execute("/usr/bin/open -n -a " .. APP)
  end
end

local function spawn()
  -- bypass resetPrefs's PlistBuddy+killall: the cfprefsd respawn delay
  -- would block the new instance's first pref read. defaults write goes
  -- through the live cfprefsd, so its cache stays warm for the launch.
  -- whole sequence runs in a background bash so the hotkey returns now.
  local cmds = {}
  for i = 0, 3 do
    table.insert(cmds, "/usr/bin/defaults write fi.alivemedia.QuadStream stream" .. i .. ".fullscreen -bool false")
    table.insert(cmds, "/usr/bin/defaults write fi.alivemedia.QuadStream stream" .. i .. ".muted -bool true")
  end
  table.insert(cmds, "/usr/bin/open -n -a " .. APP)
  hs.task.new("/bin/bash", nil, {"-c", table.concat(cmds, ";")}):start()
end

hs.hotkey.bind(HYPER, "F4", bounce)
hs.hotkey.bind(HYPER, "F9", spawn)
