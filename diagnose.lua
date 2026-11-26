-- diagnose.lua — paste into the executor. Paints each stage as it finishes, so
-- a hang can never hide the stages that already succeeded.

local REPORT = "https://raw.githubusercontent.com/mopontop/ojb-test-hub/main/release/ojb-test-hub.lua"

local lines = {}
local panel

local function render()
	if not panel then
		return
	end
	panel.Text = table.concat(lines, "\n")
	panel.Parent.Size = UDim2.fromOffset(620, 48 + (#lines * 20))
end

local function say(line)
	lines[#lines + 1] = line
	warn("[OJB diagnose] " .. line)
	render()
end

local function buildPanel()
	local parent = (gethui and gethui()) or game:GetService("CoreGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "OJB_Diagnose"
	gui.ResetOnSpawn = false
	local ok = pcall(function()
		gui.Parent = parent
	end)
	if not ok or not gui.Parent then
		local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
		gui.Parent = playerGui
	end
	if not gui.Parent then
		return
	end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(620, 48)
	frame.Position = UDim2.fromScale(0.5, 0.12)
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.Parent = frame

	panel = Instance.new("TextLabel")
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundTransparency = 1
	panel.Font = Enum.Font.Code
	panel.TextSize = 13
	panel.TextColor3 = Color3.fromRGB(235, 235, 240)
	panel.TextXAlignment = Enum.TextXAlignment.Left
	panel.TextYAlignment = Enum.TextYAlignment.Top
	panel.TextWrapped = true
	panel.Text = ""
	panel.Parent = frame

	task.delay(120, function()
		gui:Destroy()
	end)
end

buildPanel()
say("stage 1 — environment")

local okExec, execName = pcall(function()
	return identifyexecutor and identifyexecutor() or "unknown"
end)
say("  executor: " .. tostring(okExec and execName or "error"))
say("  loadstring: " .. type(loadstring) .. " | HttpGet: " .. type(game.HttpGet))

say("stage 2 — fetching release")
local okFetch, source = pcall(function()
	return game:HttpGet(REPORT)
end)

local chunk
if not okFetch then
	say("  FAILED — " .. tostring(source))
else
	say("  OK — " .. #tostring(source) .. " bytes")
	say("  head: " .. tostring(source):sub(1, 56):gsub("\n", " "))

	say("stage 3 — compiling release")
	local okCompile, result = pcall(loadstring, source)
	if okCompile and type(result) == "function" then
		chunk = result
		say("  OK")
	else
		say("  FAILED — " .. tostring(result))
	end
end

if chunk then
	say("stage 4 — running release (this is where it builds the window)")
	local okRun, runError = pcall(chunk)
	if okRun then
		say("  OK — window should be on screen, press K to toggle")
	else
		say("  FAILED — " .. tostring(runError))
	end
end

return lines
