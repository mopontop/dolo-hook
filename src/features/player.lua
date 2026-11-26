-- player.lua — character features: speed, jump, fly, noclip, infinite jump.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = __require("config")
local Util = __require("util")

local Player = {}

local state = {
	flying = false,
	flyBody = nil,
	flyConn = nil,
	noclipConn = nil,
	jumpConn = nil,
	touched = {},
}

local function destroyFlyBody()
	if state.flyBody then
		state.flyBody:Destroy()
		state.flyBody = nil
	end
end

local function startFlyBody()
	destroyFlyBody()
	local root = Util.getRoot()
	if not root then
		return false
	end

	local body = Instance.new("BodyVelocity")
	body.Name = "OJB_Fly"
	body.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	body.Velocity = Vector3.zero
	body.Parent = root
	state.flyBody = body
	return true
end

-- Camera-relative WASD with Space / LeftControl on the vertical axis.
local function readMoveVector()
	local camera = workspace.CurrentCamera
	if not camera then
		return Vector3.zero
	end

	local direction = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		direction += camera.CFrame.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		direction -= camera.CFrame.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		direction += camera.CFrame.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		direction -= camera.CFrame.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		direction += Vector3.yAxis
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		direction -= Vector3.yAxis
	end

	if direction.Magnitude > 0 then
		direction = direction.Unit
	end
	return direction
end

function Player.setWalkSpeed(value)
	local humanoid = Util.getHumanoid()
	if not humanoid then
		return false, "no character"
	end
	Config.set("WalkSpeed", value)
	humanoid.WalkSpeed = value
	return true
end

function Player.setJumpPower(value)
	local humanoid = Util.getHumanoid()
	if not humanoid then
		return false, "no character"
	end
	Config.set("JumpPower", value)
	humanoid.UseJumpPower = true
	humanoid.JumpPower = value
	return true
end

function Player.setNoClip(enabled)
	if enabled then
		if state.noclipConn then
			return true
		end
		state.noclipConn = RunService.Stepped:Connect(function()
			for _, part in ipairs(Util.getParts(Util.getCharacter())) do
				if part.CanCollide then
					state.touched[part] = true
					part.CanCollide = false
				end
			end
		end)
		return true
	end

	if state.noclipConn then
		state.noclipConn:Disconnect()
		state.noclipConn = nil
	end
	for part in pairs(state.touched) do
		if part.Parent then
			part.CanCollide = true
		end
	end
	table.clear(state.touched)
	return true
end

function Player.setFly(enabled)
	state.flying = enabled

	local humanoid = Util.getHumanoid()

	if not enabled then
		destroyFlyBody()
		if state.flyConn then
			state.flyConn:Disconnect()
			state.flyConn = nil
		end
		if humanoid then
			humanoid.PlatformStand = false
		end
		return true
	end

	if not startFlyBody() then
		state.flying = false
		return false, "no character"
	end
	if humanoid then
		humanoid.PlatformStand = true
	end

	if not state.flyConn then
		state.flyConn = RunService.RenderStepped:Connect(function()
			if not state.flying then
				return
			end
			-- Respawn destroys the attachment; rebuild against the new root.
			if not state.flyBody or not state.flyBody.Parent then
				if not startFlyBody() then
					return
				end
			end
			state.flyBody.Velocity = readMoveVector() * Config.get("FlySpeed")
		end)
	end
	return true
end

function Player.setInfiniteJump(enabled)
	if not enabled then
		if state.jumpConn then
			state.jumpConn:Disconnect()
			state.jumpConn = nil
		end
		return true
	end

	if state.jumpConn then
		return true
	end
	state.jumpConn = UserInputService.JumpRequest:Connect(function()
		local humanoid = Util.getHumanoid()
		if humanoid and humanoid.Health > 0 then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
	return true
end

function Player.resetCharacter()
	local humanoid = Util.getHumanoid()
	if not humanoid then
		return false, "no character"
	end
	humanoid.Health = 0
	return true
end

-- Re-apply persistent settings on respawn; a respawn hands us a fresh character.
function Player.bind()
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end

	localPlayer.CharacterAdded:Connect(function(character)
		task.wait(0.4)
		if character ~= Util.getCharacter() then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.get("WalkSpeed")
			humanoid.UseJumpPower = true
			humanoid.JumpPower = Config.get("JumpPower")
		end

		if Config.get("Fly") then
			Player.setFly(true)
		end
		if Config.get("NoClip") then
			Player.setNoClip(true)
		end
	end)
end

function Player.destroy()
	Player.setFly(false)
	Player.setNoClip(false)
	Player.setInfiniteJump(false)
end

return Player
