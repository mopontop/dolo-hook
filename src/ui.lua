-- ui.lua — Linoria front-end. Falls back to the bundled window if Linoria
-- cannot be fetched or does not return a usable library.
local Config = __require("config")
local Util = __require("util")
local Player = __require("features/player")
local ESP = __require("features/esp")
local Teleport = __require("features/teleport")
local Misc = __require("features/misc")

local UI = { backend = "none" }

-- wally-rblx/LinoriaLib is gone (404). These are live mirrors of the same
-- library; tried in order until one yields a compiling library.
local LINORIA_SOURCES = {
	"https://cdn.jsdelivr.net/gh/violin-suzutsuki/LinoriaLib@main/Library.lua",
	"https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua",
	"https://raw.githubusercontent.com/stratxgy/Linora-Lib/main/Library.lua",
}

local Library
local Options
local fallback

local function notify(text, duration)
	if Library and type(Library.Notify) == "function" then
		pcall(function()
			Library:Notify(tostring(text), duration or 4)
		end)
		return
	end
	Util.notify("Dolo.Hook", text)
end

local function report(ok, message, okText)
	if ok then
		notify(message or okText or "done")
	else
		notify("Failed: " .. tostring(message))
	end
	return ok
end

-- A 404 returns an HTML page, which loadstring then fails on with a message
-- that hides the real cause. Check the body before handing it to the compiler.
local function looksLikeLibrary(source)
	if type(source) ~= "string" then
		return false, "response was not a string"
	end
	if #source < 5000 then
		return false, ("response too short: %d bytes"):format(#source)
	end
	local head = source:sub(1, 256)
	if head:find("<!DOCTYPE") or head:find("<html") or head:find("404: Not Found") then
		return false, "server returned an HTML/404 page"
	end
	return true
end

local function loadLibrary()
	local reasons = {}

	for _, url in ipairs(LINORIA_SOURCES) do
		local fetched, source = pcall(function()
			return game:HttpGet(url)
		end)

		if not fetched then
			reasons[#reasons + 1] = ("fetch failed (%s)"):format(tostring(source))
			continue
		end

		local valid, why = looksLikeLibrary(source)
		if not valid then
			reasons[#reasons + 1] = ("%s: %s"):format(url:match("[^/]+/[^/]+/main"), why)
			continue
		end

		local compiled, chunk = pcall(loadstring, source)
		if not compiled or type(chunk) ~= "function" then
			reasons[#reasons + 1] = ("%s: compile failed (%s)"):format(url:match("[^/]+/[^/]+/main"), tostring(chunk))
			continue
		end

		local ran, library = pcall(chunk)
		if ran and type(library) == "table" and type(library.CreateWindow) == "function" then
			return library
		end
		reasons[#reasons + 1] = ("%s: load failed (%s)"):format(url:match("[^/]+/[^/]+/main"), tostring(library))
	end

	error("no working Linoria source: " .. table.concat(reasons, "; "))
end

local function buildLinoria()
	Library = loadLibrary()
	Options = (getgenv and getgenv().Options) or Options

	local window = Library:CreateWindow({
		Title = "Dolo.Hook",
		Center = true,
		AutoShow = true,
	})

	local tabs = {
		Main = window:AddTab("Main"),
		Visuals = window:AddTab("Visuals"),
		Teleport = window:AddTab("Teleport"),
		Config = window:AddTab("Config"),
	}

	-- Main / movement
	local movement = tabs.Main:AddLeftGroupbox("Movement")

	movement:AddSlider("WalkSpeed", {
		Text = "Walk speed",
		Default = Config.get("WalkSpeed"),
		Min = 8,
		Max = 300,
		Rounding = 0,
		Suffix = " studs/s",
		Callback = function(value)
			Player.setWalkSpeed(value)
		end,
	})

	movement:AddSlider("JumpPower", {
		Text = "Jump power",
		Default = Config.get("JumpPower"),
		Min = 50,
		Max = 500,
		Rounding = 0,
		Callback = function(value)
			Player.setJumpPower(value)
		end,
	})

	movement:AddSlider("FlySpeed", {
		Text = "Fly speed",
		Default = Config.get("FlySpeed"),
		Min = 10,
		Max = 300,
		Rounding = 0,
		Suffix = " studs/s",
		Callback = function(value)
			Config.set("FlySpeed", value)
		end,
	})

	movement:AddToggle("Fly", {
		Text = "Fly",
		Tooltip = "WASD to move, Space up, LeftControl down",
		Default = Config.get("Fly"),
		Callback = function(value)
			Config.set("Fly", value)
			local ok, message = Player.setFly(value)
			if not ok then
				notify("Fly: " .. tostring(message))
			end
		end,
	})

	movement:AddToggle("NoClip", {
		Text = "NoClip",
		Default = Config.get("NoClip"),
		Callback = function(value)
			Config.set("NoClip", value)
			Player.setNoClip(value)
		end,
	})

	movement:AddToggle("InfiniteJump", {
		Text = "Infinite jump",
		Default = Config.get("InfiniteJump"),
		Callback = function(value)
			Config.set("InfiniteJump", value)
			Player.setInfiniteJump(value)
		end,
	})

	-- Main / character
	local character = tabs.Main:AddRightGroupbox("Character")

	character:AddButton({
		Text = "Reset character",
		Func = function()
			report(Player.resetCharacter(), "character reset")
		end,
	})

	character:AddToggle("AntiAFK", {
		Text = "Anti-AFK",
		Default = Config.get("AntiAFK"),
		Callback = function(value)
			Config.set("AntiAFK", value)
			Misc.setAntiAFK(value)
		end,
	})

	character:AddButton({
		Text = "Rejoin server",
		Func = function()
			notify("Rejoining...")
			task.wait(0.5)
			Misc.rejoin()
		end,
	})

	-- Visuals
	local players = tabs.Visuals:AddLeftGroupbox("Players")

	players:AddToggle("ESP", {
		Text = "Player ESP",
		Default = Config.get("ESP"),
		Callback = function(value)
			Config.set("ESP", value)
			ESP.setEnabled(value)
		end,
	})

	players:AddLabel("ESP color"):AddColorPicker("ESPColor", {
		Default = Color3.fromRGB(120, 180, 255),
		Title = "ESP color",
		Callback = function(color)
			ESP.setColor(color)
		end,
	})

	local world = tabs.Visuals:AddRightGroupbox("World")

	world:AddToggle("Fullbright", {
		Text = "Fullbright",
		Default = Config.get("Fullbright"),
		Callback = function(value)
			Config.set("Fullbright", value)
			Misc.setFullbright(value)
		end,
	})

	-- Teleport
	local waypoints = tabs.Teleport:AddLeftGroupbox("Waypoints")

	waypoints:AddInput("WaypointName", {
		Text = "Waypoint name",
		Default = "",
		Placeholder = "spawn",
		Finished = false,
	})

	local waypointNames = Teleport.waypointNames()

	waypoints:AddDropdown("Waypoints", {
		Text = "Saved waypoints",
		Values = (#waypointNames > 0) and waypointNames or { "(empty)" },
		Default = 1,
		Multi = false,
	})

	waypoints:AddButton({
		Text = "Save waypoint here",
		Func = function()
			local name = ""
			if Options and Options.WaypointName then
				name = tostring(Options.WaypointName.Value or "")
			end
			local ok, result = Teleport.saveWaypoint(name)
			if not ok then
				notify("Waypoint: " .. tostring(result))
				return
			end
			local names = Teleport.waypointNames()
			pcall(function()
				Options.Waypoints:SetValues(names)
			end)
			notify(('Waypoint "%s" saved'):format(tostring(result)))
		end,
	})

	waypoints:AddButton({
		Text = "Teleport to waypoint",
		Func = function()
			local selected = Options and Options.Waypoints and Options.Waypoints.Value
			if not selected or selected == "(empty)" then
				notify("Pick a waypoint first")
				return
			end
			report(Teleport.toWaypoint(selected), nil, "teleported")
		end,
	})

	local targets = tabs.Teleport:AddRightGroupbox("Players")

	targets:AddDropdown("TargetPlayer", {
		Text = "Player",
		SpecialType = "Player",
		Multi = false,
	})

	targets:AddButton({
		Text = "Teleport to player",
		Func = function()
			local selected = Options and Options.TargetPlayer and Options.TargetPlayer.Value
			if not selected or selected == "" then
				notify("Pick a player first")
				return
			end
			report(Teleport.toPlayer(selected), nil, "teleported")
		end,
	})

	targets:AddButton({
		Text = "Refresh player list",
		Func = function()
			local names = Teleport.playerNames()
			pcall(function()
				Options.TargetPlayer:SetValues(names)
			end)
			notify(("%d other players"):format(#names))
		end,
	})

	-- Config
	local settings = tabs.Config:AddLeftGroupbox("Settings")

	settings:AddButton({
		Text = "Save settings",
		Func = function()
			local ok, message = Config.save()
			report(ok, message, "saved")
		end,
	})

	settings:AddButton({
		Text = "Load settings",
		Func = function()
			local ok, message = Config.load()
			if ok then
				UI.sync()
			end
			report(ok, message, "loaded")
		end,
	})

	settings:AddButton({
		Text = "Unload",
		Func = function()
			UI.destroy()
		end,
	})

	local menu = tabs.Config:AddRightGroupbox("Menu")

	menu:AddLabel("Menu keybind"):AddKeyPicker("MenuKeybind", {
		Default = "K",
		NoUI = true,
		Text = "Menu keybind",
	})

	Library.ToggleKeybind = Options and Options.MenuKeybind

	-- Visible proof of which front-end is running.
	if type(Library.SetWatermark) == "function" then
		pcall(function()
			Library:SetWatermark("Dolo.Hook — Linoria")
			Library:SetWatermarkVisibility(true)
		end)
	end

	Library:OnUnload(function()
		pcall(function()
			Player.destroy()
			ESP.destroy()
			Misc.destroy()
		end)
	end)

	UI.backend = "linoria"
	UI.sync()
	notify("Dolo.Hook loaded — Linoria")
end

function UI.sync()
	if UI.backend == "fallback" and fallback then
		return fallback.sync()
	end

	if Options then
		pcall(function()
			Options.WalkSpeed:SetValue(Config.get("WalkSpeed"))
			Options.JumpPower:SetValue(Config.get("JumpPower"))
			Options.FlySpeed:SetValue(Config.get("FlySpeed"))
			Options.Fly:SetValue(Config.get("Fly"))
			Options.NoClip:SetValue(Config.get("NoClip"))
			Options.InfiniteJump:SetValue(Config.get("InfiniteJump"))
			Options.ESP:SetValue(Config.get("ESP"))
			Options.Fullbright:SetValue(Config.get("Fullbright"))
			Options.AntiAFK:SetValue(Config.get("AntiAFK"))
		end)
	end

	Player.setWalkSpeed(Config.get("WalkSpeed"))
	Player.setJumpPower(Config.get("JumpPower"))
	Player.setFly(Config.get("Fly"))
	Player.setNoClip(Config.get("NoClip"))
	Player.setInfiniteJump(Config.get("InfiniteJump"))
	ESP.setEnabled(Config.get("ESP"))
	Misc.setFullbright(Config.get("Fullbright"))
	Misc.setAntiAFK(Config.get("AntiAFK"))
end

function UI.build()
	local ok, err = pcall(buildLinoria)
	if ok then
		return
	end

	-- Linoria unreachable: the bundled window still has to work.
	fallback = __require("ui_fallback")
	UI.backend = "fallback"

	local built, fallbackError = pcall(fallback.build)
	if not built then
		Util.showError(
			"Dolo.Hook — no window could be built",
			("linoria: %s\nfallback: %s"):format(tostring(err), tostring(fallbackError))
		)
		error(fallbackError)
	end

	-- Never let the substitute pass for the real thing silently.
	Util.showError("Linoria unavailable — bundled window in use", tostring(err))
	notify("Linoria unavailable — bundled window in use")
end

function UI.destroy()
	if Library then
		pcall(function()
			Library:Unload()
		end)
		Library = nil
	end
	if fallback then
		pcall(fallback.destroy)
		fallback = nil
	end
	pcall(function()
		Player.destroy()
		ESP.destroy()
		Misc.destroy()
	end)
	UI.backend = "none"
	Util.notify("Dolo.Hook", "unloaded")
end

return UI
