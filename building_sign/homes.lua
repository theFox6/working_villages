--TODO: transfer most of this into the building sign, the rest into working villages

building_sign.home = {
	update = {door = true, bed = true}
}

function building_sign.home:new(o)
	return setmetatable(o or {}, {__index = self})
end

-- building_sign.homes represents a table that contains the villagers homes.
-- This table's keys are name ids, and values are home objects.
building_sign.homes = (function()
	local file_name = minetest.get_worldpath() .. "/working_villages_homes"

	minetest.register_on_shutdown(function()
		local save_data = {}
		for k,v in pairs(building_sign.homes) do
			save_data[k]={marker=v.marker}
		end
		local file = io.open(file_name, "w")
		file:write(minetest.serialize(save_data))
		file:close()
	end)

	local file = io.open(file_name, "r")
	if file ~= nil then
		local data = file:read("*a")
		file:close()
		local load_data = minetest.deserialize(data)
		local home_data = {}
		for k,v in pairs(load_data) do
			home_data[k] = building_sign.home:new(v)
		end
		return home_data
	end
	return {}
end) ()

-- get the home of a villager
function building_sign.get_home(self)
	return building_sign.homes[self.inventory_name]
end

-- check whether a villager has a home
function building_sign.is_valid_home(self)
	local home = building_sign.get_home(self)
	if home == nil then
		return false
	end
	return true
end

-- get the position of the home_marker
function building_sign.home:get_marker()
	return self.marker
end

function building_sign.home:get_marker_meta()
	local home_marker_pos = self:get_marker()
	if minetest.get_node(home_marker_pos).name == "ignore" then
		minetest.get_voxel_manip():read_from_map(home_marker_pos, home_marker_pos)
		--minetest.emerge_area(home_marker_pos, home_marker_pos) --Doesn't work
	end
	if minetest.get_node(home_marker_pos).name ~= "working_villages:building_marker" then
		if not(vector.equals(home_marker_pos,{x=0,y=0,z=0})) then
			minetest.log("warning", "The position of an non existant home was requested.")
			minetest.log("warning", "Given home position:" .. minetest.pos_to_string(home_marker_pos))
		end
		return false
	end
	local meta = minetest.get_meta(home_marker_pos)
	if meta:get_string("valid")~="true" then
		local owner = meta:get_string("owner")
		if owner == "" then
			minetest.log("warning", "The data of an unconfigured home was requested.")
			minetest.log("warning", "Given home position:" .. minetest.pos_to_string(home_marker_pos))
		else
			minetest.chat_send_player(owner, "The data of an unconfigured home was requested.")
			minetest.chat_send_player(owner, "Given home position:" .. minetest.pos_to_string(home_marker_pos))
		end
		return false
	end
	return meta
end

-- get the position that marks "outside"
function building_sign.home:get_door()
	if self.door~=nil and self.update.door == false then
		return self.door
	end
	local meta = self:get_marker_meta()
	if not meta then
		return false
	end
	local door_pos = meta:get_string("door")
	if not door_pos then
		local home_marker_pos = self:get_marker()
		minetest.log("warning", "The position outside the house was not entered for the home at:" ..
		    minetest.pos_to_string(home_marker_pos))
		return false
	end
	self.door = minetest.string_to_pos(door_pos)
	self.update.door = false
	return self.door
end

-- get the bed of a villager
function building_sign.home:get_bed()
	if self.bed~=nil and self.update.bed == false then
		return self.bed
	end
	local meta = self:get_marker_meta()
	if not meta then
		return false
	end
	local bed_pos = meta:get_string("bed")
	if not bed_pos then
		local home_marker_pos = self:get_marker()
		minetest.log("warning", "The position of the bed was not entered for the home at:" ..
		    minetest.pos_to_string(home_marker_pos))
		return false
	end
	self.bed = minetest.string_to_pos(bed_pos)
	self.update.bed = false
	return self.bed
end

-- set the home of a villager
function building_sign.set_home(inv_name,marker_pos)
	building_sign.homes[inv_name] = building_sign.home:new{marker = marker_pos}
end
