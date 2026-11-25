local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Movement = {}

function Movement.new(remote, authorized)
	local settings = { fly = false, noclip = false, speed = 16 }
	local api = {}
	local stepConnection
	local accumulated = 0

	local function send(action, value)
		if not authorized then return end
		remote:FireServer(action, value)
	end

	local function inputDirection()
		local camera = workspace.CurrentCamera
		if not camera then return Vector3.zero end
		local forward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
		local right = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z)
		if forward.Magnitude > 0 then forward = forward.Unit end
		if right.Magnitude > 0 then right = right.Unit end
		local direction = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += forward end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= forward end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += right end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= right end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.yAxis end
		return direction.Magnitude > 1 and direction.Unit or direction
	end

	function api:Set(key, value)
		if key == "fly" or key == "noclip" then
			local enabled = value == true
			if settings[key] ~= enabled then
				settings[key] = enabled
				send(key, enabled)
			end
		elseif key == "speed" then
			settings.speed = math.clamp(value, 8, 32)
			send("speed", settings.speed)
		end
	end
	function api:Reset()
		settings.fly, settings.noclip, settings.speed = false, false, 16
		send("reset")
	end
	function api:Start()
		if not authorized then return end
		stepConnection = RunService.Heartbeat:Connect(function(dt)
			if not settings.fly then return end
			accumulated += dt
			if accumulated >= 0.1 then
				accumulated = 0
				send("flyInput", inputDirection())
			end
		end)
	end
	function api:Destroy()
		if stepConnection then stepConnection:Disconnect() end
		if authorized then
			send("fly", false)
			send("noclip", false)
			send("reset")
		end
	end
	return api
end

return Movement
