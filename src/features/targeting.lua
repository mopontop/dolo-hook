-- targeting.lua — shared player/character queries, projection and line of sight.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Targeting = {}

local RAY_PARAMS = RaycastParams.new()
RAY_PARAMS.FilterType = Enum.RaycastFilterType.Exclude

local function localPlayer()
	return Players.LocalPlayer
end

local function aliveCharacter(player)
	local character = player and player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character, humanoid
end

function Targeting.isAlly(player)
	local me = localPlayer()
	if not me or not me.Team then
		return false
	end
	return player.Team == me.Team
end

function Targeting.candidates(options)
	options = options or {}
	local list = {}
	local me = localPlayer()
	if not me then
		return list
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		return list
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= me then
			local character, humanoid = aliveCharacter(player)
			if character and (not options.teamCheck or not Targeting.isAlly(player)) then
				local root = character:FindFirstChild("HumanoidRootPart")
				if root then
					local distance = (root.Position - camera.CFrame.Position).Magnitude
					if not options.maxDistance or distance <= options.maxDistance then
						list[#list + 1] = {
							player = player,
							character = character,
							humanoid = humanoid,
							root = root,
							distance = distance,
						}
					end
				end
			end
		end
	end
	return list
end

function Targeting.part(entry, name)
	local character = entry.character
	if name == "Head" then
		return character:FindFirstChild("Head")
	end
	if name == "Torso" then
		return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	end
	return entry.root
end

function Targeting.project(position)
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil, false, 0
	end
	local screen, onScreen = camera:WorldToViewportPoint(position)
	if screen.Z <= 0 then
		onScreen = false
	end
	return Vector2.new(screen.X, screen.Y), onScreen, screen.Z
end

function Targeting.viewport()
	local camera = Workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end
	return Vector2.new(1920, 1080)
end

-- Line of sight against the world only; characters are excluded so a wall is
-- what stops the ray, not the target's own limbs.
function Targeting.visible(entry)
	local camera = Workspace.CurrentCamera
	if not camera then
		return false
	end
	local origin = camera.CFrame.Position
	local targetPosition = entry.root.Position

	RAY_PARAMS.FilterDescendantsInstances = { localPlayer().Character, entry.character }

	local result = Workspace:Raycast(origin, targetPosition - origin, RAY_PARAMS)
	return result == nil
end

function Targeting.closestToScreen(options)
	options = options or {}
	local viewport = Targeting.viewport()
	local center = viewport * 0.5
	local fov = options.fov or 0

	local best, bestScore
	for _, entry in ipairs(Targeting.candidates(options)) do
		local part = Targeting.part(entry, options.part or "Head")
		if part then
			local screen, onScreen = Targeting.project(part.Position)
			if screen and onScreen then
				local distance = (screen - center).Magnitude
				if fov <= 0 or distance <= fov then
					local score = distance + (options.fovWeight and entry.distance * 0.01 or 0)
					if not bestScore or score < bestScore then
						best, bestScore = entry, score
					end
				end
			end
		end
	end
	return best
end

return Targeting
