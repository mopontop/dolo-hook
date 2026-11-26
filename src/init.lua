-- init.lua — entry point. Runs once after every module is registered.
local Util = __require("util")
local Player = __require("features/player")
local ESP = __require("features/esp")
local UI = __require("ui")

local VERSION = "0.1.0"

local function main()
	-- Re-executing the loadstring must replace the running instance, not stack one.
	local previous = _G.OJB_TestHub
	if previous and type(previous.destroy) == "function" then
		pcall(previous.destroy)
	end

	Player.bind()
	ESP.bind()

	local ok, err = pcall(UI.build)
	if not ok then
		Util.notify("OJB Test Hub", "failed to build UI: " .. tostring(err))
		error(err)
	end

	local handle = {
		version = VERSION,
		destroy = function()
			UI.destroy()
			Player.destroy()
			ESP.destroy()
			if _G.OJB_TestHub == handle then
				_G.OJB_TestHub = nil
			end
		end,
	}

	_G.OJB_TestHub = handle
	return handle
end

return main()
