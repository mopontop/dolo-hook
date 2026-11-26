-- weapon.lua — camera stabilisers: recoil compensation, roll lock, FOV lock.
-- Client-side camera work only; nothing here edits the weapon itself.
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = __require("config")

local Weapon = {}

local connection
local enabled = false
local lastPitch
local lockedFov

local function pitchOf(cframe)
	local look = cframe.LookVector
	return math.asin(math.clamp(look.Y, -1, 1))
end

local function step()
	if not enabled then
		return
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local cframe = camera.CFrame

	if Config.get("NoRecoil") then
		local pitch = pitchOf(cframe)
		if lastPitch and pitch > lastPitch then
			-- Recoil kicks the view up; pull the rotation back down to the last
			-- stable pitch while keeping the camera position untouched.
			local strength = math.clamp(Config.get("RecoilStrength") or 1, 0, 1)
			local targetPitch = lastPitch + (pitch - lastPitch) * (1 - strength)
			local flat = Vector3.new(cframe.LookVector.X, 0, cframe.LookVector.Z)
			if flat.Magnitude > 1e-3 then
				flat = flat.Unit
				local horizontal = math.sqrt(math.max(0, 1 - targetPitch * targetPitch))
				local look = Vector3.new(flat.X * horizontal, targetPitch, flat.Z * horizontal)
				camera.CFrame = CFrame.lookAt(cframe.Position, cframe.Position + look)
			end
		end
		lastPitch = pitchOf(camera.CFrame)
	else
		lastPitch = nil
	end

	if Config.get("NoSway") then
		local current = camera.CFrame
		local right = current.RightVector
		local flatRight = Vector3.new(right.X, 0, right.Z)
		if flatRight.Magnitude > 1e-3 then
			local up = Vector3.new(0, 1, 0)
			camera.CFrame = CFrame.fromMatrix(current.Position, flatRight.Unit, up)
		end
	end

	if Config.get("NoSpread") then
		if not lockedFov then
			lockedFov = camera.FieldOfView
		end
		if math.abs(camera.FieldOfView - lockedFov) > 0.01 then
			camera.FieldOfView = lockedFov
		end
	else
		lockedFov = nil
	end
end

function Weapon.setEnabled(state)
	enabled = state
	if not state then
		if connection then
			connection:Disconnect()
			connection = nil
		end
		lastPitch = nil
		lockedFov = nil
		return true
	end
	if not connection then
		connection = RunService.RenderStepped:Connect(step)
	end
	return true
end

function Weapon.destroy()
	Weapon.setEnabled(false)
end

return Weapon
