local HttpService = game:GetService("HttpService")

local Config = {}

local DEFAULTS = {
	esp = { enabled = false, boxes = true, names = true, distance = true, health = true, maxDistance = 400, category = "All" },
	aim = { enabled = false, assist = false, radius = 130, sensitivity = 8 },
	radar = { enabled = false, range = 300, size = 190 },
	fov = { enabled = false, radius = 130, transparency = 0.18, colorIndex = 1 },
	movement = { speed = 16 },
}

local LIMITS = {
	esp = { maxDistance = { 50, 1000 } },
	aim = { radius = { 30, 400 }, sensitivity = { 1, 12 } },
	radar = { range = { 50, 1000 }, size = { 120, 300 } },
	fov = { radius = { 30, 400 }, transparency = { 0, 0.9 }, colorIndex = { 1, 3 } },
	movement = { speed = { 8, 32 } },
}

local function sanitize(section, value, defaults)
	if type(value) ~= "table" then return table.clone(defaults) end
	local result = {}
	for key, default in pairs(defaults) do
		local incoming = value[key]
		if type(default) == "boolean" then
			if type(incoming) == "boolean" then result[key] = incoming else result[key] = default end
		elseif type(default) == "number" then
			local limit = LIMITS[section][key]
			result[key] = type(incoming) == "number" and math.clamp(incoming, limit[1], limit[2]) or default
			if key == "colorIndex" then result[key] = math.floor(result[key]) end
		elseif section == "esp" and key == "category" then
			local categories = { All = true, Hostile = true, Friendly = true, Neutral = true }
			result[key] = type(incoming) == "string" and categories[incoming] and incoming or default
		end
	end
	return result
end

function Config.new(remote)
	local data = table.clone(DEFAULTS)
	for key, value in pairs(DEFAULTS) do data[key] = table.clone(value) end
	local api = {}
	function api:Get()
		return data
	end
	function api:Set(section, key, value)
		if data[section] and data[section][key] ~= nil then data[section][key] = value end
	end
	function api:Load()
		local ok, result, message = pcall(function() return remote:InvokeServer("loadConfig") end)
		if not ok then return false, tostring(result) end
		if type(result) == "table" then
			local loaded = {}
			for section, defaults in pairs(DEFAULTS) do loaded[section] = sanitize(section, result[section], defaults) end
			data = loaded
			return true
		end
		if result == false then return false, tostring(message or "Saved configuration could not be loaded.") end
		return false, "No saved configuration was found."
	end
	function api:Save()
		local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
		if not ok then return false, tostring(encoded) end
		local invoked, result, message = pcall(function() return remote:InvokeServer("saveConfig", encoded) end)
		if not invoked then return false, tostring(result) end
		if result == true then return true end
		return false, tostring(message or result)
	end
	function api:Reset()
		data = {}
		for key, value in pairs(DEFAULTS) do data[key] = table.clone(value) end
		local ok, result, message = pcall(function() return remote:InvokeServer("resetConfig") end)
		if not ok then return false, tostring(result) end
		if result == true then return true end
		return false, tostring(message or result)
	end
	return api
end

return Config
