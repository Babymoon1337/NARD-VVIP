local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UI = {}

local function corner(instance, radius)
	local item = Instance.new("UICorner")
	item.CornerRadius = UDim.new(0, radius or 8)
	item.Parent = instance
	return item
end

local function stroke(instance, color, transparency)
	local item = Instance.new("UIStroke")
	item.Color = color
	item.Transparency = transparency or 0
	item.Parent = instance
	return item
end

function UI.new(playerGui, theme)
	local screen = Instance.new("ScreenGui")
	screen.Name = "NARDVVIP"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.DisplayOrder = 20
	screen.Parent = playerGui

	local overlay = Instance.new("ScreenGui")
	overlay.Name = "NARDVVIPOverlays"
	overlay.ResetOnSpawn = false
	overlay.IgnoreGuiInset = true
	overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	overlay.DisplayOrder = 10
	overlay.Parent = playerGui

	local scale = Instance.new("UIScale")
	scale.Parent = screen
	local function updateScale()
		local camera = workspace.CurrentCamera
		if camera then
			scale.Scale = math.clamp(math.min(camera.ViewportSize.X / 1050, camera.ViewportSize.Y / 720), 0.72, 1)
		end
	end
	updateScale()

	local root = Instance.new("Frame")
	root.Name = "Window"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromOffset(920, 590)
	root.BackgroundColor3 = theme.Background
	root.BorderSizePixel = 0
	root.Parent = screen
	corner(root, 14)
	stroke(root, theme.Stroke, 0.22)

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 54)
	header.BackgroundColor3 = theme.Panel
	header.BorderSizePixel = 0
	header.Parent = root
	corner(header, 14)
	local headerMask = Instance.new("Frame")
	headerMask.Position = UDim2.new(0, 0, 1, -14)
	headerMask.Size = UDim2.new(1, 0, 0, 14)
	headerMask.BackgroundColor3 = theme.Panel
	headerMask.BorderSizePixel = 0
	headerMask.Parent = header

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Position = UDim2.fromOffset(20, 0)
	title.Size = UDim2.new(0, 180, 1, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "NARD  /  VVIP"
	title.TextColor3 = theme.Text
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Position = UDim2.fromOffset(220, 0)
	subtitle.Size = UDim2.new(0, 250, 1, 0)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = theme.Font
	subtitle.Text = "PRIVATE DEVELOPER TOOLKIT"
	subtitle.TextColor3 = theme.Muted
	subtitle.TextSize = 10
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = header

	local content = Instance.new("Frame")
	content.Position = UDim2.fromOffset(0, 54)
	content.Size = UDim2.new(1, 0, 1, -54)
	content.BackgroundTransparency = 1
	content.Parent = root

	local sidebar = Instance.new("Frame")
	sidebar.Size = UDim2.new(0, 188, 1, 0)
	sidebar.BackgroundColor3 = theme.Panel
	sidebar.BorderSizePixel = 0
	sidebar.Parent = content

	local nav = Instance.new("Frame")
	nav.Position = UDim2.fromOffset(12, 16)
	nav.Size = UDim2.new(1, -24, 1, -32)
	nav.BackgroundTransparency = 1
	nav.Parent = sidebar
	local navList = Instance.new("UIListLayout")
	navList.Padding = UDim.new(0, 6)
	navList.Parent = nav

	local pages = Instance.new("Frame")
	pages.Position = UDim2.new(0, 188, 0, 0)
	pages.Size = UDim2.new(1, -188, 1, 0)
	pages.BackgroundTransparency = 1
	pages.Parent = content

	local search = Instance.new("TextBox")
	search.Position = UDim2.new(1, -230, 0, 12)
	search.Size = UDim2.fromOffset(210, 32)
	search.BackgroundColor3 = theme.PanelRaised
	search.BorderSizePixel = 0
	search.ClearTextOnFocus = false
	search.Font = theme.Font
	search.PlaceholderText = "Search settings..."
	search.PlaceholderColor3 = theme.Muted
	search.Text = ""
	search.TextColor3 = theme.Text
	search.TextSize = 12
	search.Parent = pages
	corner(search, 7)

	local pageHost = Instance.new("Frame")
	pageHost.Position = UDim2.fromOffset(0, 54)
	pageHost.Size = UDim2.new(1, 0, 1, -54)
	pageHost.BackgroundTransparency = 1
	pageHost.Parent = pages

	local minimize = Instance.new("TextButton")
	minimize.Position = UDim2.new(1, -82, 0, 11)
	minimize.Size = UDim2.fromOffset(30, 30)
	minimize.BackgroundColor3 = theme.PanelRaised
	minimize.BorderSizePixel = 0
	minimize.Font = theme.Font
	minimize.Text = "—"
	minimize.TextColor3 = theme.Text
	minimize.TextSize = 15
	minimize.Parent = header
	corner(minimize, 7)

	local close = Instance.new("TextButton")
	close.Position = UDim2.new(1, -44, 0, 11)
	close.Size = UDim2.fromOffset(30, 30)
	close.BackgroundColor3 = theme.PanelRaised
	close.BorderSizePixel = 0
	close.Font = theme.Font
	close.Text = "×"
	close.TextColor3 = theme.Bad
	close.TextSize = 19
	close.Parent = header
	corner(close, 7)

	local dragging, dragInput, dragStart, startPosition
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = root.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	header.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	local dragConnection = UserInputService.InputChanged:Connect(function(input)
		if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local delta = input.Position - dragStart
			root.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
		end
	end)

	local api = { Screen = screen, Overlay = overlay, Closed = false, _rows = {}, _sections = {}, _connections = { dragConnection }, _closeCallbacks = {} }
	local activePage
	local activeButton

	function api:Track(connection)
		table.insert(self._connections, connection)
		return connection
	end
	function api:OnClose(callback)
		table.insert(self._closeCallbacks, callback)
	end

	function api:Close()
		if self.Closed then return end
		self.Closed = true
		for _, callback in ipairs(self._closeCallbacks) do
			local ok, err = pcall(callback)
			if not ok then warn("[NARD VVIP] Cleanup callback failed: " .. tostring(err)) end
		end
		for _, connection in ipairs(self._connections) do
			connection:Disconnect()
		end
		overlay:Destroy()
		screen:Destroy()
	end

	function api:AddTab(label)
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 38)
		button.BackgroundColor3 = theme.Panel
		button.BorderSizePixel = 0
		button.Font = theme.Font
		button.Text = "   " .. label
		button.TextColor3 = theme.Muted
		button.TextSize = 13
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.Parent = nav
		corner(button, 7)

		local page = Instance.new("ScrollingFrame")
		page.Size = UDim2.new(1, -36, 1, -12)
		page.Position = UDim2.fromOffset(18, 6)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 3
		page.ScrollBarImageColor3 = theme.Accent
		page.CanvasSize = UDim2.new()
		page.Visible = false
		page.Parent = pageHost
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 9)
		layout.Parent = page
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
		end)

		local tab = { Page = page, _layout = layout }
		function tab:AddSection(name)
			local sectionTitle = Instance.new("TextLabel")
			sectionTitle.Name = "SectionTitle_" .. name
			sectionTitle.Size = UDim2.new(1, -8, 0, 29)
			sectionTitle.BackgroundTransparency = 1
			sectionTitle.Font = Enum.Font.GothamBold
			sectionTitle.Text = string.upper(name)
			sectionTitle.TextColor3 = theme.Accent
			sectionTitle.TextSize = 11
			sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
			sectionTitle.Parent = page

			local section = Instance.new("Frame")
			section.Name = "SettingsSection_" .. name
			section.Size = UDim2.new(1, -8, 0, 10)
			section.AutomaticSize = Enum.AutomaticSize.Y
			section.BackgroundColor3 = theme.Panel
			section.BorderSizePixel = 0
			section.Parent = page
			corner(section, 9)
			stroke(section, theme.Stroke, 0.6)
			local padding = Instance.new("UIPadding")
			padding.PaddingTop = UDim.new(0, 9)
			padding.PaddingBottom = UDim.new(0, 9)
			padding.PaddingLeft = UDim.new(0, 11)
			padding.PaddingRight = UDim.new(0, 11)
			padding.Parent = section
			local stack = Instance.new("UIListLayout")
			stack.Padding = UDim.new(0, 6)
			stack.Parent = section

			local controls = {}
			local sectionRows = {}
			table.insert(api._sections, { title = sectionTitle, frame = section, rows = sectionRows })
			local function row(label, className)
				local frame = Instance.new("Frame")
				frame.Size = UDim2.new(1, 0, 0, className == "slider" and 48 or 34)
				frame.BackgroundTransparency = 1
				frame.Parent = section
				local entry = { frame = frame, terms = string.lower(name .. " " .. label) }
				table.insert(api._rows, entry)
				table.insert(sectionRows, entry)
				local text = Instance.new("TextLabel")
				text.Size = UDim2.new(0.58, 0, 1, 0)
				text.BackgroundTransparency = 1
				text.Font = theme.Font
				text.Text = label
				text.TextColor3 = theme.Text
				text.TextSize = 12
				text.TextXAlignment = Enum.TextXAlignment.Left
				text.Parent = frame
				return frame
			end

			function controls:AddToggle(label, initial, callback)
				local frame = row(label, "toggle")
				local button2 = Instance.new("TextButton")
				button2.AnchorPoint = Vector2.new(1, 0.5)
				button2.Position = UDim2.new(1, 0, 0.5, 0)
				button2.Size = UDim2.fromOffset(42, 22)
				button2.BackgroundColor3 = initial and theme.AccentDark or theme.PanelRaised
				button2.BorderSizePixel = 0
				button2.Text = ""
				button2.Parent = frame
				corner(button2, 11)
				local dot = Instance.new("Frame")
				dot.Size = UDim2.fromOffset(16, 16)
				dot.Position = initial and UDim2.new(1, -19, 0.5, -8) or UDim2.fromOffset(3, 3)
				dot.BackgroundColor3 = theme.Text
				dot.BorderSizePixel = 0
				dot.Parent = button2
				corner(dot, 8)
				local value = initial
				local function setValue(nextValue)
					if value == nextValue then return end
					value = nextValue
					TweenService:Create(button2, TweenInfo.new(0.12), { BackgroundColor3 = value and theme.AccentDark or theme.PanelRaised }):Play()
					TweenService:Create(dot, TweenInfo.new(0.12), { Position = value and UDim2.new(1, -19, 0.5, -8) or UDim2.fromOffset(3, 3) }):Play()
					callback(value)
				end
				button2.Activated:Connect(function()
					setValue(not value)
				end)
				button2.MouseEnter:Connect(function() TweenService:Create(button2, TweenInfo.new(0.12), { BackgroundTransparency = 0.12 }):Play() end)
				button2.MouseLeave:Connect(function() TweenService:Create(button2, TweenInfo.new(0.12), { BackgroundTransparency = 0 }):Play() end)
				callback(initial)
				return { Set = function(_, v) setValue(v == true) end }
			end

			function controls:AddButton(label, callback)
				local frame = row(label, "button")
				local button2 = Instance.new("TextButton")
				button2.AnchorPoint = Vector2.new(1, 0.5)
				button2.Position = UDim2.new(1, 0, 0.5, 0)
				button2.Size = UDim2.fromOffset(96, 27)
				button2.BackgroundColor3 = theme.PanelRaised
				button2.BorderSizePixel = 0
				button2.Font = theme.Font
				button2.Text = label
				button2.TextColor3 = theme.Text
				button2.TextSize = 11
				button2.Parent = frame
				corner(button2, 6)
				button2.Activated:Connect(function() callback(button2) end)
				button2.MouseEnter:Connect(function() TweenService:Create(button2, TweenInfo.new(0.12), { BackgroundColor3 = theme.AccentDark }):Play() end)
				button2.MouseLeave:Connect(function() TweenService:Create(button2, TweenInfo.new(0.12), { BackgroundColor3 = theme.PanelRaised }):Play() end)
				return button2
			end

			function controls:AddSlider(label, minValue, maxValue, initial, callback)
				local frame = row(label, "slider")
				local valueLabel = Instance.new("TextLabel")
				valueLabel.AnchorPoint = Vector2.new(1, 0)
				valueLabel.Position = UDim2.new(1, 0, 0, 0)
				valueLabel.Size = UDim2.new(0, 80, 0, 18)
				valueLabel.BackgroundTransparency = 1
				valueLabel.Font = theme.Font
				valueLabel.TextColor3 = theme.Muted
				valueLabel.TextSize = 11
				valueLabel.TextXAlignment = Enum.TextXAlignment.Right
				valueLabel.Parent = frame
				local rail = Instance.new("Frame")
				rail.Position = UDim2.new(0, 0, 0, 26)
				rail.Size = UDim2.new(1, 0, 0, 7)
				rail.BackgroundColor3 = theme.PanelRaised
				rail.BorderSizePixel = 0
				rail.Parent = frame
				corner(rail, 5)
				local fill = Instance.new("Frame")
				fill.Size = UDim2.new(0, 0, 1, 0)
				fill.BackgroundColor3 = theme.Accent
				fill.BorderSizePixel = 0
				fill.Parent = rail
				corner(fill, 5)
				local value = initial
				local function setValue(v)
					local precision = maxValue <= 1 and 100 or 10
					value = math.clamp(math.floor(v * precision + 0.5) / precision, minValue, maxValue)
					local fraction = (value - minValue) / (maxValue - minValue)
					fill.Size = UDim2.new(fraction, 0, 1, 0)
					valueLabel.Text = tostring(value)
					callback(value)
				end
				local held = false
				rail.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						held = true
						setValue(minValue + (maxValue - minValue) * math.clamp((input.Position.X - rail.AbsolutePosition.X) / rail.AbsoluteSize.X, 0, 1))
					end
				end)
				api:Track(UserInputService.InputChanged:Connect(function(input)
					if held and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						setValue(minValue + (maxValue - minValue) * math.clamp((input.Position.X - rail.AbsolutePosition.X) / rail.AbsoluteSize.X, 0, 1))
					end
				end))
				api:Track(UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then held = false end
				end))
				setValue(initial)
				return { Set = function(_, v) setValue(v) end }
			end
			return controls
		end

		button.Activated:Connect(function()
			if activePage then activePage.Page.Visible = false end
			activePage = tab
			activeButton = button
			page.Visible = true
			for _, child in ipairs(nav:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundColor3 = child == button and theme.PanelRaised or theme.Panel
					child.TextColor3 = child == button and theme.Text or theme.Muted
				end
			end
		end)
		button.MouseEnter:Connect(function()
			if button ~= activeButton then TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = theme.PanelRaised }):Play() end
		end)
		button.MouseLeave:Connect(function()
			if button ~= activeButton then TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = theme.Panel }):Play() end
		end)
		if not activePage then button:Activate() end
		return tab
	end

	search:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(search.Text)
		for _, section in ipairs(api._sections) do
			local hasVisibleRow = false
			for _, entry in ipairs(section.rows) do
				entry.frame.Visible = query == "" or string.find(entry.terms, query, 1, true) ~= nil
				hasVisibleRow = hasVisibleRow or entry.frame.Visible
			end
			section.title.Visible = hasVisibleRow
			section.frame.Visible = hasVisibleRow
		end
	end)
	minimize.Activated:Connect(function()
		content.Visible = not content.Visible
		root.Size = content.Visible and UDim2.fromOffset(920, 590) or UDim2.fromOffset(920, 54)
	end)
	close.Activated:Connect(function() api:Close() end)
	api:Track(UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.RightControl then
			root.Visible = not root.Visible
		end
	end))
	local cameraViewportConnection
	local function bindCurrentCamera()
		if cameraViewportConnection then cameraViewportConnection:Disconnect() end
		updateScale()
		local camera = workspace.CurrentCamera
		if camera then
			cameraViewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
		end
	end
	api:OnClose(function()
		if cameraViewportConnection then cameraViewportConnection:Disconnect() end
	end)
	api:Track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCurrentCamera))
	bindCurrentCamera()

	return api
end

return UI
