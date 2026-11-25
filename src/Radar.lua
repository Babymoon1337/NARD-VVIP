local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Radar = {}

function Radar.new(screen, theme)
	local player = Players.LocalPlayer
	local panel = Instance.new("Frame")
	panel.Name = "NPCRadar"
	panel.AnchorPoint = Vector2.new(1, 1)
	panel.Position = UDim2.new(1, -24, 1, -24)
	panel.Size = UDim2.fromOffset(190, 190)
	panel.BackgroundColor3 = theme.Panel
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screen
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(1, 0)
	round.Parent = panel
	local outline = Instance.new("UIStroke")
	outline.Color = theme.Stroke
	outline.Parent = panel
	local centerMark = Instance.new("Frame")
	centerMark.AnchorPoint = Vector2.new(0.5, 0.5)
	centerMark.Position = UDim2.fromScale(0.5, 0.5)
	centerMark.Size = UDim2.fromOffset(8, 8)
	centerMark.BackgroundColor3 = theme.Text
	centerMark.BorderSizePixel = 0
	centerMark.Parent = panel
	local playerRound = Instance.new("UICorner")
	playerRound.CornerRadius = UDim.new(1, 0)
	playerRound.Parent = centerMark
	local rangeLabel = Instance.new("TextLabel")
	rangeLabel.AnchorPoint = Vector2.new(0.5, 0)
	rangeLabel.Position = UDim2.new(0.5, 0, 0, 7)
	rangeLabel.Size = UDim2.new(1, -18, 0, 16)
	rangeLabel.BackgroundTransparency = 1
	rangeLabel.Font = theme.Font
	rangeLabel.TextColor3 = theme.Muted
	rangeLabel.TextSize = 10
	rangeLabel.Parent = panel
	local markers = {}
	local settings = { enabled = false, range = 300, size = 190 }
	local connection
	local elapsed = 0
	local api = {}

	local function update()
		if not settings.enabled then return end
		local camera = workspace.CurrentCamera
		local root = player.Character and (player.Character:FindFirstChild("HumanoidRootPart") or player.Character.PrimaryPart)
		if not camera or not root then
			for _, marker in pairs(markers) do marker:Destroy() end
			table.clear(markers)
			return
		end
		local live = {}
		for _, model in ipairs(CollectionService:GetTagged("NARDTestNPC")) do
			local part = model:IsA("Model") and (model.PrimaryPart or model:FindFirstChild("HumanoidRootPart"))
			if part and not part:IsA("BasePart") then part = nil end
			if part and root then
				local delta = part.Position - root.Position
				local distance = delta.Magnitude
				if distance <= settings.range then
					live[model] = true
					local marker = markers[model]
					if not marker then
						marker = Instance.new("TextLabel")
						marker.Size = UDim2.fromOffset(62, 28)
						marker.AnchorPoint = Vector2.new(0.5, 0.5)
						marker.BackgroundTransparency = 1
						marker.Font = theme.Font
						marker.TextColor3 = theme.Accent
						marker.TextSize = 10
						marker.TextStrokeTransparency = 0.55
						marker.Parent = panel
						markers[model] = marker
					end
					local radius = settings.size * 0.42
					local forward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
					local right = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z)
					marker.Position = UDim2.new(0.5, math.clamp(delta:Dot(right) / settings.range * radius, -radius, radius), 0.5, math.clamp(-delta:Dot(forward) / settings.range * radius, -radius, radius))
					marker.Text = string.format("%s\n%.0f", model.Name, distance)
				end
			end
		end
		for model, marker in pairs(markers) do
			if not live[model] then marker:Destroy(); markers[model] = nil end
		end
		rangeLabel.Text = string.format("NPC RADAR  ·  %d studs", settings.range)
	end

	function api:Set(key, value)
		if settings[key] ~= nil then
			settings[key] = value
			if key == "size" then
				panel.Size = UDim2.fromOffset(value, value)
				rangeLabel.Position = UDim2.new(0.5, 0, 0, 7)
			elseif key == "enabled" then
				panel.Visible = value
				if not value then
					for model, marker in pairs(markers) do marker:Destroy(); markers[model] = nil end
				end
			end
		end
	end
	function api:Start()
		if not connection then
			connection = RunService.Heartbeat:Connect(function(dt)
				elapsed += dt
				if elapsed >= 0.1 then
					elapsed = 0
					update()
				end
			end)
		end
	end
	function api:Destroy()
		if connection then connection:Disconnect() end
		panel:Destroy()
	end
	return api
end

return Radar
