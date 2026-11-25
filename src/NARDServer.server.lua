local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local AUTHORIZED_USER_IDS = {
	-- Add your Roblox UserId values to enable the private Studio test tools.
}

local function isAuthorized(player)
	if not RunService:IsStudio() then return false end
	return table.find(AUTHORIZED_USER_IDS, player.UserId) ~= nil
end

local folder = ReplicatedStorage:FindFirstChild("NARDVVIPRemotes") or Instance.new("Folder")
folder.Name = "NARDVVIPRemotes"
folder.Parent = ReplicatedStorage

local request = folder:FindFirstChild("Request") or Instance.new("RemoteFunction")
request.Name = "Request"
request.Parent = folder
local movement = folder:FindFirstChild("Movement") or Instance.new("RemoteEvent")
movement.Name = "Movement"
movement.Parent = folder

local store = DataStoreService:GetDataStore("NARDVVIP_Config_v1")
local movementState = {}
local savedCollision = {}

local function setNoclip(player, enabled)
	local character = player.Character
	if not character then return end
	savedCollision[player] = savedCollision[player] or {}
	for _, item in ipairs(character:GetDescendants()) do
		if item:IsA("BasePart") then
			if enabled then
				if savedCollision[player][item] == nil then savedCollision[player][item] = item.CanCollide end
				item.CanCollide = false
			elseif savedCollision[player][item] ~= nil then
				item.CanCollide = savedCollision[player][item]
				savedCollision[player][item] = nil
			end
		end
	end
end

local function setFlight(player, enabled)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local state = movementState[player] or {}
	movementState[player] = state
	if not enabled then
		if state.velocity then state.velocity:Destroy() end
		if state.attachment then state.attachment:Destroy() end
		state.velocity, state.attachment = nil, nil
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
			pcall(function() root:SetNetworkOwnershipAuto() end)
		end
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and state.previousPlatformStand ~= nil then
			humanoid.PlatformStand = state.previousPlatformStand
		end
		state.previousPlatformStand = nil
	elseif root and not state.velocity then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			state.previousPlatformStand = humanoid.PlatformStand
			humanoid.PlatformStand = true
		end
		local attachment = Instance.new("Attachment")
		attachment.Name = "NARDFlightAttachment"
		attachment.Parent = root
		local velocity = Instance.new("LinearVelocity")
		velocity.Name = "NARDFlightVelocity"
		velocity.Attachment0 = attachment
		velocity.RelativeTo = Enum.ActuatorRelativeTo.World
		velocity.MaxForce = 100000
		velocity.VectorVelocity = Vector3.zero
		velocity.Parent = root
		state.attachment, state.velocity = attachment, velocity
		pcall(function() root:SetNetworkOwner(nil) end)
	end
end

local function isFiniteNumber(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

request.OnServerInvoke = function(player, action, payload)
	if not isAuthorized(player) then return false, "Not authorized for NARD Studio testing." end
	if action == "authorize" then return true end
	if action == "loadConfig" then
		local ok, result = pcall(function() return store:GetAsync(tostring(player.UserId)) end)
		if not ok then return false, "Configuration load failed: " .. tostring(result) end
		if result == nil then return nil end
		local decoded, value = pcall(function() return HttpService:JSONDecode(result) end)
		if not decoded or type(value) ~= "table" then return false, "Saved configuration is invalid." end
		return value
	elseif action == "saveConfig" then
		if type(payload) ~= "string" or #payload > 8192 then return false, "Configuration exceeds the size limit." end
		local ok, value = pcall(function() return HttpService:JSONDecode(payload) end)
		if not ok or type(value) ~= "table" then return false, "Configuration payload is invalid." end
		local stored, err = pcall(function() store:SetAsync(tostring(player.UserId), payload) end)
		if not stored then return false, "Configuration save failed: " .. tostring(err) end
		return true
	elseif action == "resetConfig" then
		local ok, err = pcall(function() store:RemoveAsync(tostring(player.UserId)) end)
		if not ok then return false, "Configuration reset failed: " .. tostring(err) end
		return true
	end
	return false, "Unknown request."
end

movement.OnServerEvent:Connect(function(player, action, value)
	if not isAuthorized(player) then return end
	local state = movementState[player] or { speed = 16 }
	movementState[player] = state
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if action == "speed" and isFiniteNumber(value) then
		state.speed = math.clamp(value, 8, 32)
		if humanoid then humanoid.WalkSpeed = state.speed end
	elseif action == "reset" then
		state.flying = false
		state.noclip = false
		setFlight(player, false)
		setNoclip(player, false)
		state.speed = 16
		if humanoid then humanoid.WalkSpeed = 16 end
	elseif action == "fly" and type(value) == "boolean" then
		state.flying = value
		setFlight(player, value)
	elseif action == "flyInput" and typeof(value) == "Vector3" and state.flying then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local velocity = state.velocity
		if root and velocity and value.Magnitude == value.Magnitude and value.Magnitude <= 1.01 then
			velocity.VectorVelocity = value.Magnitude > 0.01 and value.Unit * 36 or Vector3.zero
		end
	elseif action == "noclip" and type(value) == "boolean" then
		state.noclip = value
		setNoclip(player, value)
	end
end)

local function bindPlayer(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		if player.Parent ~= Players or player.Character ~= character then return end
		savedCollision[player] = {}
		local state = movementState[player]
		if state then
			state.velocity, state.attachment = nil, nil
			state.previousPlatformStand = nil
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if state and humanoid then humanoid.WalkSpeed = state.speed or 16 end
		if state and state.noclip then setNoclip(player, true) end
		if state and state.flying then setFlight(player, true) end
		character.DescendantAdded:Connect(function(item)
			local currentState = movementState[player]
			if currentState and currentState.noclip and savedCollision[player] and item:IsA("BasePart") then
				savedCollision[player][item] = item.CanCollide
				item.CanCollide = false
			end
		end)
	end)
end

Players.PlayerAdded:Connect(bindPlayer)
for _, player in ipairs(Players:GetPlayers()) do bindPlayer(player) end
Players.PlayerRemoving:Connect(function(player)
	setFlight(player, false)
	setNoclip(player, false)
	movementState[player] = nil
	savedCollision[player] = nil
end)
