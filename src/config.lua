-- config.lua — flag defaults, live values, optional disk persistence.
local HttpService = game:GetService("HttpService")

local Config = {}

local FOLDER = "OJBS-TestHub"
local FILE = FOLDER .. "/settings.json"

-- Color3 and instance references are session-only; only primitives persist.
Config.defaults = {
	WalkSpeed = 16,
	JumpPower = 50,
	FlySpeed = 60,
	Fly = false,
	NoClip = false,
	InfiniteJump = false,
	ESP = false,
	Fullbright = false,
	AntiAFK = true,
}

local values = {}
for key, value in pairs(Config.defaults) do
	values[key] = value
end

function Config.get(key)
	return values[key]
end

function Config.set(key, value)
	values[key] = value
end

function Config.values()
	return values
end

local function storageReady()
	return type(writefile) == "function"
		and type(readfile) == "function"
		and type(isfile) == "function"
end

local function serialisable(value)
	local kind = typeof(value)
	return kind == "number" or kind == "boolean" or kind == "string"
end

function Config.save()
	if not storageReady() then
		return false, "executor exposes no filesystem"
	end

	local payload = {}
	for key, value in pairs(values) do
		if serialisable(value) then
			payload[key] = value
		end
	end

	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, payload)
	if not ok then
		return false, "encode failed"
	end

	local wrote = pcall(function()
		if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(FOLDER) then
			makefolder(FOLDER)
		end
		writefile(FILE, encoded)
	end)
	if not wrote then
		return false, "write failed"
	end
	return true
end

function Config.load()
	if not storageReady() then
		return false, "executor exposes no filesystem"
	end
	if not isfile(FILE) then
		return false, "no saved settings"
	end

	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(readfile(FILE))
	end)
	if not ok or type(decoded) ~= "table" then
		return false, "saved settings are corrupt"
	end

	local applied = 0
	for key, default in pairs(Config.defaults) do
		local value = decoded[key]
		if value ~= nil and typeof(value) == typeof(default) then
			values[key] = value
			applied = applied + 1
		end
	end
	return true, ("%d settings applied"):format(applied)
end

return Config
