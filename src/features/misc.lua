-- misc.lua — lighting, idle guard, server actions.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local Misc = {}

local originals
local idleConn
local fogOriginals

function Misc.setFullbright(enabled)
	if enabled then
		if originals then
			return true
		end
		originals = {
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			Brightness = Lighting.Brightness,
			ClockTime = Lighting.ClockTime,
			FogEnd = Lighting.FogEnd,
			GlobalShadows = Lighting.GlobalShadows,
		}
		Lighting.Ambient = Color3.fromRGB(200, 200, 200)
		Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
		Lighting.Brightness = 3
		Lighting.ClockTime = 14
		Lighting.FogEnd = 1e6
		Lighting.GlobalShadows = false
		return true
	end

	if not originals then
		return true
	end
	for key, value in pairs(originals) do
		Lighting[key] = value
	end
	originals = nil
	return true
end

function Misc.setAntiAFK(enabled)
	if not enabled then
		if idleConn then
			idleConn:Disconnect()
			idleConn = nil
		end
		return true
	end

	if idleConn then
		return true
	end
	idleConn = Players.LocalPlayer.Idled:Connect(function()
		-- The 20-minute idle kick fires from the client; feed it a click.
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.zero)
	end)
	return true
end

function Misc.rejoin()
	TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
	return true
end

function Misc.serverInfo()
	local info = {
		place = tostring(game.PlaceId),
		job = tostring(game.JobId),
		players = tostring(#Players:GetPlayers()),
	}
	return info
end

function Misc.copyJobId()
	local ok = pcall(function()
		setclipboard(tostring(game.JobId))
	end)
	return ok
end

function Misc.setNoFog(enabled)
	if enabled then
		if fogOriginals then
			return true
		end
		fogOriginals = { FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart }
		Lighting.FogEnd = 100000
		Lighting.FogStart = 100000
		return true
	end
	if fogOriginals then
		Lighting.FogEnd = fogOriginals.FogEnd
		Lighting.FogStart = fogOriginals.FogStart
		fogOriginals = nil
	end
	return true
end

function Misc.setCameraFOV(value)
	local camera = workspace.CurrentCamera
	if not camera then
		return false, "no camera"
	end
	camera.FieldOfView = value
	return true
end

function Misc.destroy()
	Misc.setFullbright(false)
	Misc.setNoFog(false)
	Misc.setAntiAFK(false)
end

return Misc
