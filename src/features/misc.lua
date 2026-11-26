-- misc.lua — lighting, idle guard, server actions.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local Misc = {}

local originals
local idleConn

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

function Misc.destroy()
	Misc.setFullbright(false)
	Misc.setAntiAFK(false)
end

return Misc
