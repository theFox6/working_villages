local init = os.clock()
minetest.log("action", "["..minetest.get_current_modname().."] loading...")

local modpath = minetest.get_modpath("building_sign")
building_sign = {
  S = modutil.require("translations","venus")(),
  DEFAULT_NODE = {name="air"},
  registered_schematics = {"[custom house]"},
  modpath = modpath
}

modutil.require("local_require")(building_sign)
local log = building_sign.require("log")
building_sign.log = log

function building_sign.out_of_limit(pos)
  if (pos.x>30927 or pos.x<-30912
  or  pos.y>30927 or pos.y<-30912
  or  pos.z>30927 or pos.z<-30912) then
    return true
  end
  return false
end

function building_sign.register_schematic(file)
  table.insert(building_sign.registered_schematics,file)
end

--TODO: load world schematics

building_sign.require("building_store","venus")
building_sign.require("forms")
building_sign.require("areas")

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
		local building = building_sign.areas.get_building(pos)
		if building then
			--TODO: load everything from area
			if building.build_pos then
				meta:set_string("build_pos",minetest.pos_to_string(building.build_pos))
			end
			if not building.nodedata then
        meta:set_string("configured","false")
        meta:set_string("state","unplanned")
			end
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
	--on_destruct
	after_destruct = function(pos, oldnode)
		--TODO: record sign removal
	end,
})

local time_to_load= os.clock() - init
log.action("loaded init in %.4f s", time_to_load)
