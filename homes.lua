working_villages.home = {}

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
			"field[0.5,3;4,1;door_pos;position outside near door;${door_pos}]"..
			"button_exit[1,4;2,1;ok;Write]")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		local sender_name = sender:get_player_name()
		if minetest.is_protected(pos, sender_name) then
			minetest.record_protection_violation(pos, sender_name)
			return
		end
		if (meta:get_string("bed")~="" and meta:get_string("door")~="") or fields.bed_pos == nil or fields.door_pos == nil then
			return
		end
		local coords = {}
		coords.x, coords.y, coords.z = string.match(fields.bed_pos, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
		coords.x=tonumber(coords.x)
		coords.y=tonumber(coords.y)
		coords.z=tonumber(coords.z)
		if not (coords.x and coords.y and coords.z) then
			-- fail on illegal input of coordinates
			minetest.chat_send_player(sender_name, 'You failed to provide correct coordinates for the bed position. Please enter the X, Y, and Z coordinates of the desired destination in a comma seperated list. Example: The input "10,20,30" means the destination at the coordinates X=10, Y=20 and Z=30.')
			return
		end
		if(coords.x>30927 or coords.x<-30912 or coords.y>30927 or coords.y<-30912 or coords.z>30927 or coords.z<-30912) then
			minetest.chat_send_player(sender_name, 'The coordinates of your bed position do not exist in our coordinate system. Correct coordinates range from -30912 to 30927 in all axes.')
			return
		end
		coords = {}
		coords.x, coords.y, coords.z = string.match(fields.door_pos, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
		coords.x=tonumber(coords.x)
		coords.y=tonumber(coords.y)
		coords.z=tonumber(coords.z)
		if not (coords.x and coords.y and coords.z) then
			-- fail on illegal input of coordinates
			minetest.chat_send_player(sender_name, 'You failed to provide correct coordinates for the bed position. Please enter the X, Y, and Z coordinates of the desired destination in a comma seperated list. Example: The input "10,20,30" means the destination at the coordinates X=10, Y=20 and Z=30.')
			return
		end
		if(coords.x>30927 or coords.x<-30912 or coords.y>30927 or coords.y<-30912 or coords.z>30927 or coords.z<-30912) then
			minetest.chat_send_player(sender_name, 'The coordinates of your bed position do not exist in our coordinate system. Correct coordinates range from -30912 to 30927 in all axes.')
			return
		end
		meta:set_string("bed", fields.bed_pos)
		meta:set_string("door", fields.door_pos)
		meta:set_string("infotext", fields.name)
		meta:set_string("formspec",
			"size[5,4]"..
			"label[0.5,0.5;house label: ".. fields.name .."]"..
			"label[0.5,1;bed position:".. fields.bed_pos .."]"..
			"label[0.5,1.5;door position:".. fields.door_pos .."]"..
			"label[0.5,2;position of this marker:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. "]"..
			"button_exit[1,2.5;2,1;ok;exit]")
	end,
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		local pname = player:get_player_name()
		return pname == owner or pname == minetest.setting_get("name")
	end,
})

function working_villages.home.get_door(home_marker_pos)
	if minetest.get_node(home_marker_pos).name ~= "working_villages:home_marker" then
		if working_villages.debug_logging and not(vector.equals(home_marker_pos,{x=0,y=0,z=0})) then
			minetest.log("warning", "The door position of an invalid home was requested.")
			minetest.log("warning", "Given home position:" .. home_marker_pos.x .. "," .. home_marker_pos.y .. "," .. home_marker_pos.z)
		end
		return false
	end
	local meta = minetest.get_meta(home_marker_pos)
	local door_pos = meta:get_string("door")
	if not door_pos then
		if working_villages.debug_logging then
			minetest.log("warning", "The door position was not entered for the home at:" .. home_marker_pos.x .. "," .. home_marker_pos.y .. "," .. home_marker_pos.z)
		end
		return false
	end
	local p = {}
	p.x, p.y, p.z = string.match(door_pos, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
	p.x=tonumber(p.x)
	p.y=tonumber(p.y)
	p.z=tonumber(p.z)
	return p
end

function working_villages.home.get_bed(home_marker_pos)
	local meta = minetest.get_meta(home_marker_pos)
	local bed_pos = meta:get_string("bed")
	if not bed_pos then
		print("no bed position")
		return false
	end
	local p = {}
	p.x, p.y, p.z = string.match(bed_pos, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
	p.x=tonumber(p.x)
	p.y=tonumber(p.y)
	p.z=tonumber(p.z)
	return p
end