-- aim.lua — camera aimbot with FOV limit, smoothing, visibility and prediction.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = __require("config")
local Targeting = __require("features/targeting")

local Aim = {}

local connection
local enabled = false

local function isKeyDown()
	local key = Config.get("AimKey") or "MB2"
	if key == "MB1" then
		return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
	elseif key == "MB2" then
		return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	elseif key == "Always" then
		return true
	end
	local keyCode = Enum.KeyCode[key]
	if keyCode then
		return UserInputService:IsKeyDown(keyCode)
	end
	return false
end

local function targetPosition(entry)
	local part = Targeting.part(entry, Config.get("AimPart") or "Head")
	if not part then
		return nil
	end
	local position = part.Position

	if Config.get("AimPrediction") then
		-- 120ms lead time against the root velocity; enough to lead a walk cycle.
		local root = entry.root
		position = position + root.AssemblyLinearVelocity * 0.12
	end
	return position
end

local function step()
	if not enabled or not isKeyDown() then
		return
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local entry = Targeting.closestToScreen({
		fov = Config.get("AimFOV"),
		part = Config.get("AimPart"),
		teamCheck = Config.get("AimTeamCheck"),
		maxDistance = Config.get("AimMaxDistance"),
		fovWeight = true,
	})
	if not entry then
		return
	end

	if Config.get("AimVisibleOnly") and not Targeting.visible(entry) then
		return
	end

	local position = targetPosition(entry)
	if not position then
		return
	end

	local speed = math.clamp(tonumber(Config.get("AimSmooth")) or 0.35, 0.01, 1)
	local alpha = 1 - speed

	local goal = CFrame.lookAt(camera.CFrame.Position, position)
	camera.CFrame = camera.CFrame:Lerp(goal, alpha)
end

function Aim.setEnabled(state)
	enabled = state
	if not state then
		if connection then
			connection:Disconnect()
			connection = nil
		end
		return true
	end
	if not connection then
		connection = RunService.RenderStepped:Connect(step)
	end
	return true
end

function Aim.destroy()
	enabled = false
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

return Aim
