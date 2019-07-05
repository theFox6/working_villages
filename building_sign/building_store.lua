local building = {}

function building:new(o)
	return setmetatable(o or {}, {__index = self})
end

building_sign.building_store = (function()
	local file_name = minetest.get_worldpath() .. "/building_signs"

	minetest.register_on_shutdown(function()
		local file = io.open(file_name, "w")
		file:write(minetest.serialize(building_sign.building_store))
		file:close()
	end)

	local file = io.open(file_name, "r")
	if file ~= nil then
		local data = file:read("*a")
		file:close()
		return minetest.deserialize(data)
	end
	return {}
end) ()

function building_sign.get(pos)
	local poshash = minetest.hash_node_position(pos)
	if building_sign.building_store[poshash] == nil then
		building_sign.building_store[poshash] = building:new()
	end
	return building_sign.building_store[poshash]
end

building_sign.building = building
