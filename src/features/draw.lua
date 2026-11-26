-- draw.lua — thin wrapper over the executor Drawing API.
-- Every helper returns nil when Drawing is missing, so callers stay simple.
local Draw = {}

local library
do
	local ok, result = pcall(function()
		return Drawing
	end)
	if ok and type(result) == "table" and type(result.new) == "function" then
		library = result
	end
end

function Draw.available()
	return library ~= nil
end

local function make(kind, properties)
	if not library then
		return nil
	end

	local ok, object = pcall(function()
		return library.new(kind)
	end)
	if not ok or not object then
		return nil
	end

	for key, value in pairs(properties or {}) do
		pcall(function()
			object[key] = value
		end)
	end
	return object
end

local function set(object, properties)
	if not object then
		return
	end
	for key, value in pairs(properties) do
		pcall(function()
			object[key] = value
		end)
	end
end

local function remove(object)
	if not object then
		return
	end
	pcall(function()
		object:Remove()
	end)
end

Draw.set = set
Draw.remove = remove

function Draw.line(properties)
	return make("Line", properties)
end

function Draw.text(properties)
	return make("Text", properties)
end

function Draw.square(properties)
	return make("Square", properties)
end

function Draw.circle(properties)
	return make("Circle", properties)
end

function Draw.quad(properties)
	return make("Quad", properties)
end

return Draw
