-- crosshair.lua — Drawing crosshair with adjustable arms, gap and centre dot.
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = __require("config")
local Draw = __require("features/draw")

local Crosshair = {}

local arms = {}
local dot
local connection
local enabled = false
local color = Color3.fromRGB(255, 255, 255)

local function ensure()
	if #arms == 0 then
		for index = 1, 4 do
			arms[index] = Draw.line({ Thickness = 1, Color = color, Transparency = 0.1, Visible = false })
		end
	end
	if not dot then
		dot = Draw.square({ Thickness = 0, Filled = true, Color = color, Transparency = 0.1, Visible = false })
	end
end

local function viewport()
	local camera = Workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end
	return Vector2.new(1920, 1080)
end

local function draw()
	if not enabled then
		return
	end
	ensure()
	if not arms[1] then
		return
	end

	local center = viewport() * 0.5
	local size = Config.get("CrosshairSize")
	local gap = Config.get("CrosshairGap")
	local thickness = Config.get("CrosshairThickness")

	Draw.set(arms[1], { From = Vector2.new(center.X, center.Y - gap), To = Vector2.new(center.X, center.Y - gap - size) })
	Draw.set(arms[2], { From = Vector2.new(center.X, center.Y + gap), To = Vector2.new(center.X, center.Y + gap + size) })
	Draw.set(arms[3], { From = Vector2.new(center.X - gap, center.Y), To = Vector2.new(center.X - gap - size, center.Y) })
	Draw.set(arms[4], { From = Vector2.new(center.X + gap, center.Y), To = Vector2.new(center.X + gap + size, center.Y) })

	for index = 1, 4 do
		Draw.set(arms[index], { Visible = true, Color = color, Thickness = thickness })
	end

	if Config.get("CrosshairDot") then
		Draw.set(dot, {
			Position = center - Vector2.new(1, 1),
			Size = Vector2.new(2, 2),
			Visible = true,
			Color = color,
		})
	else
		Draw.set(dot, { Visible = false })
	end
end

function Crosshair.setEnabled(state)
	enabled = state

	if not state then
		if connection then
			connection:Disconnect()
			connection = nil
		end
		for _, arm in ipairs(arms) do
			Draw.set(arm, { Visible = false })
		end
		Draw.set(dot, { Visible = false })
		return true
	end

	if not Draw.available() then
		return false, "executor has no Drawing API"
	end

	ensure()
	if not connection then
		connection = RunService.RenderStepped:Connect(draw)
	end
	draw()
	return true
end

function Crosshair.setColor(value)
	color = value
	for _, arm in ipairs(arms) do
		Draw.set(arm, { Color = value })
	end
	Draw.set(dot, { Color = value })
end

function Crosshair.destroy()
	Crosshair.setEnabled(false)
	for index, arm in ipairs(arms) do
		Draw.remove(arm)
		arms[index] = nil
	end
	Draw.remove(dot)
	dot = nil
end

return Crosshair
