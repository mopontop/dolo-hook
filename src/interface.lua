-- interface.lua — self-contained window library.
-- Implements the subset of the Rayfield surface that ui.lua uses, with no
-- network fetch and no third-party dependency. Plain Roblox instances only.

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Interface = {}
Interface.__index = Interface

local THEME = {
	background = Color3.fromRGB(20, 20, 26),
	panel = Color3.fromRGB(28, 28, 36),
	control = Color3.fromRGB(38, 38, 48),
	accent = Color3.fromRGB(120, 170, 255),
	text = Color3.fromRGB(235, 235, 242),
	muted = Color3.fromRGB(140, 140, 155),
	onAccent = Color3.fromRGB(16, 16, 16),
}

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local function create(class, props, children)
	local instance = Instance.new(class)
	for key, value in pairs(props or {}) do
		instance[key] = value
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	return instance
end

local function corner(instance, radius)
	create("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = instance })
	return instance
end

local function padding(instance, top, left, bottom, right)
	create("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingLeft = UDim.new(0, left or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingRight = UDim.new(0, right or 0),
		Parent = instance,
	})
	return instance
end

local function label(props)
	local defaults = {
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 13,
		TextColor3 = THEME.text,
		TextXAlignment = Enum.TextXAlignment.Left,
	}
	local class = props.ClassName or "TextLabel"
	for key, value in pairs(props) do
		if key ~= "ClassName" then
			defaults[key] = value
		end
	end
	return create(class, defaults)
end

local function tween(instance, properties, duration)
	TweenService:Create(instance, TweenInfo.new(duration or 0.12), properties):Play()
end

local function guiParent()
	local ok, hui = pcall(function()
		return gethui and gethui()
	end)
	if ok and hui then
		return hui
	end

	local okCore, core = pcall(function()
		return CoreGui
	end)
	if okCore and core then
		return core
	end

	local player = Players.LocalPlayer
	local playerGui = player and player:FindFirstChild("PlayerGui")
	return playerGui or core
end

-- ---------------------------------------------------------------- elements

local function makeSection(parent, name)
	return create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Font = FONT_BOLD,
		TextSize = 12,
		TextColor3 = THEME.accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(name),
		Parent = parent,
	})
end

local function rowBase(parent)
	return create("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Parent = parent,
	})
end

local function makeButton(parent, config)
	local button = rowBase(parent)
	create("TextLabel", {
		Size = UDim2.new(1, -8, 1, 0),
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 13,
		TextColor3 = THEME.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = config.Name or "Button",
		Parent = button,
	})

	local target = create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = button,
	})
	target.MouseEnter:Connect(function()
		tween(button, { BackgroundTransparency = 0.9, BackgroundColor3 = THEME.control }, 0.1)
	end)
	target.MouseLeave:Connect(function()
		tween(button, { BackgroundTransparency = 1 }, 0.1)
	end)
	target.MouseButton1Click:Connect(function()
		if config.Callback then
			task.spawn(config.Callback)
		end
	end)
	return button
end

local function makeToggle(parent, config)
	local row = rowBase(parent)
	label({
		Size = UDim2.new(1, -70, 1, 0),
		Text = config.Name or "Toggle",
		Parent = row,
	})

	local pill = create("Frame", {
		Size = UDim2.fromOffset(40, 20),
		Position = UDim2.new(1, -40, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = THEME.control,
		Parent = row,
	})
	corner(pill, 10)

	local knob = create("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 2, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = THEME.muted,
		Parent = pill,
	})
	corner(knob, 8)

	local hit = create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		Parent = row,
	})

	local element = { CurrentValue = config.CurrentValue == true }

	local function paint(animate)
		local props = {
			BackgroundColor3 = element.CurrentValue and THEME.accent or THEME.control,
		}
		local knobProps = {
			Position = element.CurrentValue and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
			BackgroundColor3 = element.CurrentValue and THEME.onAccent or THEME.muted,
		}
		if animate then
			tween(pill, props)
			tween(knob, knobProps)
		else
			for key, value in pairs(props) do
				pill[key] = value
			end
			for key, value in pairs(knobProps) do
				knob[key] = value
			end
		end
	end

	paint(false)

	function element:Set(value, silent)
		element.CurrentValue = value == true
		paint(true)
		if not silent and config.Callback then
			task.spawn(config.Callback, element.CurrentValue)
		end
	end

	hit.MouseButton1Click:Connect(function()
		element:Set(not element.CurrentValue)
	end)

	return element
end

local function makeSlider(parent, config)
	local range = config.Range or { 0, 100 }
	local increment = config.Increment or 1
	local minimum, maximum = range[1], range[2]

	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	label({
		Size = UDim2.new(1, -60, 0, 18),
		Text = config.Name or "Slider",
		Parent = row,
	})

	local valueLabel = label({
		Size = UDim2.new(0, 60, 0, 18),
		Position = UDim2.new(1, -60, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = THEME.muted,
		Parent = row,
	})

	local track = create("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 1, -14),
		BackgroundColor3 = THEME.control,
		Parent = row,
	})
	corner(track, 3)

	local fillBar = create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = THEME.accent,
		Parent = track,
	})
	corner(fillBar, 3)

	local knob = create("Frame", {
		Size = UDim2.fromOffset(12, 12),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = THEME.text,
		Parent = track,
	})
	corner(knob, 6)

	local hit = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 1, -20),
		BackgroundTransparency = 1,
		Text = "",
		Parent = row,
	})

	local element = { CurrentValue = config.CurrentValue or minimum }

	local function format(value)
		local rounded = math.floor(value + 0.5)
		return tostring(rounded) .. (config.Suffix and (" " .. config.Suffix) or "")
	end

	local function paint(animate)
		local alpha = (maximum > minimum) and ((element.CurrentValue - minimum) / (maximum - minimum)) or 0
		alpha = math.clamp(alpha, 0, 1)
		valueLabel.Text = format(element.CurrentValue)
		if animate then
			tween(fillBar, { Size = UDim2.fromScale(alpha, 1) }, 0.08)
			tween(knob, { Position = UDim2.new(alpha, 0, 0.5, 0) }, 0.08)
		else
			fillBar.Size = UDim2.fromScale(alpha, 1)
			knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		end
	end

	local function commit(value, silent)
		value = math.clamp(value, minimum, maximum)
		value = math.floor((value - minimum) / increment + 0.5) * increment + minimum
		value = math.clamp(value, minimum, maximum)
		element.CurrentValue = value
		paint(true)
		if not silent and config.Callback then
			task.spawn(config.Callback, value)
		end
	end

	local dragging = false
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			local relative = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			commit(minimum + (maximum - minimum) * relative)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		local relative = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		commit(minimum + (maximum - minimum) * relative)
	end)

	function element:Set(value, silent)
		commit(value, silent)
	end

	paint(false)
	return element
end

local function makeInput(parent, config)
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	label({
		Size = UDim2.new(1, 0, 0, 18),
		Text = config.Name or "Input",
		Parent = row,
	})

	local box = create("TextBox", {
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0, 22),
		BackgroundColor3 = THEME.control,
		BorderSizePixel = 0,
		Font = FONT,
		TextSize = 13,
		TextColor3 = THEME.text,
		PlaceholderText = config.PlaceholderText or "",
		PlaceholderColor3 = THEME.muted,
		Text = config.CurrentValue or "",
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = row,
	})
	corner(box, 6)
	padding(box, 0, 8, 0, 8)

	local element = { CurrentValue = box.Text }

	local function apply(text, silent)
		element.CurrentValue = text
		box.Text = text
		if not silent and config.Callback then
			task.spawn(config.Callback, text)
		end
	end

	box.FocusLost:Connect(function()
		apply(box.Text)
		if config.RemoveTextAfterFocusLost then
			box.Text = ""
		end
	end)

	function element:Set(text, silent)
		apply(text, silent)
	end

	return element
end

local function makeDropdown(parent, config)
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	local button = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = THEME.control,
		BorderSizePixel = 0,
		Font = FONT,
		TextSize = 13,
		TextColor3 = THEME.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = config.Name or "Dropdown",
		Parent = row,
	})
	corner(button, 6)
	padding(button, 0, 8, 0, 8)

	local list = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 36),
		BackgroundColor3 = THEME.panel,
		BorderSizePixel = 0,
		Visible = false,
		Parent = row,
	})
	corner(list, 6)
	create("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = list,
	})

	local element = { CurrentOption = {} }

	local function selectedText()
		if #element.CurrentOption == 0 then
			return "..."
		end
		return table.concat(element.CurrentOption, ", ")
	end

	local function paint()
		button.Text = ("%s  —  %s"):format(config.Name or "Dropdown", selectedText())
	end

	local setOpen

	local function rebuild(options)
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		local count = 0
		for _, option in ipairs(options or {}) do
			count += 1
			local item = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = THEME.control,
				BorderSizePixel = 0,
				Font = FONT,
				TextSize = 13,
				TextColor3 = THEME.text,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = option,
				LayoutOrder = count,
				Parent = list,
			})
			padding(item, 0, 8, 0, 8)
			item.MouseButton1Click:Connect(function()
				element:Set({ option })
				setOpen(false)
			end)
		end
		list.Size = UDim2.new(1, 0, 0, math.max(count * 30, 30))
		if list.Visible then
			row.Size = UDim2.new(1, 0, 0, 34 + list.Size.Y.Offset)
		end
	end

	setOpen = function(open)
		list.Visible = open
		row.Size = open and UDim2.new(1, 0, 0, 34 + list.Size.Y.Offset) or UDim2.new(1, 0, 0, 34)
	end

	button.MouseButton1Click:Connect(function()
		setOpen(not list.Visible)
	end)

	function element:Set(options, silent)
		element.CurrentOption = options or {}
		paint()
		if not silent and config.Callback then
			task.spawn(config.Callback, element.CurrentOption)
		end
	end

	function element:Refresh(options)
		config.Options = options
		rebuild(options)
	end

	rebuild(config.Options or {})
	paint()
	return element
end

local PALETTE = {
	Color3.fromRGB(120, 180, 255),
	Color3.fromRGB(255, 105, 105),
	Color3.fromRGB(120, 255, 160),
	Color3.fromRGB(255, 210, 100),
	Color3.fromRGB(200, 130, 255),
	Color3.fromRGB(255, 140, 200),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(40, 200, 230),
}

local function makeColorPicker(parent, config)
	local row = create("Frame", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	label({
		Size = UDim2.new(1, 0, 0, 18),
		Text = config.Name or "Color",
		Parent = row,
	})

	local strip = create("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 0, 24),
		BackgroundTransparency = 1,
		Parent = row,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = strip,
	})

	local element = { CurrentValue = config.Color or PALETTE[1] }

	local swatches = {}
	for index, color in ipairs(PALETTE) do
		local swatch = create("TextButton", {
			Size = UDim2.fromOffset(22, 22),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Text = "",
			LayoutOrder = index,
			Parent = strip,
		})
		corner(swatch, 6)
		swatches[index] = swatch
		swatch.MouseButton1Click:Connect(function()
			element:Set(color)
		end)
	end

	function element:Set(color, silent)
		element.CurrentValue = color
		for index, swatch in pairs(swatches) do
			local chosen = PALETTE[index] == color
			swatch.Size = chosen and UDim2.fromOffset(26, 26) or UDim2.fromOffset(22, 22)
		end
		if not silent and config.Callback then
			task.spawn(config.Callback, color)
		end
	end

	return element
end

-- ---------------------------------------------------------------- window

function Interface:CreateWindow(config)
	local parent = guiParent()

	local root = create("ScreenGui", {
		Name = "OJB_TestHub",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 10,
	})

	-- CoreGui is writable in most executors but not all; never let the fallback
	-- be an unprotected assignment.
	local parented = pcall(function()
		root.Parent = parent
	end)
	if not parented or not root.Parent then
		local player = Players.LocalPlayer
		root.Parent = player and player:FindFirstChild("PlayerGui")
	end
	if not root.Parent then
		error("no GUI parent available (CoreGui and PlayerGui both refused)")
	end

	local frame = create("Frame", {
		Size = UDim2.fromOffset(560, 400),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = THEME.background,
		BorderSizePixel = 0,
		Parent = root,
	})
	corner(frame, 10)

	local topbar = create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = THEME.panel,
		BorderSizePixel = 0,
		Parent = frame,
	})
	corner(topbar, 10)

	label({
		Size = UDim2.new(1, -80, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		Font = FONT_BOLD,
		TextSize = 14,
		Text = config.Name or "OJB Test Hub",
		Parent = topbar,
	})

	local close = create("TextButton", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -34, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = THEME.control,
		BorderSizePixel = 0,
		Font = FONT_BOLD,
		TextSize = 14,
		TextColor3 = THEME.text,
		Text = "x",
		Parent = topbar,
	})
	corner(close, 6)

	-- Closing hides the window but leaves a handle: on mobile there is no K key.
	local reopen = create("TextButton", {
		Size = UDim2.fromOffset(52, 36),
		Position = UDim2.new(0, 12, 0, 12),
		BackgroundColor3 = THEME.panel,
		BorderSizePixel = 0,
		Font = FONT_BOLD,
		TextSize = 13,
		TextColor3 = THEME.accent,
		Text = "OJB",
		Visible = false,
		Parent = root,
	})
	corner(reopen, 8)

	local function setVisible(visible)
		frame.Visible = visible
		reopen.Visible = not visible
	end

	close.MouseButton1Click:Connect(function()
		setVisible(false)
	end)
	reopen.MouseButton1Click:Connect(function()
		setVisible(true)
	end)

	local rail = create("Frame", {
		Size = UDim2.new(0, 130, 1, -52),
		Position = UDim2.new(0, 10, 0, 46),
		BackgroundTransparency = 1,
		Parent = frame,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = rail,
	})

	local body = create("Frame", {
		Size = UDim2.new(1, -152, 1, -52),
		Position = UDim2.new(0, 142, 0, 46),
		BackgroundTransparency = 1,
		Parent = frame,
	})

	local tabs = {}
	local tabOrder = 0
	local activeTab

	local window = {}

	local function selectTab(tab)
		for _, candidate in ipairs(tabs) do
			candidate.page.Visible = (candidate == tab)
			candidate.button.BackgroundColor3 = (candidate == tab) and THEME.control or THEME.background
			candidate.button.TextColor3 = (candidate == tab) and THEME.text or THEME.muted
		end
		activeTab = tab
	end

	function window:CreateTab(name)
		tabOrder += 1

		local button = create("TextButton", {
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = THEME.background,
			BorderSizePixel = 0,
			Font = FONT,
			TextSize = 13,
			TextColor3 = THEME.muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "  " .. tostring(name),
			LayoutOrder = tabOrder,
			Parent = rail,
		})
		corner(button, 6)

		local page = create("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = THEME.control,
			Visible = false,
			Parent = body,
		})
		create("UIListLayout", {
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = page,
		})
		padding(page, 0, 0, 0, 6)

		local tab = { page = page, button = button }
		tabs[#tabs + 1] = tab

		-- First tab created becomes the visible one; CreateWindow runs before any exist.
		if not activeTab then
			selectTab(tab)
		end

		button.MouseButton1Click:Connect(function()
			selectTab(tab)
		end)

		function tab:CreateSection(sectionName)
			makeSection(page, sectionName)
		end

		function tab:CreateButton(elementConfig)
			return makeButton(page, elementConfig)
		end

		function tab:CreateToggle(elementConfig)
			return makeToggle(page, elementConfig)
		end

		function tab:CreateSlider(elementConfig)
			return makeSlider(page, elementConfig)
		end

		function tab:CreateInput(elementConfig)
			return makeInput(page, elementConfig)
		end

		function tab:CreateDropdown(elementConfig)
			return makeDropdown(page, elementConfig)
		end

		function tab:CreateColorPicker(elementConfig)
			return makeColorPicker(page, elementConfig)
		end

		return tab
	end

	function window:Destroy()
		root:Destroy()
	end

	function window:Toggle()
		setVisible(not frame.Visible)
	end

	-- drag
	local dragging, dragStart, startPosition = false, nil, nil
	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = input.Position
			startPosition = frame.Position
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging or not dragStart then
			return
		end
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end)

	-- toggle keybind
	local keybind = config.ToggleUIKeybind
	if type(keybind) == "string" and keybind ~= "" then
		local key = Enum.KeyCode[keybind:upper()]
		if key then
			UserInputService.InputBegan:Connect(function(input, processed)
				if processed then
					return
				end
				if input.KeyCode == key then
					window:Toggle()
				end
			end)
		end
	end

	-- notifications
	local toastHost = create("Frame", {
		Size = UDim2.fromOffset(260, 300),
		Position = UDim2.new(1, -16, 0, 16),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Parent = root,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = toastHost,
	})

	function Interface:Notify(payload)
		payload = payload or {}
		local duration = payload.Duration or 4

		local toast = create("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = THEME.panel,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			Parent = toastHost,
		})
		corner(toast, 8)
		padding(toast, 8, 10, 8, 10)

		create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			Font = FONT_BOLD,
			TextSize = 13,
			TextColor3 = THEME.accent,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = tostring(payload.Title or "Notice"),
			Parent = toast,
		})

		create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(0, 0, 0, 20),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = FONT,
			TextSize = 12,
			TextColor3 = THEME.text,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = tostring(payload.Content or ""),
			Parent = toast,
		})

		task.delay(duration, function()
			tween(toast, { BackgroundTransparency = 1 }, 0.3)
			task.wait(0.35)
			toast:Destroy()
		end)
	end

	if #tabs > 0 then
		selectTab(tabs[1])
	end

	return window
end

return Interface
