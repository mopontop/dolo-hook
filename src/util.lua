-- util.lua — shared lookups. No side effects at require time.
local Players = game:GetService("Players")

local Util = {}

local notifier = function(title, content)
	print(("[OJB] %s — %s"):format(tostring(title), tostring(content)))
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

return Util
