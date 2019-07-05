---
--@type building
--@field #table area two positions marking the size of the building
--@field #table anchor the anchor point of the schematic
local building = {}

function building:new(o)
	return setmetatable(o or {}, {__index = self})
end

-- #table all buildings that ever were in the world
local building_store
building_store = (function()
	local file_name = minetest.get_worldpath() .. "/building_signs"

	minetest.register_on_shutdown(function()
		local file = io.open(file_name, "w")
		file:write(minetest.serialize(building_store))
		file:close()
	end)

	local file = io.open(file_name, "r")
	if file ~= nil then
		local data = file:read("*a")
		file:close()
		local ret = {}
		for i,v in pairs(minetest.deserialize(data)) do
		  ret[i] = building:new(v)
		end
		return ret
	end
	return {}
end) ()

function building_sign.get(pos, create)
	local poshash = minetest.hash_node_position(pos)
	if building_sign.building_store[poshash] == nil and create then
		building_sign.building_store[poshash] = building:new()
	end
	return building_sign.building_store[poshash]
end

building_sign.building = building
building_sign.building_store = building_store
