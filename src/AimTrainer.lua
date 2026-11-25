local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local AimTrainer = {}

function AimTrainer.new(screen, theme, player, notifications)
	local indicator = Instance.new("TextLabel")
	indicator.Name = "TrainingTarget"
	indicator.AnchorPoint = Vector2.new(0.5, 0.5)
	indicator.Size = UDim2.fromOffset(190, 38)
	indicator.BackgroundColor3 = theme.Panel
	indicator.BackgroundTransparency = 0.1
	indicator.BorderSizePixel = 0
	indicator.Font = theme.Font
	indicator.TextColor3 = theme.Text
	indicator.TextSize = 12
	indicator.Visible = false
	indicator.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = indicator
	local outline = Instance.new("UIStroke")
	outline.Color = theme.Accent
	outline.Parent = indicator

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "TrainingStats"
	statsLabel.AnchorPoint = Vector2.new(0.5, 1)
	statsLabel.Position = UDim2.new(0.5, 0, 1, -18)
	statsLabel.Size = UDim2.fromOffset(260, 22)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Font = theme.Font
	statsLabel.TextColor3 = theme.Muted
	statsLabel.TextSize = 11
	statsLabel.Visible = false
	statsLabel.Parent = screen

	local settings = { enabled = false, assist = false, radius = 130, sensitivity = 8 }
	local activeSince, lastTarget, attempts, hits = nil, nil, 0, 0
	local target
	local renderConnection
	local clickConnection
	local tagConnections = {}
	local dummies = {}
	local raycast = RaycastParams.new()
	raycast.FilterType = Enum.RaycastFilterType.Exclude
	local api = {}

	local function visible(part, model)
		local camera = workspace.CurrentCamera
		if not camera then return false end
		local excluded = { model }
		if player.Character then table.insert(excluded, player.Character) end
		raycast.FilterDescendantsInstances = excluded
		return workspace:Raycast(camera.CFrame.Position, part.Position - camera.CFrame.Position, raycast) == nil
	end

	local function findTarget()
		local camera = workspace.CurrentCamera
		if not camera then return nil end
		local center = camera.ViewportSize / 2
		local best, bestPixel = nil, settings.radius
		for model in pairs(dummies) do
			local humanoid = model:IsA("Model") and model:FindFirstChildOfClass("Humanoid")
			local part = model:IsA("Model") and (model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChild("HumanoidRootPart"))
			if part and not part:IsA("BasePart") then part = nil end
			if humanoid and humanoid.Health > 0 and part then
				local screenPoint, onScreen = camera:WorldToViewportPoint(part.Position)
				local pixel = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
				if onScreen and pixel < bestPixel and visible(part, model) then
					best, bestPixel = { model = model, part = part, humanoid = humanoid, pixel = pixel }, pixel
				end
			end
		end
		return best
	end

	local function tick(dt)
		local camera = workspace.CurrentCamera
		if not camera or not settings.enabled then
			if target then lastTarget = nil; activeSince = nil end
			target = nil
			indicator.Visible = false
			statsLabel.Visible = false
			return
		end
		statsLabel.Visible = true
		statsLabel.Text = string.format("TRAINING  ·  %d hits / %d attempts  ·  %.0f%%", hits, attempts, attempts > 0 and hits / attempts * 100 or 0)
		target = findTarget()
		if target then
			local point = camera:WorldToViewportPoint(target.part.Position)
			indicator.Position = UDim2.fromOffset(point.X, point.Y - 36)
			indicator.Text = string.format(" %s  |  %.0f studs", target.model.Name, (target.part.Position - camera.CFrame.Position).Magnitude)
			indicator.Visible = true
			if target.model ~= lastTarget then activeSince = os.clock(); lastTarget = target.model end
			if settings.assist then
				local desired = CFrame.lookAt(camera.CFrame.Position, target.part.Position)
				camera.CFrame = camera.CFrame:Lerp(desired, math.clamp(settings.sensitivity * dt, 0, 0.16))
			end
		else
			indicator.Visible = false
			lastTarget = nil
			activeSince = nil
		end
	end

	function api:Set(key, value)
		if settings[key] ~= nil then settings[key] = value end
		if key == "enabled" and not value then
			indicator.Visible = false
			statsLabel.Visible = false
			target, lastTarget, activeSince = nil, nil, nil
		end
	end
	function api:Start(authorized)
		if not authorized or renderConnection then return end
		for _, model in ipairs(CollectionService:GetTagged("NARDTrainingDummy")) do dummies[model] = true end
		table.insert(tagConnections, CollectionService:GetInstanceAddedSignal("NARDTrainingDummy"):Connect(function(model)
			if model:IsA("Model") then dummies[model] = true end
		end))
		table.insert(tagConnections, CollectionService:GetInstanceRemovedSignal("NARDTrainingDummy"):Connect(function(model)
			dummies[model] = nil
		end))
		renderConnection = RunService.RenderStepped:Connect(tick)
		clickConnection = UserInputService.InputBegan:Connect(function(input, processed)
			if processed or not settings.enabled or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			attempts += 1
			local camera = workspace.CurrentCamera
			local mouse = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
			if target and camera and target.model.Parent and target.part.Parent and target.humanoid.Health > 0 then
				local point = camera:WorldToViewportPoint(target.part.Position)
				if (Vector2.new(point.X, point.Y) - mouse).Magnitude <= 35 then
					hits += 1
					local reaction = activeSince and (os.clock() - activeSince) or 0
					notifications:Push(string.format("Hit %s  ·  %.0f ms  ·  %d%% accuracy", target.model.Name, reaction * 1000, math.floor(hits / attempts * 100)))
					activeSince = os.clock()
				end
			end
		end)
	end
	function api:GetStats()
		return { hits = hits, attempts = attempts, accuracy = attempts > 0 and hits / attempts * 100 or 0 }
	end
	function api:Destroy()
		if renderConnection then renderConnection:Disconnect() end
		if clickConnection then clickConnection:Disconnect() end
		for _, connection in ipairs(tagConnections) do connection:Disconnect() end
		table.clear(dummies)
		indicator:Destroy()
		statsLabel:Destroy()
	end
	return api
end

return AimTrainer
