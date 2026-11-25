local TweenService = game:GetService("TweenService")

local FOV = {}

function FOV.new(screen, theme)
	local circle = Instance.new("Frame")
	circle.Name = "FOVVisualizer"
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.fromScale(0.5, 0.5)
	circle.Size = UDim2.fromOffset(260, 260)
	circle.BackgroundTransparency = 1
	circle.Visible = false
	circle.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = circle
	local line = Instance.new("UIStroke")
	line.Color = theme.Accent
	line.Thickness = 1.5
	line.Transparency = 0.18
	line.Parent = circle
	local circleTween
	local lineTween
	local api = {}
	function api:Set(key, value)
		if key == "radius" then
			if circleTween then circleTween:Cancel() end
			circleTween = TweenService:Create(circle, TweenInfo.new(0.12), { Size = UDim2.fromOffset(value * 2, value * 2) })
			circleTween:Play()
		elseif key == "color" or key == "transparency" then
			if lineTween then lineTween:Cancel() end
			lineTween = TweenService:Create(line, TweenInfo.new(0.12), { [key == "color" and "Color" or "Transparency"] = value })
			lineTween:Play()
		elseif key == "enabled" then circle.Visible = value end
	end
	function api:Destroy()
		if circleTween then circleTween:Cancel() end
		if lineTween then lineTween:Cancel() end
		circle:Destroy()
	end
	return api
end

return FOV
