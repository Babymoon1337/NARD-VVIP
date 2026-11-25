local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

if not RunService:IsStudio() then
	warn("NARD VVIP is restricted to Roblox Studio.")
	return
end

local player = Players.LocalPlayer
local modules = ReplicatedStorage:WaitForChild("NARDVVIP", 15)
local remotes = ReplicatedStorage:WaitForChild("NARDVVIPRemotes", 15)
if not modules or not remotes then
	warn("NARD VVIP setup is incomplete. See INSTALLATION.md.")
	return
end
local request = remotes:WaitForChild("Request", 10)
local movementRemote = remotes:WaitForChild("Movement", 10)
if not request or not movementRemote then
	warn("NARD VVIP server remotes were not created.")
	return
end

local ok, authorized, reason = pcall(function() return request:InvokeServer("authorize") end)
if not ok or not authorized then
	warn("NARD VVIP access denied: " .. tostring(reason or authorized))
	return
end

local Theme = require(modules:WaitForChild("Theme"))
local UI = require(modules:WaitForChild("UI"))
local Notifications = require(modules:WaitForChild("Notifications"))
local NPCESP = require(modules:WaitForChild("NPCESP"))
local AimTrainer = require(modules:WaitForChild("AimTrainer"))
local Radar = require(modules:WaitForChild("Radar"))
local FOV = require(modules:WaitForChild("FOV"))
local Movement = require(modules:WaitForChild("Movement"))
local Config = require(modules:WaitForChild("Config"))

local window = UI.new(player:WaitForChild("PlayerGui"), Theme)
local notifications = Notifications.new(window.Screen, Theme)
local config = Config.new(request)
local loaded, loadMessage = config:Load()
if not loaded and loadMessage ~= "No saved configuration was found." then
	notifications:Push(loadMessage, "error")
end

local esp = NPCESP.new(window.Overlay, Theme, player)
local aim = AimTrainer.new(window.Overlay, Theme, player, notifications)
local radar = Radar.new(window.Overlay, Theme)
local fov = FOV.new(window.Overlay, Theme)
local movement = Movement.new(movementRemote, authorized)
esp:Start()
aim:Start(authorized)
radar:Start()
movement:Start()

local colors = {
	Color3.fromRGB(176, 112, 255),
	Color3.fromRGB(93, 196, 255),
	Color3.fromRGB(110, 224, 169),
}

local function applyConfig()
	local data = config:Get()
	for key, value in pairs(data.esp) do esp:Set(key, value) end
	for key, value in pairs(data.aim) do aim:Set(key, value) end
	for key, value in pairs(data.radar) do radar:Set(key, value) end
	for key, value in pairs(data.fov) do
		if key == "colorIndex" then fov:Set("color", colors[value] or colors[1])
		else fov:Set(key, value) end
	end
	movement:Set("speed", data.movement.speed)
end
applyConfig()

local settingControls = {}
local categories = { "All", "Hostile", "Friendly", "Neutral" }
local categoryIndex = table.find(categories, config:Get().esp.category) or 1
local categoryButton
local function syncControls()
	local data = config:Get()
	for _, control in ipairs(settingControls) do
		local value = data[control.section][control.key]
		if control.key == "colorIndex" then value = data.fov.colorIndex end
		if value ~= nil then control.widget:Set(value) end
	end
	categoryIndex = table.find(categories, data.esp.category) or 1
	if categoryButton then categoryButton.Text = "Filter: " .. categories[categoryIndex] end
end

local function applySetting(section, key, value, module, moduleKey)
	config:Set(section, key, value)
	module:Set(moduleKey or key, value)
end

local dashboard = window:AddTab("Overview")
local overview = dashboard:AddSection("Private test session")
overview:AddButton("Save configuration", function()
	local success, message = config:Save()
	if success then notifications:Push("Configuration saved to this experience.")
	else notifications:Push(message, "error") end
end)
overview:AddButton("Load configuration", function()
	local success, message = config:Load()
	if success then applyConfig(); syncControls(); notifications:Push("Configuration loaded.") else notifications:Push(message, "error") end
end)
overview:AddButton("Reset configuration", function()
	local success, message = config:Reset()
	applyConfig()
	syncControls()
	if success then notifications:Push("Settings reset to defaults.")
	else notifications:Push(message, "error") end
end)
overview:AddButton("Aim drill preset", function()
	local data = config:Get()
	data.aim.enabled, data.aim.assist, data.aim.radius = true, false, 150
	data.fov.enabled, data.fov.radius = true, 150
	applyConfig()
	syncControls()
	notifications:Push("Aim drill preset applied.")
end)

local espTab = window:AddTab("NPC ESP")
local espControls = espTab:AddSection("Tagged test NPCs")
local function register(section, key, widget)
	table.insert(settingControls, { section = section, key = key, widget = widget })
	return widget
end
register("esp", "enabled", espControls:AddToggle("Enable visualization", config:Get().esp.enabled, function(v) applySetting("esp", "enabled", v, esp) end))
register("esp", "boxes", espControls:AddToggle("Bounding boxes", config:Get().esp.boxes, function(v) applySetting("esp", "boxes", v, esp) end))
register("esp", "names", espControls:AddToggle("Names", config:Get().esp.names, function(v) applySetting("esp", "names", v, esp) end))
register("esp", "distance", espControls:AddToggle("Distance", config:Get().esp.distance, function(v) applySetting("esp", "distance", v, esp) end))
register("esp", "health", espControls:AddToggle("Health", config:Get().esp.health, function(v) applySetting("esp", "health", v, esp) end))
register("esp", "maxDistance", espControls:AddSlider("Maximum visible distance", 50, 1000, config:Get().esp.maxDistance, function(v) applySetting("esp", "maxDistance", v, esp) end))
categoryButton = espControls:AddButton("Filter: " .. categories[categoryIndex], function(button)
	categoryIndex = categoryIndex % #categories + 1
	local category = categories[categoryIndex]
	config:Set("esp", "category", category)
	esp:Set("category", category)
	button.Text = "Filter: " .. category
end)

local aimTab = window:AddTab("Aim Trainer")
local aimControls = aimTab:AddSection("Training dummies only")
register("aim", "enabled", aimControls:AddToggle("Enable target training", config:Get().aim.enabled, function(v) applySetting("aim", "enabled", v, aim) end))
register("aim", "assist", aimControls:AddToggle("Camera assistance", config:Get().aim.assist, function(v) applySetting("aim", "assist", v, aim) end))
register("aim", "radius", aimControls:AddSlider("Target FOV radius", 30, 400, config:Get().aim.radius, function(v)
	applySetting("aim", "radius", v, aim)
end))
register("aim", "sensitivity", aimControls:AddSlider("Assistance sensitivity", 1, 12, config:Get().aim.sensitivity, function(v) applySetting("aim", "sensitivity", v, aim) end))

local radarTab = window:AddTab("Radar")
local radarControls = radarTab:AddSection("NPC radar")
register("radar", "enabled", radarControls:AddToggle("Show radar", config:Get().radar.enabled, function(v) applySetting("radar", "enabled", v, radar) end))
register("radar", "range", radarControls:AddSlider("Detection range", 50, 1000, config:Get().radar.range, function(v) applySetting("radar", "range", v, radar) end))
register("radar", "size", radarControls:AddSlider("Radar size", 120, 300, config:Get().radar.size, function(v) applySetting("radar", "size", v, radar) end))

local fovTab = window:AddTab("FOV")
local fovControls = fovTab:AddSection("Screen-space visualizer")
register("fov", "enabled", fovControls:AddToggle("Show FOV circle", config:Get().fov.enabled, function(v) applySetting("fov", "enabled", v, fov) end))
register("fov", "radius", fovControls:AddSlider("Circle radius", 30, 400, config:Get().fov.radius, function(v) applySetting("fov", "radius", v, fov) end))
register("fov", "transparency", fovControls:AddSlider("Line transparency", 0, 0.9, config:Get().fov.transparency, function(v) applySetting("fov", "transparency", v, fov) end))
fovControls:AddButton("Cycle accent color", function()
	local index = config:Get().fov.colorIndex % #colors + 1
	config:Set("fov", "colorIndex", index)
	fov:Set("color", colors[index])
end)

local movementTab = window:AddTab("Movement")
local movementControls = movementTab:AddSection("Studio-authorized character tests")
local flyToggle = movementControls:AddToggle("Server-authorized flight", false, function(v) movement:Set("fly", v) end)
local noclipToggle = movementControls:AddToggle("Server-authorized noclip", false, function(v) movement:Set("noclip", v) end)
register("movement", "speed", movementControls:AddSlider("Walk speed", 8, 32, config:Get().movement.speed, function(v)
	config:Set("movement", "speed", v)
	movement:Set("speed", v)
end))
movementControls:AddButton("Reset movement", function()
	movement:Reset()
	flyToggle:Set(false)
	noclipToggle:Set(false)
	config:Set("movement", "speed", 16)
	syncControls()
end)

window:OnClose(function() aim:Destroy() end)
window:OnClose(function() esp:Destroy() end)
window:OnClose(function() radar:Destroy() end)
window:OnClose(function() fov:Destroy() end)
window:OnClose(function() movement:Destroy() end)
