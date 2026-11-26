-- triggerbot.lua — fires when a target sits under the crosshair.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local Config = __require("config")
local Targeting = __require("features/targeting")

local Triggerbot = {}

local connection
local enabled = false
local lastShot = 0

local function keyHeld()
	local key = Config.get("TriggerKey") or "MB2"
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

local function click()
	local ok = pcall(function()
		mouse1click()
	end)
	if ok then
		return true
	end
	-- Fallback: the virtual user path most executors allow.
	local fallback = pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton1(Vector2.new())
	end)
	return fallback
end

local function underCrosshair()
	local viewport = Targeting.viewport()
	local center = viewport * 0.5
	local fov = Config.get("TriggerFOV") or 4

	for _, entry in ipairs(Targeting.candidates({
		teamCheck = Config.get("TriggerTeamCheck"),
		maxDistance = Config.get("TriggerMaxDistance"),
	})) do
		local parts = { entry.character:FindFirstChild("Head"), entry.root }
		for _, part in ipairs(parts) do
			if part then
				local screen, onScreen = Targeting.project(part.Position)
				if screen and onScreen and (screen - center).Magnitude <= fov then
					if Config.get("TriggerVisibleOnly") and not Targeting.visible(entry) then
						continue
					end
					return entry
				end
			end
		end
	end
	return nil
end

local function step()
	if not enabled or not keyHeld() then
		return
	end

	local now = os.clock()
	if now - lastShot < (Config.get("TriggerDelay") or 0.05) then
		return
	end

	if underCrosshair() then
		lastShot = now
		click()
	end
end

function Triggerbot.setEnabled(state)
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

function Triggerbot.destroy()
	Triggerbot.setEnabled(false)
end

return Triggerbot
