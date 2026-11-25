local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

assert(RunService:IsStudio(), "Run this regression script from Roblox Studio.")

local player = Players.LocalPlayer
local modules = ReplicatedStorage:WaitForChild("NARDVVIP", 10)
assert(modules, "ReplicatedStorage.NARDVVIP is missing.")

local Theme = require(modules:WaitForChild("Theme"))
local UI = require(modules:WaitForChild("UI"))
local NPCESP = require(modules:WaitForChild("NPCESP"))
local Movement = require(modules:WaitForChild("Movement"))

local failures = {}
local function test(name, callback)
	local ok, err = xpcall(callback, debug.traceback)
	if ok then
		print("[NARD regression PASS] " .. name)
	else
		table.insert(failures, name .. ": " .. tostring(err))
		warn("[NARD regression FAIL] " .. name .. "\n" .. tostring(err))
	end
end

local window
test("UI spacing and empty-section search", function()
	window = UI.new(player:WaitForChild("PlayerGui"), Theme)
	local tab = window:AddTab("Regression")
	tab:AddSection("Alpha controls"):AddButton("Alpha setting", function() end)
	tab:AddSection("Beta controls"):AddButton("Beta setting", function() end)

	local title = window.Screen:FindFirstChild("Title", true)
	local subtitle = window.Screen:FindFirstChild("Subtitle", true)
	assert(title and subtitle, "Header labels are missing.")
	task.wait()
	assert(title.AbsolutePosition.X + title.AbsoluteSize.X <= subtitle.AbsolutePosition.X, "Header labels overlap.")

	local search = window.Screen:FindFirstChildWhichIsA("TextBox", true)
	assert(search, "Settings search box is missing.")
	search.Text = "alpha setting"
	task.wait()
	assert(window._sections[1].frame.Visible and window._sections[1].title.Visible, "Matching section should remain visible.")
	assert(not window._sections[2].frame.Visible and not window._sections[2].title.Visible, "Empty search sections should be hidden.")
	search.Text = ""
	task.wait()
	assert(window._sections[1].frame.Visible and window._sections[2].frame.Visible, "Clearing search should restore sections.")
end)

test("CurrentCamera replacement rescaling", function()
	assert(window, "UI test must initialize first.")
	local previousCamera = workspace.CurrentCamera
	local replacement = Instance.new("Camera")
	replacement.Parent = workspace
	local ok, err = xpcall(function()
		workspace.CurrentCamera = replacement
		task.wait()
		local expected = math.clamp(math.min(replacement.ViewportSize.X / 1050, replacement.ViewportSize.Y / 720), 0.72, 1)
		local scale = window.Screen:FindFirstChildOfClass("UIScale")
		assert(scale and math.abs(scale.Scale - expected) < 0.01, "UIScale did not update for the replacement camera.")
	end, debug.traceback)
	workspace.CurrentCamera = previousCamera
	replacement:Destroy()
	if not ok then error(err) end
end)

test("ESP overlays remain independent of bounding boxes", function()
	assert(window, "UI test must initialize first.")
	local camera = workspace.CurrentCamera
	assert(camera, "Workspace.CurrentCamera is missing.")
	local previousType, previousCFrame = camera.CameraType, camera.CFrame
	local dummy = Instance.new("Model")
	dummy.Name = "NARDRegressionDummy"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.CanCollide = false
	root.Size = Vector3.new(4, 6, 2)
	root.CFrame = camera.CFrame * CFrame.new(0, 0, -30)
	root.Parent = dummy
	dummy.PrimaryPart = root
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 60
	humanoid.Parent = dummy
	dummy.Parent = workspace
	CollectionService:AddTag(dummy, "NARDTestNPC")

	local esp
	local ok, err = xpcall(function()
		camera.CameraType = Enum.CameraType.Scriptable
		esp = NPCESP.new(window.Overlay, Theme, player)
		esp:Start()
		esp:Set("enabled", true)
		esp:Set("boxes", false)
		task.wait(0.2)
		local layer = window.Overlay:FindFirstChild("ESPOverlay")
		local box = layer and layer:FindFirstChild("NPCBox")
		local label = layer and layer:FindFirstChild("Info")
		local health = layer and layer:FindFirstChild("HealthBack")
		assert(box and label and health, "Expected ESP overlay instances are missing.")
		assert(not box.Visible, "Bounding box should be hidden when disabled.")
		assert(label.Visible and label.Text ~= "", "NPC label should remain visible without the bounding box.")
		assert(health.Visible, "Health bar should remain visible without the bounding box.")

		esp:Set("names", false)
		esp:Set("distance", false)
		esp:Set("health", false)
		esp:Set("boxes", true)
		task.wait(0.1)
		assert(box.Visible, "Bounding box toggle should operate independently.")
		assert(not label.Visible and not health.Visible, "Label and health toggles should hide their own overlays.")
	end, debug.traceback)
	if esp then esp:Destroy() end
	CollectionService:RemoveTag(dummy, "NARDTestNPC")
	dummy:Destroy()
	camera.CameraType, camera.CFrame = previousType, previousCFrame
	if not ok then error(err) end
end)

test("Client movement reset sends one complete reset request", function()
	local requests = {}
	local remote = {
		FireServer = function(_, action, value)
			table.insert(requests, { action = action, value = value })
		end,
	}
	local movement = Movement.new(remote, true)
	movement:Set("fly", true)
	movement:Set("noclip", true)
	movement:Reset()
	assert(requests[1].action == "fly" and requests[1].value == true, "Flight enable request was not sent.")
	assert(requests[2].action == "noclip" and requests[2].value == true, "Noclip enable request was not sent.")
	assert(requests[3].action == "reset", "Reset must independently clear server movement states.")
	assert(#requests == 3, "Reset should not require follow-up state-disable requests.")
	movement:Destroy()
end)

test("Server reset restores active movement effects", function()
	local remotes = ReplicatedStorage:WaitForChild("NARDVVIPRemotes", 10)
	assert(remotes, "Server remotes are missing.")
	local request = remotes:WaitForChild("Request", 10)
	local movementRemote = remotes:WaitForChild("Movement", 10)
	assert(request and movementRemote, "Movement remotes are missing.")
	local authorized = request:InvokeServer("authorize")
	assert(authorized, "Add this test user's UserId to the server Studio allowlist.")

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	assert(character and humanoid and root, "A loaded player character is required.")
	local originalCollision = {}
	for _, item in ipairs(character:GetDescendants()) do
		if item:IsA("BasePart") then originalCollision[item] = item.CanCollide end
	end

	local movement = Movement.new(movementRemote, true)
	local ok, err = xpcall(function()
		movement:Set("fly", true)
		movement:Set("noclip", true)
		movement:Set("speed", 25)
		task.wait(0.25)
		assert(root:FindFirstChild("NARDFlightVelocity"), "Server did not enable flight.")
		assert(humanoid.WalkSpeed == 25, "Server did not apply the test walk speed.")
		for part in pairs(originalCollision) do
			assert(not part.CanCollide, "Server did not enable noclip.")
		end

		movement:Reset()
		task.wait(0.25)
		assert(not root:FindFirstChild("NARDFlightVelocity"), "Reset left flight active.")
		assert(humanoid.WalkSpeed == 16, "Reset did not restore default walk speed.")
		for part, canCollide in pairs(originalCollision) do
			if part.Parent then assert(part.CanCollide == canCollide, "Reset did not restore collision state.") end
		end
		movement:Destroy()
	end, debug.traceback)
	movement:Reset()
	if not ok then error(err) end
end)

test("UI cleanup continues after a failing close callback", function()
	assert(window and not window.Closed, "UI test window is unavailable.")
	local laterCleanupRan = false
	window:OnClose(function() error("Intentional regression-test callback failure.") end)
	window:OnClose(function() laterCleanupRan = true end)
	window:Close()
	assert(laterCleanupRan, "A failing close callback prevented later cleanup.")
	assert(window.Screen.Parent == nil and window.Overlay.Parent == nil, "Close did not destroy the UI and overlays.")
end)

if #failures > 0 then
	error(string.format("NARD Studio regression suite failed (%d):\n%s", #failures, table.concat(failures, "\n")))
end
print("[NARD regression PASS] All Studio regression tests completed.")
