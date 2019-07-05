local init = os.clock()
minetest.log("action", "["..minetest.get_current_modname().."] loading...")

building_sign = {
	modpath=minetest.get_modpath("building_sign"),
	DEFAULT_NODE = {name="air"},
}

dofile(building_sign.modpath .. "/util.lua")
dofile(building_sign.modpath .. "/building_store.lua")

local S = building_sign.S
minetest.register_node("building_sign:building_marker", {
	description = S("marker_desc"),
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
	sounds = default.node_sound_defaults(),
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local owner = placer:get_player_name()
		meta:set_string("owner", owner)
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local area = building_sign.areas.check_existing(pos)
		if area then
			--TODO: load from area
		else
			meta:set_string("configured","false")
			meta:set_string("state","unplanned")
		end
		meta:set_string("formspec",building_sign.forms.make_formspec(meta))
	end,
	on_receive_fields = building_sign.forms.on_receive_fields,
	can_dig = function(pos, player)
		local pname = player:get_player_name()
		if minetest.is_protected(pos, pname) then
			minetest.record_protection_violation(pos, pname)
			return false
		end
		return true
	end,
	after_destruct = function(pos, oldnode)
		--TODO: record sign removal
	end,
})

local time_to_load= os.clock() - init
building_sign.log.action("loaded in %.4f s", time_to_load)
