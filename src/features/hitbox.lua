-- hitbox.lua — locally enlarge other players' heads so aim rays hit easier.
-- Client-side only; nothing here replicates to the server.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = __require("config")

local Hitbox = {}

local originals = {}
local connection
local enabled = false
local accumulator = 0

local function apply(player)
	if player == Players.LocalPlayer then
		return
	end
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end

	local base = originals[head]
	if not base then
		base = head.Size
		originals[head] = base
	end

	local scale = Config.get("HitboxScale")
	head.Size = Vector3.new(base.X * scale, base.Y * scale, base.Z * scale)
	head.CanCollide = false
end

local function restore()
	for part, size in pairs(originals) do
		if part.Parent then
			part.Size = size
		end
	end
	table.clear(originals)
end

function Hitbox.setEnabled(state)
	enabled = state

	if not state then
		if connection then
			connection:Disconnect()
			connection = nil
		end
		restore()
		return true
	end

	if not connection then
		connection = RunService.Heartbeat:Connect(function(delta)
			if not enabled then
				return
			end
			accumulator += delta
			if accumulator < 0.5 then
				return
			end
			accumulator = 0
			for _, player in ipairs(Players:GetPlayers()) do
				apply(player)
			end
		end)
	end
	return true
end

function Hitbox.destroy()
	Hitbox.setEnabled(false)
end

return Hitbox
