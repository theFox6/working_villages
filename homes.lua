-- working_villages.homes represents a table that contains the villagers homes.
-- This table's keys are inventory names, and values are home objects.
working_villages.homes = (function()
	local file_name = minetest.get_worldpath() .. "/working_villages_homes"

	minetest.register_on_shutdown(function()
		local file = io.open(file_name, "w")
		file:write(minetest.serialize(working_villages.homes))
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

minetest.register_node("working_villages:home_marker", {
	description = "home marker for working_villages",
	drawtype = "nodebox",
	tiles = {"default_sign_wall_wood.png"},
	inventory_image = "default_sign_wood.png",
	wield_image = "default_sign_wood.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.4375, 0.4375, -0.3125, 0.4375, 0.5, 0.3125},
		wall_bottom = {-0.4375, -0.5, -0.3125, 0.4375, -0.4375, 0.3125},
		wall_side   = {-0.5, -0.3125, -0.4375, -0.4375, 0.3125, 0.4375},
	},
	groups = {choppy = 2, dig_immediate = 2, attached_node = 1},
	legacy_wallmounted = true,
	sounds = default.node_sound_defaults(),
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local owner = placer:get_player_name()
		meta:set_string("owner", owner)
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string(
			"formspec",
			"size[5,5]"..
			"field[0.5,1;4,1;name;house label;${name}]"..
			"field[0.5,2;4,1;bed_pos;bed position;${bed_pos}]"..
			"field[0.5,3;4,1;door_pos;position outside the house;${door_pos}]"..
			"button_exit[1,4;2,1;ok;Write]")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		local sender_name = sender:get_player_name()
		local failed = false
		if minetest.is_protected(pos, sender_name) then
			minetest.record_protection_violation(pos, sender_name)
			return
		end
		if (meta:get_string("bed")~="" and meta:get_string("door")~="") or (fields.bed_pos == nil and fields.door_pos == nil) then
			return
		end
		local coords = minetest.sring_to_pos(fields.bed_pos)
		if coords == nil then
			-- fail on illegal input of coordinates
			minetest.chat_send_player(sender_name, 'You failed to provide correct coordinates for the bed position. Please enter the X, Y, and Z coordinates of the desired destination in a comma seperated list. Example: The input "10,20,30" means the destination at the coordinates X=10, Y=20 and Z=30.')
			failed = true
		elseif(coords.x>30927 or coords.x<-30912 or coords.y>30927 or coords.y<-30912 or coords.z>30927 or coords.z<-30912) then
			minetest.chat_send_player(sender_name, 'The coordinates of your bed position do not exist in our coordinate system. Correct coordinates range from -30912 to 30927 in all axes.')
			failed = true
		else
			meta:set_string("bed", fields.bed_pos)
		end
		coords = minetest.sring_to_pos(fields.door_pos)
		if coords == nil then
			-- fail on illegal input of coordinates
			minetest.chat_send_player(sender_name, 'You failed to provide correct coordinates for the door position. Please enter the X, Y, and Z coordinates of the desired destination in a comma seperated list. Example: The input "10,20,30" means the destination at the coordinates X=10, Y=20 and Z=30.')
			failed = true
		elseif(coords.x>30927 or coords.x<-30912 or coords.y>30927 or coords.y<-30912 or coords.z>30927 or coords.z<-30912) then
			minetest.chat_send_player(sender_name, 'The coordinates of your bed position do not exist in our coordinate system. Correct coordinates range from -30912 to 30927 in all axes.')
			failed = true
		else
			meta:set_string("door", fields.door_pos)
		end
		if not failed then
			meta:set_string("infotext", fields.name)
			meta:set_string("formspec",
				"size[5,4]"..
				"label[0.5,0.5;house label: ".. fields.name .."]"..
				"label[0.5,1;bed position:".. fields.bed_pos .."]"..
				"label[0.5,1.5;position outside:".. fields.door_pos .."]"..
				"label[0.5,2;position of this marker:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. "]"..
				"button_exit[1,2.5;2,1;ok;exit]")
		end
	end,
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		local pname = player:get_player_name()
		return pname == owner or pname == minetest.setting_get("name")
	end,
})

-- home is a prototype home object
working_villages.home = {}

-- get the home of a villager
function working_villages.get_home(self)
	return working_villages.homes[self.inventory_name]
end

-- check whether a villager has a home
function working_villages.is_valid_home(self)
	local home = working_villages.get_home(self)
	if home == nil then
		return false
	end
	if not home.get_bed then --update home
		for k, v in pairs(working_villages.home) do
			home[k] = v
		end
	end
	return true
end

-- get the position of the home_marker
function working_villages.home:get_marker()
	return self.marker
end

function working_villages.home:get_marker_meta()
	local home_marker_pos = self:get_marker()
	if minetest.get_node(home_marker_pos).name == "ignore" then
		minetest.get_voxel_manip():read_from_map(home_marker_pos, home_marker_pos)
	end
	if minetest.get_node(home_marker_pos).name ~= "working_villages:home_marker" then
		if working_villages.debug_logging and not(vector.equals(home_marker_pos,{x=0,y=0,z=0})) then
			minetest.log("warning", "The door position of an invalid home was requested.")
			minetest.log("warning", "Given home position:" .. home_marker_pos.x .. "," .. home_marker_pos.y .. "," .. home_marker_pos.z)
		end
		return false
	end
	return minetest.get_meta(home_marker_pos)
end

-- get the position that marks "outside"
function working_villages.home:get_door()
	if self.door~=nil then
		return self.door
	end
	local meta = self:get_marker_meta()
	local door_pos = meta:get_string("door")
	if not door_pos then
		if working_villages.debug_logging then
			minetest.log("warning", "The position outside the house was not entered for the home at:" .. home_marker_pos.x .. "," .. home_marker_pos.y .. "," .. home_marker_pos.z)
		end
		return false
	end
	home.door = minetest.string_to_pos(door_pos)
	return home.door
end

-- get the bed of a villager
function working_villages.home:get_bed()
	if self.bed~=nil then
		return self.bed
	end

	local meta = self:get_marker_meta()
	local bed_pos = meta:get_string("bed")
	if not bed_pos then
		if working_villages.debug_logging then
			minetest.log("warning", "The position of the bed was not entered for the home at:" .. home_marker_pos.x .. "," .. home_marker_pos.y .. "," .. home_marker_pos.z)
		end
		return false
	end
	home.bed = minetest.string_to_pos(bed_pos)
	return home.bed
end

-- set the home of a villager
function working_villages.set_home(inv_name,marker_pos)
	working_villages.homes[inv_name] = table.copy(working_villages.home)
	working_villages.homes[inv_name].marker = marker_pos
end