-- visuals.lua — Drawing-based ESP: boxes, names, health, distance, tracers,
-- skeletons, plus the aim FOV ring.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = __require("config")
local Draw = __require("features/draw")
local Targeting = __require("features/targeting")

local Visuals = {}

local entries = {}
local connection
local color = Color3.fromRGB(120, 170, 255)
local fovCircle
local enabled = false

local SKELETON = {
	{ "Head", "UpperTorso" },
	{ "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" },
	{ "LeftUpperArm", "LeftLowerArm" },
	{ "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" },
	{ "RightUpperArm", "RightLowerArm" },
	{ "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" },
	{ "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" },
	{ "RightUpperLeg", "RightLowerLeg" },
	{ "RightLowerLeg", "RightFoot" },
}

local function newEntry()
	return {
		box = Draw.square({ Thickness = 1, Filled = false, Color = color, Transparency = 1, Visible = false }),
		name = Draw.text({
			Size = 14,
			Center = true,
			Outline = true,
			Color = Color3.new(1, 1, 1),
			Transparency = 1,
			Visible = false,
		}),
		healthBack = Draw.square({ Thickness = 1, Filled = true, Color = Color3.new(0, 0, 0), Transparency = 0.6, Visible = false }),
		healthFill = Draw.square({ Thickness = 0, Filled = true, Color = Color3.fromRGB(80, 220, 120), Transparency = 0.15, Visible = false }),
		distance = Draw.text({
			Size = 12,
			Center = true,
			Outline = true,
			Color = Color3.fromRGB(215, 215, 225),
			Transparency = 1,
			Visible = false,
		}),
		tracer = Draw.line({ Thickness = 1, Color = color, Transparency = 1, Visible = false }),
		skeleton = {},
	}
end

local function hideEntry(entry)
	Draw.set(entry.box, { Visible = false })
	Draw.set(entry.name, { Visible = false })
	Draw.set(entry.healthBack, { Visible = false })
	Draw.set(entry.healthFill, { Visible = false })
	Draw.set(entry.distance, { Visible = false })
	Draw.set(entry.tracer, { Visible = false })
	for _, line in ipairs(entry.skeleton) do
		Draw.set(line, { Visible = false })
	end
end

local function removeEntry(player)
	local entry = entries[player]
	if not entry then
		return
	end
	hideEntry(entry)
	Draw.remove(entry.box)
	Draw.remove(entry.name)
	Draw.remove(entry.healthBack)
	Draw.remove(entry.healthFill)
	Draw.remove(entry.distance)
	Draw.remove(entry.tracer)
	for _, line in ipairs(entry.skeleton) do
		Draw.remove(line)
	end
	entries[player] = nil
end

local function ensureEntry(player)
	local entry = entries[player]
	if entry then
		return entry
	end
	entry = newEntry()
	entries[player] = entry
	return entry
end

local function drawSkeleton(entry, character)
	for index, pair in ipairs(SKELETON) do
		local line = entry.skeleton[index]
		if not line then
			line = Draw.line({ Thickness = 1, Color = color, Transparency = 1 })
			entry.skeleton[index] = line
		end
		if not line then
			return
		end

		local a = character:FindFirstChild(pair[1])
		local b = character:FindFirstChild(pair[2])
		if a and b then
			local from, fromOn = Targeting.project(a.Position)
			local to, toOn = Targeting.project(b.Position)
			if from and to and fromOn and toOn then
				Draw.set(line, { From = from, To = to, Visible = true, Color = color })
			else
				Draw.set(line, { Visible = false })
			end
		else
			Draw.set(line, { Visible = false })
		end
	end
end

local function updateEntry(entry, data)
	local character = data.character
	local head = character:FindFirstChild("Head") or data.root
	local root = data.root

	local top = head.Position + Vector3.new(0, head.Size.Y * 0.5 + 0.4, 0)
	local bottom = root.Position - Vector3.new(0, 2.6, 0)

	local topScreen, topOn = Targeting.project(top)
	local bottomScreen, bottomOn = Targeting.project(bottom)

	if not topScreen or not bottomScreen or not topOn or not bottomOn then
		hideEntry(entry)
		return
	end

	local height = math.abs(bottomScreen.Y - topScreen.Y)
	if height < 6 then
		hideEntry(entry)
		return
	end
	local width = height * 0.55
	local centerX = topScreen.X

	local viewport = Targeting.viewport()

	if Config.get("ESPBox") then
		Draw.set(entry.box, {
			Position = Vector2.new(centerX - width * 0.5, topScreen.Y),
			Size = Vector2.new(width, height),
			Color = color,
			Visible = true,
		})
	else
		Draw.set(entry.box, { Visible = false })
	end

	if Config.get("ESPName") then
		Draw.set(entry.name, {
			Position = Vector2.new(centerX, topScreen.Y - 16),
			Text = data.player.Name,
			Visible = true,
		})
	else
		Draw.set(entry.name, { Visible = false })
	end

	if Config.get("ESPDistance") then
		Draw.set(entry.distance, {
			Position = Vector2.new(centerX, bottomScreen.Y + 4),
			Text = ("%d studs"):format(math.floor(data.distance)),
			Visible = true,
		})
	else
		Draw.set(entry.distance, { Visible = false })
	end

	if Config.get("ESPHealth") then
		local health = data.humanoid.Health
		local maxHealth = math.max(data.humanoid.MaxHealth, 1)
		local ratio = math.clamp(health / maxHealth, 0, 1)
		local barX = centerX - width * 0.5 - 6
		local barHeight = height * ratio

		Draw.set(entry.healthBack, {
			Position = Vector2.new(barX, topScreen.Y),
			Size = Vector2.new(3, height),
			Visible = true,
		})
		Draw.set(entry.healthFill, {
			Position = Vector2.new(barX, bottomScreen.Y - barHeight),
			Size = Vector2.new(3, barHeight),
			Color = Color3.fromRGB(80 + 175 * (1 - ratio), 220 * ratio, 70),
			Visible = true,
		})
	else
		Draw.set(entry.healthBack, { Visible = false })
		Draw.set(entry.healthFill, { Visible = false })
	end

	if Config.get("ESPTracer") then
		Draw.set(entry.tracer, {
			From = Vector2.new(viewport.X * 0.5, viewport.Y),
			To = Vector2.new(centerX, bottomScreen.Y),
			Color = color,
			Visible = true,
		})
	else
		Draw.set(entry.tracer, { Visible = false })
	end

	if Config.get("ESPSkeleton") then
		drawSkeleton(entry, character)
	else
		for _, line in ipairs(entry.skeleton) do
			Draw.set(line, { Visible = false })
		end
	end
end

local function updateFovCircle()
	if not fovCircle then
		fovCircle = Draw.circle({ Thickness = 1, Filled = false, Color = color, Transparency = 0.5 })
	end
	if not fovCircle then
		return
	end

	if Config.get("AimFOVCircle") and Config.get("Aim") then
		local viewport = Targeting.viewport()
		Draw.set(fovCircle, {
			Position = viewport * 0.5,
			Radius = Config.get("AimFOV"),
			Visible = true,
		})
	else
		Draw.set(fovCircle, { Visible = false })
	end
end

local function tick()
	if not enabled then
		return
	end

	local seen = {}
	for _, data in ipairs(Targeting.candidates({
		teamCheck = Config.get("ESPTeamCheck"),
		maxDistance = Config.get("ESPMaxDistance"),
	})) do
		seen[data.player] = true
		local entry = ensureEntry(data.player)
		updateEntry(entry, data)
	end

	for player in pairs(entries) do
		if not seen[player] then
			hideEntry(entries[player])
		end
	end

	updateFovCircle()
end

function Visuals.setEnabled(state)
	enabled = state

	if not state then
		if connection then
			connection:Disconnect()
			connection = nil
		end
		for player in pairs(entries) do
			removeEntry(player)
		end
		if fovCircle then
			Draw.remove(fovCircle)
			fovCircle = nil
		end
		return true
	end

	if not Draw.available() then
		return false, "executor has no Drawing API"
	end

	if not connection then
		connection = RunService.RenderStepped:Connect(tick)
	end
	return true
end

function Visuals.setColor(value)
	color = value
	for _, entry in pairs(entries) do
		Draw.set(entry.box, { Color = value })
		Draw.set(entry.tracer, { Color = value })
		Draw.set(entry.skeleton[1], { Color = value })
	end
	if fovCircle then
		Draw.set(fovCircle, { Color = value })
	end
	return true
end

function Visuals.bind()
	Players.PlayerRemoving:Connect(function(player)
		removeEntry(player)
	end)
end

function Visuals.destroy()
	Visuals.setEnabled(false)
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

return Visuals
