-- util.lua — shared lookups. No side effects at require time.
local Players = game:GetService("Players")

local Util = {}

local notifier = function(title, content)
	print(("[Dolo.Hook] %s — %s"):format(tostring(title), tostring(content)))
end

function Util.setNotifier(fn)
	if type(fn) == "function" then
		notifier = fn
	end
end

function Util.notify(title, content)
	notifier(title, content)
end

function Util.localPlayer()
	return Players.LocalPlayer
end

function Util.getCharacter()
	local player = Players.LocalPlayer
	if not player then
		return nil
	end
	return player.Character
end

function Util.getHumanoid()
	local character = Util.getCharacter()
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

function Util.getRoot()
	local character = Util.getCharacter()
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

-- Live scan: characters gain and lose parts (tools, accessories, death) mid-session.
function Util.getParts(character)
	local parts = {}
	if not character then
		return parts
	end
	for _, instance in ipairs(character:GetDescendants()) do
		if instance:IsA("BasePart") then
			table.insert(parts, instance)
		end
	end
	return parts
end

function Util.isAlive()
	local humanoid = Util.getHumanoid()
	return humanoid ~= nil and humanoid.Health > 0
end

-- A UI that never builds is otherwise silent: nothing appears, no error is read.
-- This draws the failure with plain Roblox instances, no library involved.
function Util.showError(title, detail)
	local parent = (gethui and gethui()) or game:GetService("CoreGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "DoloHook_Error"
	gui.ResetOnSpawn = false

	local ok = pcall(function()
		gui.Parent = parent
	end)
	if not ok or not gui.Parent then
		local player = Players.LocalPlayer
		local playerGui = player and player:FindFirstChild("PlayerGui")
		gui.Parent = playerGui
	end
	if not gui.Parent then
		return
	end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(600, 150)
	frame.Position = UDim2.fromScale(0.5, 0.2)
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(28, 14, 16)
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Code
	label.TextSize = 14
	label.TextColor3 = Color3.fromRGB(255, 170, 170)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.Text = tostring(title) .. "\n\n" .. tostring(detail)
	label.Parent = frame

	task.delay(30, function()
		gui:Destroy()
	end)
end

return Util
