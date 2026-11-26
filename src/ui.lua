-- ui.lua — Linoria front-end. Falls back to the bundled window if Linoria
-- cannot be fetched or does not return a usable library.
local Config = __require("config")
local Util = __require("util")
local Player = __require("features/player")
local ESP = __require("features/esp")
local Teleport = __require("features/teleport")
local Misc = __require("features/misc")
local Aim = __require("features/aim")
local Visuals = __require("features/visuals")
local World = __require("features/world")
local HUD = __require("features/hud")
local Crosshair = __require("features/crosshair")
local Hitbox = __require("features/hitbox")

local UserInputService = game:GetService("UserInputService")

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
			reasons[#reasons + 1] = ("%s: %s"):format(url, why)
			continue
		end

		local compiled, chunk = pcall(loadstring, source)
		if not compiled or type(chunk) ~= "function" then
			reasons[#reasons + 1] = ("%s: compile failed (%s)"):format(url, tostring(chunk))
			continue
		end

		local ran, library = pcall(chunk)
		if ran and type(library) == "table" and type(library.CreateWindow) == "function" then
			return library
		end
		reasons[#reasons + 1] = ("%s: load failed (%s)"):format(url, tostring(library))
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
		Aim = window:AddTab("Aim"),
		Visuals = window:AddTab("Visuals"),
		HUD = window:AddTab("HUD"),
		Movement = window:AddTab("Movement"),
		World = window:AddTab("World"),
		Teleport = window:AddTab("Teleport"),
		Misc = window:AddTab("Misc"),
		Config = window:AddTab("Config"),
	}

	-- ---------------------------------------------------------------- aim
	local aimbox = tabs.Aim:AddLeftGroupbox("Aimbot")

	aimbox:AddToggle("Aim", {
		Text = "Aimbot",
		Default = Config.get("Aim"),
		Callback = function(value)
			Config.set("Aim", value)
			local ok, message = Aim.setEnabled(value)
			if not ok then
				notify("Aim: " .. tostring(message))
			end
		end,
	})

	aimbox:AddDropdown("AimKey", {
		Text = "Aim key",
		Values = { "MB2", "MB1", "E", "Q", "Always" },
		Default = 1,
		Multi = false,
		Callback = function(value)
			Config.set("AimKey", value)
		end,
	})

	aimbox:AddDropdown("AimPart", {
		Text = "Aim part",
		Values = { "Head", "Torso", "Root" },
		Default = 1,
		Multi = false,
		Callback = function(value)
			Config.set("AimPart", value)
		end,
	})

	aimbox:AddSlider("AimFOV", {
		Text = "FOV radius",
		Default = Config.get("AimFOV"),
		Min = 10,
		Max = 600,
		Rounding = 0,
		Suffix = " px",
		Callback = function(value)
			Config.set("AimFOV", value)
		end,
	})

	aimbox:AddSlider("AimSmooth", {
		Text = "Smoothing",
		Default = Config.get("AimSmooth"),
		Min = 0.05,
		Max = 0.95,
		Rounding = 2,
		Callback = function(value)
			Config.set("AimSmooth", value)
		end,
	})

	local aimchecks = tabs.Aim:AddRightGroupbox("Targeting")

	aimchecks:AddToggle("AimVisibleOnly", {
		Text = "Visible only",
		Default = Config.get("AimVisibleOnly"),
		Tooltip = "Raycast from the camera; a wall blocks the target",
		Callback = function(value)
			Config.set("AimVisibleOnly", value)
		end,
	})

	aimchecks:AddToggle("AimTeamCheck", {
		Text = "Team check",
		Default = Config.get("AimTeamCheck"),
		Callback = function(value)
			Config.set("AimTeamCheck", value)
		end,
	})

	aimchecks:AddToggle("AimPrediction", {
		Text = "Velocity prediction",
		Default = Config.get("AimPrediction"),
		Callback = function(value)
			Config.set("AimPrediction", value)
		end,
	})

	aimchecks:AddToggle("AimFOVCircle", {
		Text = "Draw FOV circle",
		Default = Config.get("AimFOVCircle"),
		Callback = function(value)
			Config.set("AimFOVCircle", value)
		end,
	})

	aimchecks:AddSlider("AimMaxDistance", {
		Text = "Max distance",
		Default = Config.get("AimMaxDistance"),
		Min = 50,
		Max = 2000,
		Rounding = 0,
		Suffix = " studs",
		Callback = function(value)
			Config.set("AimMaxDistance", value)
		end,
	})

	aimchecks:AddDropdown("AimPriority", {
		Text = "Target priority",
		Values = { "Crosshair", "Distance", "Health" },
		Default = 1,
		Multi = false,
		Callback = function(value)
			Config.set("AimPriority", value)
		end,
	})

	local hitboxBox = tabs.Aim:AddLeftGroupbox("Hitbox")

	hitboxBox:AddToggle("Hitbox", {
		Text = "Expand hitboxes",
		Tooltip = "Client-side head resize on other players",
		Default = Config.get("Hitbox"),
		Callback = function(value)
			Config.set("Hitbox", value)
			Hitbox.setEnabled(value)
		end,
	})

	hitboxBox:AddSlider("HitboxScale", {
		Text = "Head scale",
		Default = Config.get("HitboxScale"),
		Min = 1,
		Max = 6,
		Rounding = 1,
		Suffix = "x",
		Callback = function(value)
			Config.set("HitboxScale", value)
		end,
	})

	-- ------------------------------------------------------------ visuals
	local playersBox = tabs.Visuals:AddLeftGroupbox("Players")

	playersBox:AddToggle("ESP", {
		Text = "Player ESP",
		Default = Config.get("ESP"),
		Callback = function(value)
			Config.set("ESP", value)
			local ok, message = Visuals.setEnabled(value)
			if not ok then
				notify("ESP: " .. tostring(message))
			end
		end,
	})

	playersBox:AddToggle("ESPBox", {
		Text = "Box",
		Default = Config.get("ESPBox"),
		Callback = function(value)
			Config.set("ESPBox", value)
		end,
	})

	playersBox:AddToggle("ESPName", {
		Text = "Name",
		Default = Config.get("ESPName"),
		Callback = function(value)
			Config.set("ESPName", value)
		end,
	})

	playersBox:AddToggle("ESPHealth", {
		Text = "Health bar",
		Default = Config.get("ESPHealth"),
		Callback = function(value)
			Config.set("ESPHealth", value)
		end,
	})

	playersBox:AddToggle("ESPDistance", {
		Text = "Distance",
		Default = Config.get("ESPDistance"),
		Callback = function(value)
			Config.set("ESPDistance", value)
		end,
	})

	playersBox:AddToggle("ESPTracer", {
		Text = "Tracers",
		Default = Config.get("ESPTracer"),
		Callback = function(value)
			Config.set("ESPTracer", value)
		end,
	})

	playersBox:AddToggle("ESPSkeleton", {
		Text = "Skeleton",
		Default = Config.get("ESPSkeleton"),
		Callback = function(value)
			Config.set("ESPSkeleton", value)
		end,
	})

	playersBox:AddToggle("ESPChams", {
		Text = "Chams (highlight)",
		Default = Config.get("ESPChams"),
		Callback = function(value)
			Config.set("ESPChams", value)
			ESP.setEnabled(value)
		end,
	})

	playersBox:AddToggle("ESPTeamCheck", {
		Text = "Team check",
		Default = Config.get("ESPTeamCheck"),
		Callback = function(value)
			Config.set("ESPTeamCheck", value)
		end,
	})

	playersBox:AddSlider("ESPMaxDistance", {
		Text = "Max distance",
		Default = Config.get("ESPMaxDistance"),
		Min = 50,
		Max = 2000,
		Rounding = 0,
		Suffix = " studs",
		Callback = function(value)
			Config.set("ESPMaxDistance", value)
		end,
	})

	playersBox:AddLabel("ESP color"):AddColorPicker("ESPColor", {
		Default = Color3.fromRGB(120, 170, 255),
		Title = "ESP color",
		Callback = function(value)
			Visuals.setColor(value)
		end,
	})

	local worldBox = tabs.Visuals:AddRightGroupbox("World")

	worldBox:AddToggle("Fullbright", {
		Text = "Fullbright",
		Default = Config.get("Fullbright"),
		Callback = function(value)
			Config.set("Fullbright", value)
			Misc.setFullbright(value)
		end,
	})

	worldBox:AddToggle("NoFog", {
		Text = "No fog",
		Default = Config.get("NoFog"),
		Callback = function(value)
			Config.set("NoFog", value)
			Misc.setNoFog(value)
		end,
	})

	worldBox:AddSlider("CameraFOV", {
		Text = "Camera FOV",
		Default = Config.get("CameraFOV"),
		Min = 30,
		Max = 120,
		Rounding = 0,
		Callback = function(value)
			Config.set("CameraFOV", value)
			Misc.setCameraFOV(value)
		end,
	})

	local crossBox = tabs.Visuals:AddRightGroupbox("Crosshair")

	crossBox:AddToggle("Crosshair", {
		Text = "Crosshair",
		Default = Config.get("Crosshair"),
		Callback = function(value)
			Config.set("Crosshair", value)
			local ok, message = Crosshair.setEnabled(value)
			if not ok then
				notify("Crosshair: " .. tostring(message))
			end
		end,
	})

	crossBox:AddSlider("CrosshairSize", {
		Text = "Arm length",
		Default = Config.get("CrosshairSize"),
		Min = 2,
		Max = 40,
		Rounding = 0,
		Suffix = " px",
		Callback = function(value)
			Config.set("CrosshairSize", value)
		end,
	})

	crossBox:AddSlider("CrosshairGap", {
		Text = "Centre gap",
		Default = Config.get("CrosshairGap"),
		Min = 0,
		Max = 30,
		Rounding = 0,
		Suffix = " px",
		Callback = function(value)
			Config.set("CrosshairGap", value)
		end,
	})

	crossBox:AddSlider("CrosshairThickness", {
		Text = "Thickness",
		Default = Config.get("CrosshairThickness"),
		Min = 1,
		Max = 6,
		Rounding = 0,
		Callback = function(value)
			Config.set("CrosshairThickness", value)
		end,
	})

	crossBox:AddToggle("CrosshairDot", {
		Text = "Centre dot",
		Default = Config.get("CrosshairDot"),
		Callback = function(value)
			Config.set("CrosshairDot", value)
		end,
	})

	crossBox:AddLabel("Crosshair color"):AddColorPicker("CrosshairColor", {
		Default = Color3.fromRGB(255, 255, 255),
		Title = "Crosshair color",
		Callback = function(value)
			Crosshair.setColor(value)
		end,
	})

	-- ---------------------------------------------------------------- hud
	local hudBox = tabs.HUD:AddLeftGroupbox("Readouts")

	hudBox:AddToggle("HUD", {
		Text = "HUD",
		Default = Config.get("HUD"),
		Callback = function(value)
			Config.set("HUD", value)
			local ok, message = HUD.setEnabled(value)
			if not ok then
				notify("HUD: " .. tostring(message))
			end
		end,
	})

	hudBox:AddToggle("HUD_FPS", {
		Text = "FPS",
		Default = Config.get("HUD_FPS"),
		Callback = function(value)
			Config.set("HUD_FPS", value)
		end,
	})

	hudBox:AddToggle("HUD_Ping", {
		Text = "Ping",
		Default = Config.get("HUD_Ping"),
		Callback = function(value)
			Config.set("HUD_Ping", value)
		end,
	})

	hudBox:AddToggle("HUD_Players", {
		Text = "Player count",
		Default = Config.get("HUD_Players"),
		Callback = function(value)
			Config.set("HUD_Players", value)
		end,
	})

	hudBox:AddToggle("HUD_Coords", {
		Text = "Position",
		Default = Config.get("HUD_Coords"),
		Callback = function(value)
			Config.set("HUD_Coords", value)
		end,
	})

	hudBox:AddToggle("HUD_Clock", {
		Text = "Clock",
		Default = Config.get("HUD_Clock"),
		Callback = function(value)
			Config.set("HUD_Clock", value)
		end,
	})

	local hudStyle = tabs.HUD:AddRightGroupbox("Style")

	hudStyle:AddLabel("HUD color"):AddColorPicker("HUDColor", {
		Default = Color3.fromRGB(235, 235, 242),
		Title = "HUD color",
		Callback = function(value)
			HUD.setColor(value)
		end,
	})

	-- ----------------------------------------------------------- movement
	local speedBox = tabs.Movement:AddLeftGroupbox("Speed")

	speedBox:AddSlider("WalkSpeed", {
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

	speedBox:AddSlider("JumpPower", {
		Text = "Jump power",
		Default = Config.get("JumpPower"),
		Min = 50,
		Max = 500,
		Rounding = 0,
		Callback = function(value)
			Player.setJumpPower(value)
		end,
	})

	speedBox:AddToggle("Bhop", {
		Text = "Bunny hop",
		Default = Config.get("Bhop"),
		Callback = function(value)
			Player.setBhop(value)
		end,
	})

	local flightBox = tabs.Movement:AddRightGroupbox("Flight")

	flightBox:AddToggle("Fly", {
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

	flightBox:AddSlider("FlySpeed", {
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

	flightBox:AddToggle("NoClip", {
		Text = "NoClip",
		Default = Config.get("NoClip"),
		Callback = function(value)
			Config.set("NoClip", value)
			Player.setNoClip(value)
		end,
	})

	flightBox:AddToggle("InfiniteJump", {
		Text = "Infinite jump",
		Default = Config.get("InfiniteJump"),
		Callback = function(value)
			Config.set("InfiniteJump", value)
			Player.setInfiniteJump(value)
		end,
	})

	flightBox:AddToggle("Hover", {
		Text = "Hover",
		Default = Config.get("Hover"),
		Callback = function(value)
			local ok, message = Player.setHover(value)
			if not ok then
				notify("Hover: " .. tostring(message))
			end
		end,
	})

	flightBox:AddToggle("NoFallDamage", {
		Text = "No fall damage",
		Default = Config.get("NoFallDamage"),
		Callback = function(value)
			Player.setNoFallDamage(value)
		end,
	})

	flightBox:AddToggle("Freeze", {
		Text = "Freeze character",
		Default = Config.get("Freeze"),
		Callback = function(value)
			local ok, message = Player.setFreeze(value)
			if not ok then
				notify("Freeze: " .. tostring(message))
			end
		end,
	})

	flightBox:AddToggle("ClickTeleport", {
		Text = "Click teleport",
		Tooltip = "Press T (rebindable) to jump to the surface under the cursor",
		Default = Config.get("ClickTeleport"),
		Callback = function(value)
			Config.set("ClickTeleport", value)
		end,
	})

	-- -------------------------------------------------------------- world
	local timeBox = tabs.World:AddLeftGroupbox("Lighting")

	timeBox:AddSlider("ClockTime", {
		Text = "Time of day",
		Default = Config.get("ClockTime"),
		Min = 0,
		Max = 24,
		Rounding = 1,
		Callback = function(value)
			Config.set("ClockTime", value)
			World.apply()
		end,
	})

	timeBox:AddSlider("Brightness", {
		Text = "Brightness",
		Default = Config.get("Brightness"),
		Min = 0,
		Max = 5,
		Rounding = 1,
		Callback = function(value)
			Config.set("Brightness", value)
			World.apply()
		end,
	})

	timeBox:AddSlider("WorldFogEnd", {
		Text = "Fog distance",
		Default = Config.get("WorldFogEnd"),
		Min = 100,
		Max = 100000,
		Rounding = 0,
		Callback = function(value)
			Config.set("WorldFogEnd", value)
			World.apply()
		end,
	})

	local physicsBox = tabs.World:AddRightGroupbox("Physics")

	physicsBox:AddSlider("Gravity", {
		Text = "Gravity",
		Default = Config.get("Gravity"),
		Min = 0,
		Max = 500,
		Rounding = 1,
		Callback = function(value)
			Config.set("Gravity", value)
			World.apply()
		end,
	})

	physicsBox:AddButton({
		Text = "Reset world",
		Func = function()
			World.reset()
			notify("World restored")
		end,
	})

	-- ----------------------------------------------------------- teleport
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

	targets:AddButton({
		Text = "Spectate player",
		Func = function()
			local selected = Options and Options.TargetPlayer and Options.TargetPlayer.Value
			if not selected or selected == "" then
				notify("Pick a player first")
				return
			end
			report(Teleport.spectate(selected), nil, "spectating")
		end,
	})

	targets:AddButton({
		Text = "Stop spectating",
		Func = function()
			report(Teleport.unspectate(), nil, "back to your character")
		end,
	})

	targets:AddDropdown("ClickTeleportKey", {
		Text = "Click teleport key",
		Values = { "T", "G", "V", "F" },
		Default = 1,
		Multi = false,
		Callback = function(value)
			Config.set("ClickTeleportKey", value)
		end,
	})

	-- --------------------------------------------------------------- misc
	local session = tabs.Misc:AddLeftGroupbox("Session")

	session:AddToggle("AntiAFK", {
		Text = "Anti-AFK",
		Default = Config.get("AntiAFK"),
		Callback = function(value)
			Config.set("AntiAFK", value)
			Misc.setAntiAFK(value)
		end,
	})

	session:AddButton({
		Text = "Reset character",
		Func = function()
			report(Player.resetCharacter(), "character reset")
		end,
	})

	session:AddButton({
		Text = "Rejoin server",
		Func = function()
			notify("Rejoining...")
			task.wait(0.5)
			Misc.rejoin()
		end,
	})

	local tools = tabs.Misc:AddRightGroupbox("Interface")

	tools:AddButton({
		Text = "Server info",
		Func = function()
			local info = Misc.serverInfo()
			notify(("job %s… | %s players"):format(info.job:sub(1, 8), info.players), 6)
		end,
	})

	tools:AddButton({
		Text = "Copy JobId",
		Func = function()
			report(Misc.copyJobId(), "JobId copied")
		end,
	})

	tools:AddButton({
		Text = "Test notification",
		Func = function()
			notify("Test", 3)
		end,
	})

	tools:AddButton({
		Text = "Unload",
		Func = function()
			UI.destroy()
		end,
	})

	-- ------------------------------------------------------------- config
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

	local menu = tabs.Config:AddRightGroupbox("Menu")

	menu:AddLabel("Menu keybind"):AddKeyPicker("MenuKeybind", {
		Default = "K",
		NoUI = true,
		Text = "Menu keybind",
	})

	Library.ToggleKeybind = Options and Options.MenuKeybind

	-- Click teleport: bound here so it keeps working while the menu is closed.
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not Config.get("ClickTeleport") then
			return
		end
		local key = Config.get("ClickTeleportKey") or "T"
		local keyCode = Enum.KeyCode[key]
		if keyCode and input.KeyCode == keyCode then
			local ok, message = Teleport.toCursor()
			if not ok then
				notify("Teleport: " .. tostring(message))
			end
		end
	end)

	if type(Library.SetWatermark) == "function" then
		pcall(function()
			Library:SetWatermark("Dolo.Hook")
			Library:SetWatermarkVisibility(true)
		end)
	end

	Library:OnUnload(function()
		pcall(function()
			Player.destroy()
			ESP.destroy()
			Aim.destroy()
			Visuals.destroy()
			Misc.destroy()
		end)
	end)

	UI.backend = "linoria"
	Visuals.bind()
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
			Options.Bhop:SetValue(Config.get("Bhop"))
			Options.Hover:SetValue(Config.get("Hover"))
			Options.ESP:SetValue(Config.get("ESP"))
			Options.ESPChams:SetValue(Config.get("ESPChams"))
			Options.Fullbright:SetValue(Config.get("Fullbright"))
			Options.NoFog:SetValue(Config.get("NoFog"))
			Options.AntiAFK:SetValue(Config.get("AntiAFK"))
			Options.Aim:SetValue(Config.get("Aim"))
			Options.HUD:SetValue(Config.get("HUD"))
			Options.Crosshair:SetValue(Config.get("Crosshair"))
			Options.Hitbox:SetValue(Config.get("Hitbox"))
			Options.Freeze:SetValue(Config.get("Freeze"))
			Options.NoFallDamage:SetValue(Config.get("NoFallDamage"))
			Options.ClockTime:SetValue(Config.get("ClockTime"))
			Options.Gravity:SetValue(Config.get("Gravity"))
			Options.Brightness:SetValue(Config.get("Brightness"))
		end)
	end

	Player.setWalkSpeed(Config.get("WalkSpeed"))
	Player.setJumpPower(Config.get("JumpPower"))
	Player.setFly(Config.get("Fly"))
	Player.setNoClip(Config.get("NoClip"))
	Player.setInfiniteJump(Config.get("InfiniteJump"))
	Player.setBhop(Config.get("Bhop"))
	Player.setHover(Config.get("Hover"))
	Player.setNoFallDamage(Config.get("NoFallDamage"))
	Aim.setEnabled(Config.get("Aim"))
	Visuals.setEnabled(Config.get("ESP"))
	ESP.setEnabled(Config.get("ESPChams"))
	Hitbox.setEnabled(Config.get("Hitbox"))
	HUD.setEnabled(Config.get("HUD"))
	Crosshair.setEnabled(Config.get("Crosshair"))
	Misc.setFullbright(Config.get("Fullbright"))
	Misc.setNoFog(Config.get("NoFog"))
	Misc.setCameraFOV(Config.get("CameraFOV"))
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
		Aim.destroy()
		Visuals.destroy()
		Hitbox.destroy()
		HUD.destroy()
		Crosshair.destroy()
		World.destroy()
		Misc.destroy()
	end)
	UI.backend = "none"
	Util.notify("Dolo.Hook", "unloaded")
end

return UI
