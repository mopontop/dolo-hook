-- teleport.lua — saved waypoints and player-to-player movement.
local Players = game:GetService("Players")

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

return Teleport
