-- diagnose.lua — paste this into the executor first. No dependencies.
-- Every stage prints to console and to an on-screen report.

local REPORT = "https://raw.githubusercontent.com/mopontop/ojb-test-hub/main/release/ojb-test-hub.lua"
local RAYFIELD = "https://sirius.menu/rayfield"

local lines = {}
local function say(line)
	lines[#lines + 1] = line
	warn("[OJB diagnose] " .. line)
end

local function show()
	if not (gethui or game:GetService("CoreGui")) then
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "OJB_Diagnose"
	gui.ResetOnSpawn = false
	pcall(function()
		gui.Parent = gethui and gethui() or game:GetService("CoreGui")
	end)
	if not gui.Parent then
		gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(560, 44 + (#lines * 20))
	frame.Position = UDim2.fromScale(0.5, 0.15)
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Code
	label.TextSize = 13
	label.TextColor3 = Color3.fromRGB(235, 235, 240)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.Text = table.concat(lines, "\n")
	label.Parent = frame

	task.delay(45, function()
		gui:Destroy()
	end)
end

-- stage 1: environment
local okExec, execName = pcall(function()
	if identifyexecutor then
		return identifyexecutor()
	end
	return "unknown (no identifyexecutor)"
end)
say("executor: " .. tostring(okExec and execName or "error"))

say("loadstring: " .. type(loadstring))
say("HttpGet: " .. type(game.HttpGet))

-- stage 2: release fetch
local releaseSource
local okFetch, fetchResult = pcall(function()
	return game:HttpGet(REPORT)
end)
if okFetch then
	releaseSource = fetchResult
	say("release fetch: OK, " .. tostring(#tostring(fetchResult)) .. " bytes")
	local head = tostring(fetchResult):sub(1, 60):gsub("\n", " ")
	say("release head: " .. head)
else
	say("release fetch: FAILED — " .. tostring(fetchResult))
end

-- stage 3: release compile
local chunk
if releaseSource then
	local okCompile, compileResult = pcall(loadstring, releaseSource)
	if okCompile and type(compileResult) == "function" then
		chunk = compileResult
		say("release compile: OK")
	else
		say("release compile: FAILED — " .. tostring(compileResult))
	end
end

-- stage 4: rayfield fetch + compile
local okLib, libResult = pcall(function()
	return game:HttpGet(RAYFIELD)
end)
if okLib then
	say("rayfield fetch: OK, " .. tostring(#tostring(libResult)) .. " bytes")
	local okLibCompile, libChunk = pcall(loadstring, libResult)
	if okLibCompile and type(libChunk) == "function" then
		say("rayfield compile: OK")
	else
		say("rayfield compile: FAILED — " .. tostring(libChunk))
	end
else
	say("rayfield fetch: FAILED — " .. tostring(libResult))
end

show()

-- stage 5: run the release, reporting the real error instead of dying silently
if chunk then
	local okRun, runError = pcall(chunk)
	if not okRun then
		say("release run: FAILED — " .. tostring(runError))
	else
		say("release run: OK")
	end
	show()
end

return lines
