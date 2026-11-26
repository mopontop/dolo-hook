-- ui.lua — Rayfield window. Requires the feature modules before it runs.
local Config = __require("config")
local Util = __require("util")
local Player = __require("features/player")
local ESP = __require("features/esp")
local Teleport = __require("features/teleport")
local Misc = __require("features/misc")

local UI = {}

local RAYFIELD_URL = "https://sirius.menu/rayfield"

local Rayfield
local window
local elements = {}
local loaded = false

local function notify(title, content)
	if loaded and Rayfield then
		pcall(function()
			Rayfield:Notify({ Title = title, Content = content, Duration = 4 })
		end)
	else
		Util.notify(title, content)
	end
end

local function report(result, okMessage)
	local ok, message = result
	if ok then
		if okMessage then
			notify("Success", message or okMessage)
		end
		return true
	end
	notify("Failed", tostring(message or "unknown error"))
	return false
end

local function loadRayfield()
	local loader = loadstring(game:HttpGet(RAYFIELD_URL))
	if type(loader) ~= "function" then
		error("rayfield loader did not return a function")
	end
	return loader()
end

local function buildPlayerTab(Rayfield, tab)
	tab:CreateSection("Movement")

	elements.WalkSpeed = tab:CreateSlider({
		Name = "Walk Speed",
		Range = { 8, 300 },
		Increment = 1,
		Suffix = "studs/s",
		CurrentValue = Config.get("WalkSpeed"),
		Flag = "WalkSpeed",
		Callback = function(value)
			Player.setWalkSpeed(value)
		end,
	})

	elements.JumpPower = tab:CreateSlider({
		Name = "Jump Power",
		Range = { 50, 500 },
		Increment = 1,
		Suffix = "power",
		CurrentValue = Config.get("JumpPower"),
		Flag = "JumpPower",
		Callback = function(value)
			Player.setJumpPower(value)
		end,
	})

	tab:CreateSection("Flight")

	elements.Fly = tab:CreateToggle({
		Name = "Fly (WASD + Space/Ctrl)",
		CurrentValue = Config.get("Fly"),
		Flag = "Fly",
		Callback = function(value)
			Config.set("Fly", value)
			local ok, message = Player.setFly(value)
			if not ok then
				notify("Fly", tostring(message))
			end
		end,
	})

	elements.FlySpeed = tab:CreateSlider({
		Name = "Fly Speed",
		Range = { 10, 300 },
		Increment = 1,
		Suffix = "studs/s",
		CurrentValue = Config.get("FlySpeed"),
		Flag = "FlySpeed",
		Callback = function(value)
			Config.set("FlySpeed", value)
		end,
	})

	tab:CreateSection("Collision")

	elements.NoClip = tab:CreateToggle({
		Name = "NoClip",
		CurrentValue = Config.get("NoClip"),
		Flag = "NoClip",
		Callback = function(value)
			Config.set("NoClip", value)
			Player.setNoClip(value)
		end,
	})

	elements.InfiniteJump = tab:CreateToggle({
		Name = "Infinite Jump",
		CurrentValue = Config.get("InfiniteJump"),
		Flag = "InfiniteJump",
		Callback = function(value)
			Config.set("InfiniteJump", value)
			Player.setInfiniteJump(value)
		end,
	})

	tab:CreateButton({
		Name = "Reset Character",
		Callback = function()
			report(Player.resetCharacter(), "character reset")
		end,
	})
end

local function buildVisualsTab(Rayfield, tab)
	tab:CreateSection("Players")

	elements.ESP = tab:CreateToggle({
		Name = "Player ESP",
		CurrentValue = Config.get("ESP"),
		Flag = "ESP",
		Callback = function(value)
			Config.set("ESP", value)
			ESP.setEnabled(value)
		end,
	})

	elements.ESPColor = tab:CreateColorPicker({
		Name = "ESP Color",
		Color = Color3.fromRGB(120, 180, 255),
		Flag = "ESPColor",
		Callback = function(color)
			ESP.setColor(color)
		end,
	})

	tab:CreateSection("Lighting")

	elements.Fullbright = tab:CreateToggle({
		Name = "Fullbright",
		CurrentValue = Config.get("Fullbright"),
		Flag = "Fullbright",
		Callback = function(value)
			Config.set("Fullbright", value)
			Misc.setFullbright(value)
		end,
	})
end

local function buildTeleportTab(Rayfield, tab)
	tab:CreateSection("Waypoints")

	elements.WaypointName = tab:CreateInput({
		Name = "Waypoint Name",
		CurrentValue = "",
		PlaceholderText = "spawn",
		RemoveTextAfterFocusLost = false,
		Flag = "WaypointName",
		Callback = function()
		end,
	})

	tab:CreateButton({
		Name = "Save Waypoint Here",
		Callback = function()
			local name = elements.WaypointName and elements.WaypointName.CurrentValue or ""
			local ok, result = Teleport.saveWaypoint(name)
			if ok then
				local names = Teleport.waypointNames()
				if elements.Waypoints then
					elements.Waypoints:Refresh((#names > 0) and names or { "(empty)" })
				end
				notify("Waypoint", ("saved \"%s\""):format(result))
			else
				notify("Waypoint", tostring(result))
			end
		end,
	})

	local waypointNames = Teleport.waypointNames()
	elements.Waypoints = tab:CreateDropdown({
		Name = "Saved Waypoints",
		Options = (#waypointNames > 0) and waypointNames or { "(empty)" },
		CurrentOption = {},
		MultipleOptions = false,
		Flag = "Waypoints",
		Callback = function()
		end,
	})

	tab:CreateButton({
		Name = "Teleport To Waypoint",
		Callback = function()
			local selected = elements.Waypoints and elements.Waypoints.CurrentOption or {}
			local name = selected[1]
			if not name or name == "(empty)" then
				notify("Teleport", "pick a waypoint first")
				return
			end
			report(Teleport.toWaypoint(name))
		end,
	})

	tab:CreateSection("Players")

	local playerNames = Teleport.playerNames()
	elements.Players = tab:CreateDropdown({
		Name = "Player",
		Options = (#playerNames > 0) and playerNames or { "(empty)" },
		CurrentOption = {},
		MultipleOptions = false,
		Flag = "Players",
		Callback = function()
		end,
	})

	tab:CreateButton({
		Name = "Teleport To Player",
		Callback = function()
			local selected = elements.Players and elements.Players.CurrentOption or {}
			local name = selected[1]
			if not name or name == "(empty)" then
				notify("Teleport", "pick a player first")
				return
			end
			report(Teleport.toPlayer(name))
		end,
	})

	tab:CreateButton({
		Name = "Refresh Player List",
		Callback = function()
			local names = Teleport.playerNames()
			if elements.Players then
				elements.Players:Refresh(names)
			end
			notify("Players", ("%d in server"):format(#names))
		end,
	})
end

local function buildMiscTab(Rayfield, tab)
	tab:CreateSection("Session")

	elements.AntiAFK = tab:CreateToggle({
		Name = "Anti-AFK",
		CurrentValue = Config.get("AntiAFK"),
		Flag = "AntiAFK",
		Callback = function(value)
			Config.set("AntiAFK", value)
			Misc.setAntiAFK(value)
		end,
	})

	tab:CreateButton({
		Name = "Rejoin Server",
		Callback = function()
			notify("Rejoin", "teleporting")
			task.wait(0.6)
			Misc.rejoin()
		end,
	})

	tab:CreateSection("Diagnostics")

	tab:CreateButton({
		Name = "Test Notification",
		Callback = function()
			notify("Test", "notification pipeline is live")
		end,
	})

	tab:CreateButton({
		Name = "Destroy UI",
		Callback = function()
			UI.destroy()
		end,
	})
end

local function buildConfigTab(Rayfield, tab)
	tab:CreateButton({
		Name = "Save Settings",
		Callback = function()
			notify("Config", select(2, Config.save()) or "saved")
		end,
	})

	tab:CreateButton({
		Name = "Load Settings",
		Callback = function()
			local ok, message = Config.load()
			notify("Config", tostring(message))
			if ok then
				UI.sync()
			end
		end,
	})
end

-- Push the current config into live features and into the UI elements.
function UI.sync()
	if elements.WalkSpeed then
		elements.WalkSpeed:Set(Config.get("WalkSpeed"))
	end
	if elements.JumpPower then
		elements.JumpPower:Set(Config.get("JumpPower"))
	end
	if elements.FlySpeed then
		elements.FlySpeed:Set(Config.get("FlySpeed"))
	end

	Player.setWalkSpeed(Config.get("WalkSpeed"))
	Player.setJumpPower(Config.get("JumpPower"))

	if Config.get("Fly") then
		Player.setFly(true)
	else
		Player.setFly(false)
	end
	if elements.Fly then
		elements.Fly:Set(Config.get("Fly"))
	end

	Player.setNoClip(Config.get("NoClip"))
	if elements.NoClip then
		elements.NoClip:Set(Config.get("NoClip"))
	end

	Player.setInfiniteJump(Config.get("InfiniteJump"))
	if elements.InfiniteJump then
		elements.InfiniteJump:Set(Config.get("InfiniteJump"))
	end

	ESP.setEnabled(Config.get("ESP"))
	if elements.ESP then
		elements.ESP:Set(Config.get("ESP"))
	end

	Misc.setFullbright(Config.get("Fullbright"))
	if elements.Fullbright then
		elements.Fullbright:Set(Config.get("Fullbright"))
	end

	Misc.setAntiAFK(Config.get("AntiAFK"))
	if elements.AntiAFK then
		elements.AntiAFK:Set(Config.get("AntiAFK"))
	end
end

function UI.build()
	if window then
		return window
	end

	Rayfield = loadRayfield()
	loaded = true

	Util.setNotifier(function(title, content)
		notify(title, content)
	end)

	window = Rayfield:CreateWindow({
		Name = "OJB Test Hub",
		Icon = 0,
		LoadingTitle = "OJB Test Hub",
		LoadingSubtitle = "loadstring test build",
		Theme = "Default",
		ToggleUIKeybind = "K",
		DisableRayfieldPrompts = true,
	})

	buildPlayerTab(Rayfield, window:CreateTab("Player", "user"))
	buildVisualsTab(Rayfield, window:CreateTab("Visuals", "eye"))
	buildTeleportTab(Rayfield, window:CreateTab("Teleport", "map-pin"))
	buildMiscTab(Rayfield, window:CreateTab("Misc", "wrench"))
	buildConfigTab(Rayfield, window:CreateTab("Config", "save"))

	UI.sync()
	notify("OJB Test Hub", "loaded — press K to toggle")
	return window
end

function UI.destroy()
	pcall(function()
		Player.destroy()
		ESP.destroy()
		Misc.destroy()
	end)
	if window then
		pcall(function()
			window:Destroy()
		end)
		window = nil
	end
	elements = {}
	loaded = false
	Util.notify("OJB Test Hub", "unloaded")
end

return UI
