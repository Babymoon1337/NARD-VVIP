local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local NPCESP = {}

function NPCESP.new(screen, theme, player)
	local layer = Instance.new("Folder")
	layer.Name = "ESPOverlay"
	layer.Parent = screen
	local items = {}
	local settings = { enabled = false, names = true, boxes = true, distance = true, health = true, category = "All", maxDistance = 600 }
	local connection
	local tagConnections = {}
	local api = {}

	local function cleanup(model)
		local item = items[model]
		if item then
			item.highlight:Destroy()
			item.box:Destroy()
			item.label:Destroy()
			item.healthBack:Destroy()
			items[model] = nil
		end
	end

	local function add(model)
		if items[model] or not model:IsA("Model") then return end
		local highlight = Instance.new("Highlight")
		highlight.Name = "NARDTestHighlight"
		highlight.Adornee = model
		highlight.FillColor = theme.Accent
		highlight.OutlineColor = theme.Text
		highlight.FillTransparency = 0.82
		highlight.OutlineTransparency = 0.15
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Enabled = false
		highlight.Parent = model

		local box = Instance.new("Frame")
		box.Name = "NPCBox"
		box.BackgroundTransparency = 1
		box.BorderSizePixel = 0
		box.Visible = false
		box.Parent = layer
		local line = Instance.new("UIStroke")
		line.Color = theme.Accent
		line.Thickness = 1.5
		line.Parent = box
		local label = Instance.new("TextLabel")
		label.Name = "Info"
		label.AnchorPoint = Vector2.new(0.5, 1)
		label.Position = UDim2.new(0.5, 0, 0, -3)
		label.Size = UDim2.new(1, 24, 0, 38)
		label.BackgroundTransparency = 1
		label.Font = theme.Font
		label.TextColor3 = theme.Text
		label.TextStrokeTransparency = 0.45
		label.TextSize = 11
		label.TextWrapped = true
		label.Visible = false
		label.Parent = layer
		local healthBack = Instance.new("Frame")
		healthBack.Name = "HealthBack"
		healthBack.AnchorPoint = Vector2.new(0.5, 0)
		healthBack.Size = UDim2.new(1, 0, 0, 4)
		healthBack.BackgroundColor3 = theme.Panel
		healthBack.BorderSizePixel = 0
		healthBack.Visible = false
		healthBack.Parent = layer
		local healthFill = Instance.new("Frame")
		healthFill.Size = UDim2.fromScale(1, 1)
		healthFill.BackgroundColor3 = theme.Good
		healthFill.BorderSizePixel = 0
		healthFill.Parent = healthBack
		local raycast = RaycastParams.new()
		raycast.FilterType = Enum.RaycastFilterType.Exclude
		local excluded = { model }
		if player.Character then table.insert(excluded, player.Character) end
		raycast.FilterDescendantsInstances = excluded
		items[model] = {
			highlight = highlight,
			box = box,
			label = label,
			healthBack = healthBack,
			healthFill = healthFill,
			raycast = raycast,
			character = player.Character,
		}
	end

	local function hasLineOfSight(model, part, camera, item)
		if item.character ~= player.Character then
			item.character = player.Character
			local excluded = { model }
			if item.character then table.insert(excluded, item.character) end
			item.raycast.FilterDescendantsInstances = excluded
		end
		local result = workspace:Raycast(camera.CFrame.Position, part.Position - camera.CFrame.Position, item.raycast)
		return result == nil
	end

	local function update()
		if not settings.enabled then return end
		local camera = workspace.CurrentCamera
		if not camera then return end
		for model, item in pairs(items) do
			local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
			if root and not root:IsA("BasePart") then root = nil end
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local category = tostring(model:GetAttribute("NARDCategory") or "NPC")
			local allowed = settings.enabled and model.Parent and root and humanoid
				and (settings.category == "All" or category == settings.category)
			if allowed then
				local distance = (root.Position - camera.CFrame.Position).Magnitude
				local visible = distance <= settings.maxDistance and hasLineOfSight(model, root, camera, item)
				item.label.Text = (settings.names and model.Name or "")
					.. (settings.distance and string.format("\n%.0f studs", distance) or "")
					.. (settings.health and string.format("\nHP %d/%d", math.ceil(humanoid.Health), math.ceil(humanoid.MaxHealth)) or "")
				if visible and (settings.boxes or settings.names or settings.distance or settings.health) then
					local cf, size = model:GetBoundingBox()
					local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
					local onScreen = false
					for x = -1, 1, 2 do
						for y = -1, 1, 2 do
							for z = -1, 1, 2 do
								local point = cf:PointToWorldSpace(Vector3.new(size.X * x / 2, size.Y * y / 2, size.Z * z / 2))
								local projected, inView = camera:WorldToViewportPoint(point)
								if inView then onScreen = true end
								local xPosition = math.clamp(projected.X, 0, camera.ViewportSize.X)
								local yPosition = math.clamp(projected.Y, 0, camera.ViewportSize.Y)
								minX, maxX = math.min(minX, xPosition), math.max(maxX, xPosition)
								minY, maxY = math.min(minY, yPosition), math.max(maxY, yPosition)
							end
						end
					end
					local onViewport = onScreen and maxX > 0 and minX < camera.ViewportSize.X and maxY > 0 and minY < camera.ViewportSize.Y
					item.box.Visible = settings.boxes and onViewport
					if item.box.Visible then
						item.box.Position = UDim2.fromOffset(minX, minY)
						item.box.Size = UDim2.fromOffset(math.max(maxX - minX, 2), math.max(maxY - minY, 2))
					end
					local centerX = (minX + maxX) / 2
					item.label.Position = UDim2.fromOffset(centerX, minY - 3)
					item.label.Visible = onViewport and item.label.Text ~= ""
					item.healthBack.Position = UDim2.fromOffset(centerX, maxY + 3)
					item.healthBack.Size = UDim2.fromOffset(math.max(maxX - minX, 2), 4)
					item.healthBack.Visible = settings.health and onViewport
					local healthRatio = humanoid.MaxHealth > 0 and math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) or 0
					item.healthFill.Size = UDim2.fromScale(healthRatio, 1)
					item.healthFill.BackgroundColor3 = healthRatio > 0.5 and theme.Good or (healthRatio > 0.25 and Color3.fromRGB(255, 190, 92) or theme.Bad)
				else
					item.box.Visible = false
					item.label.Visible = false
					item.healthBack.Visible = false
				end
				item.highlight.Enabled = visible
			else
				item.box.Visible = false
				item.label.Visible = false
				item.healthBack.Visible = false
				item.highlight.Enabled = false
			end
		end
	end

	function api:Set(key, value)
		if settings[key] ~= nil then
			settings[key] = value
			if key == "enabled" and not value then
				for _, item in pairs(items) do
					item.highlight.Enabled = false
					item.box.Visible = false
					item.label.Visible = false
					item.healthBack.Visible = false
				end
			end
		end
	end
	function api:Start()
		if connection then return end
		for _, model in ipairs(CollectionService:GetTagged("NARDTestNPC")) do add(model) end
		table.insert(tagConnections, CollectionService:GetInstanceAddedSignal("NARDTestNPC"):Connect(add))
		table.insert(tagConnections, CollectionService:GetInstanceRemovedSignal("NARDTestNPC"):Connect(cleanup))
		connection = RunService.RenderStepped:Connect(update)
	end
	function api:Destroy()
		if connection then connection:Disconnect() end
		for _, item in ipairs(tagConnections) do item:Disconnect() end
		for model in pairs(items) do cleanup(model) end
		layer:Destroy()
	end
	return api
end

return NPCESP
