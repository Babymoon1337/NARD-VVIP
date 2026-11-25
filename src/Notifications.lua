local TweenService = game:GetService("TweenService")

local Notifications = {}

function Notifications.new(parent, theme)
	local holder = Instance.new("Frame")
	holder.Name = "Notifications"
	holder.AnchorPoint = Vector2.new(1, 1)
	holder.Position = UDim2.new(1, -18, 1, -18)
	holder.Size = UDim2.fromOffset(300, 240)
	holder.BackgroundTransparency = 1
	holder.Parent = parent

	local list = Instance.new("UIListLayout")
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.Padding = UDim.new(0, 8)
	list.Parent = holder

	local api = {}
	function api:Push(message, kind)
		local card = Instance.new("TextLabel")
		card.Size = UDim2.new(1, 0, 0, 48)
		card.BackgroundColor3 = theme.PanelRaised
		card.BackgroundTransparency = 0.08
		card.BorderSizePixel = 0
		card.Font = theme.Font
		card.Text = "  " .. tostring(message)
		card.TextColor3 = kind == "error" and theme.Bad or theme.Text
		card.TextSize = 13
		card.TextXAlignment = Enum.TextXAlignment.Left
		card.TextWrapped = true
		card.TextTransparency = 1
		card.Parent = holder
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 9)
		corner.Parent = card
		local stroke = Instance.new("UIStroke")
		stroke.Color = kind == "error" and theme.Bad or theme.Accent
		stroke.Transparency = 0.65
		stroke.Parent = card
		TweenService:Create(card, TweenInfo.new(0.18), { TextTransparency = 0 }):Play()
		task.delay(3.2, function()
			if card.Parent then
				TweenService:Create(card, TweenInfo.new(0.2), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
				task.delay(0.22, function()
					card:Destroy()
				end)
			end
		end)
	end

	return api
end

return Notifications
