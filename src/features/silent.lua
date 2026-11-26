-- silent.lua — redirects the mouse's Hit/Target reads to the aimed player.
-- Only games that fire from Mouse.Hit/Mouse.Target see it; camera aim does not
-- move, so nothing is drawn for the shooter.
local Players = game:GetService("Players")
local Config = __require("config")
local Targeting = __require("features/targeting")

local Silent = {}

local enabled = false
local mouseMetatable
local originalIndex

local function targetEntry()
	return Targeting.closestToScreen({
		fov = Config.get("SilentFOV"),
		part = "Head",
		teamCheck = Config.get("SilentTeamCheck"),
		maxDistance = Config.get("AimMaxDistance"),
	})
end

function Silent.setEnabled(state)
	enabled = state

	if not state then
		if mouseMetatable and originalIndex ~= nil then
			mouseMetatable.__index = originalIndex
			mouseMetatable = nil
			originalIndex = nil
		end
		return true
	end

	if mouseMetatable then
		return true
	end

	if type(getrawmetatable) ~= "function" then
		return false, "executor has no getrawmetatable"
	end

	local player = Players.LocalPlayer
	if not player then
		return false, "no local player"
	end

	local ok, mouse = pcall(function()
		return player:GetMouse()
	end)
	if not ok or not mouse then
		return false, "no mouse object"
	end

	local metatableOk, metatable = pcall(getrawmetatable, mouse)
	if not metatableOk or type(metatable) ~= "table" then
		return false, "mouse metatable is protected"
	end

	originalIndex = metatable.__index
	mouseMetatable = metatable

	metatable.__index = function(self, key)
		if enabled and (key == "Hit" or key == "Target") then
			local entry = targetEntry()
			if entry then
				local part = entry.character:FindFirstChild("Head") or entry.root
				if part then
					if key == "Hit" then
						return CFrame.new(part.Position)
					end
					return part
				end
			end
		end

		if type(originalIndex) == "function" then
			return originalIndex(self, key)
		end
		return originalIndex
	end

	return true
end

function Silent.destroy()
	Silent.setEnabled(false)
end

return Silent
