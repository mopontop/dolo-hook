-- teleport.lua — saved waypoints, player-to-player movement, click teleport.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Util = __require("util")

local Teleport = {}

local waypoints = {}

function Teleport.saveWaypoint(name)
	name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		return false, "empty name"
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return false, "no camera"
	end

	-- Six studs ahead of the camera keeps the saved point out of geometry.
	waypoints[name] = camera.CFrame * CFrame.new(0, 0, -6)
	return true, name
end

function Teleport.deleteWaypoint(name)
	if not waypoints[name] then
		return false, "unknown waypoint"
	end
	waypoints[name] = nil
	return true
end

function Teleport.waypointNames()
	local names = {}
	for name in pairs(waypoints) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function Teleport.toWaypoint(name)
	local target = waypoints[name]
	if not target then
		return false, "unknown waypoint"
	end

	local character = Util.getCharacter()
	if not character then
		return false, "no character"
	end
	character:PivotTo(target)
	return true
end

function Teleport.playerNames()
	local names = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= Players.LocalPlayer then
			table.insert(names, player.Name)
		end
	end
	table.sort(names)
	return names
end

function Teleport.toPlayer(name)
	local target = Players:FindFirstChild(name)
	if not target then
		return false, "player left"
	end

	local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not targetRoot then
		return false, "target has no character"
	end

	local character = Util.getCharacter()
	if not character then
		return false, "no character"
	end
	character:PivotTo(CFrame.new(targetRoot.Position + Vector3.new(0, 3, 0)))
	return true
end

function Teleport.toPosition(vector)
	if typeof(vector) ~= "Vector3" then
		return false, "not a Vector3"
	end
	local character = Util.getCharacter()
	if not character then
		return false, "no character"
	end
	character:PivotTo(CFrame.new(vector))
	return true
end

-- Click teleport: cast through the cursor and drop the character on the hit.
function Teleport.toCursor()
	local camera = workspace.CurrentCamera
	if not camera then
		return false, "no camera"
	end

	local mouse = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { Util.getCharacter() }

	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	if not result then
		return false, "nothing under the cursor"
	end
	return Teleport.toPosition(result.Position + Vector3.new(0, 3, 0))
end

function Teleport.spectate(name)
	local player = Players:FindFirstChild(name)
	if not player then
		return false, "player left"
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false, "target has no character"
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return false, "no camera"
	end
	camera.CameraSubject = humanoid
	return true
end

function Teleport.unspectate()
	local player = Players.LocalPlayer
	local humanoid = player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		workspace.CurrentCamera.CameraSubject = humanoid
		return true
	end
	return false, "no character"
end

return Teleport
