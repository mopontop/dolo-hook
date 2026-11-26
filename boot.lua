-- boot.lua — paste this into the executor. Never fails silently.
-- Verifies the fetch and the compile, then draws the error on screen instead of
-- dying in a console nobody is watching.

local REPO = "https://raw.githubusercontent.com/mopontop/ojb-test-hub/main/release/ojb-test-hub.lua"

local function drawError(title, detail)
	local parent = (gethui and gethui()) or game:GetService("CoreGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "OJB_Error"
	gui.ResetOnSpawn = false

	local ok = pcall(function()
		gui.Parent = parent
	end)
	if not ok or not gui.Parent then
		gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(600, 150)
	frame.Position = UDim2.fromScale(0.5, 0.2)
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(28, 12, 14)
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

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
	label.Text = title .. "\n\n" .. tostring(detail)
	label.Parent = frame

	task.delay(30, function()
		gui:Destroy()
	end)
end

local okFetch, source = pcall(function()
	return game:HttpGet(REPO)
end)
if not okFetch then
	drawError("Fetch failed — the raw URL did not load", source)
	return
end

local okCompile, chunk = pcall(loadstring, source)
if not okCompile or type(chunk) ~= "function" then
	drawError("Compile failed — the release file is not valid Luau", chunk)
	return
end

local okRun, runError = pcall(chunk)
if not okRun then
	drawError("Run failed — the bundle loaded but threw", runError)
end
