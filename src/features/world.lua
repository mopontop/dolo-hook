-- world.lua — lighting, gravity and fog control with a full snapshot restore.
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Config = __require("config")

local World = {}

local snapshot

function World.capture()
	if snapshot then
		return
	end
	snapshot = {
		ClockTime = Lighting.ClockTime,
		Brightness = Lighting.Brightness,
		FogEnd = Lighting.FogEnd,
		FogStart = Lighting.FogStart,
		Gravity = Workspace.Gravity,
		Ambient = Lighting.Ambient,
		FogColor = Lighting.FogColor,
		Exposure = Lighting.ExposureCompensation,
	}
end

function World.apply()
	World.capture()
	Lighting.ClockTime = Config.get("ClockTime")
	Lighting.Brightness = Config.get("Brightness")
	Lighting.FogEnd = Config.get("WorldFogEnd")
	Lighting.ExposureCompensation = Config.get("Exposure")
	Workspace.Gravity = Config.get("Gravity")
	return true
end

function World.setAmbient(color)
	World.capture()
	Lighting.Ambient = color
	Lighting.OutdoorAmbient = color
	return true
end

function World.setFogColor(color)
	World.capture()
	Lighting.FogColor = color
	return true
end

function World.reset()
	if not snapshot then
		return true
	end
	Lighting.ClockTime = snapshot.ClockTime
	Lighting.Brightness = snapshot.Brightness
	Lighting.FogEnd = snapshot.FogEnd
	Lighting.FogStart = snapshot.FogStart
	Lighting.Ambient = snapshot.Ambient
	Lighting.FogColor = snapshot.FogColor
	Lighting.ExposureCompensation = snapshot.Exposure
	Workspace.Gravity = snapshot.Gravity
	snapshot = nil
	return true
end

function World.destroy()
	World.reset()
end

return World
