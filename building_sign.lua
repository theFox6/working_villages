local SCHEMS = {"simple_hut.we", "fancy_hut.we"}
local DEFAULT_NODE = {name="air"}
local MAX_POS = 3000

working_villages.building = (function()
	local file_name = minetest.get_worldpath() .. "/working_villages_building_sites"

	minetest.register_on_shutdown(function()
		local file = io.open(file_name, "w")
		file:write(minetest.serialize(working_villages.building))
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

working_villages.buildings = {}

function working_villages.buildings.get(pos)
	return working_villages.building[minetest.hash_node_position(pos)]
end

function working_villages.buildings.get_build_pos(meta)
	return minetest.string_to_pos(meta:get_string("build_pos"))
end

function working_villages.buildings.get_registered_nodename(name)
	if name:find("doors:") then
		name = name:gsub("_[ab]_[12]", "")
		if string.find(name, "_t") or name:find("hidden") then
			name = nil
		end
	elseif string.find(name, "stairs") then
		name = name:gsub("upside_down", "")
	elseif string.find(name, "farming") then
		name = name:gsub("_%d", "")
	end
	return name
end

local function load_schematic(filename,pos)
	local meta = minetest.get_meta(pos)
	local input = io.open(working_villages.modpath.."/schems/"..filename, "r")
	if not input then
		minetest.log("warning","schematic \""..working_villages.modpath.."/schems/"..filename.."\" does not exist")
		working_villages.building[minetest.hash_node_position(working_villages.buildings.get_build_pos(meta))] = {}
		return
	end
	local data = minetest.deserialize(input:read('*all'))
	io.close(input)
	if not data then
		minetest.log("warning","schematic \""..working_villages.modpath.."/schems/"..filename.."\" is broken")
		working_villages.building[minetest.hash_node_position(working_villages.buildings.get_build_pos(meta))] = {}
		return
	end
	table.sort(data, function(a,b)
		if a.y == b.y then
			if a.z == b.z then
				return a.x < b.x
			end
			return a.z < b.z
		end
		return a.y < b.y
	end)
	local nodedata = {}
	for i,v in ipairs(data) do --TODO: this is actually not nessecary
		if v.name and v.x and v.y and v.z then
			local node = {name=v.name, param1=v.param1, param2=v.param2}
			local npos = vector.add(working_villages.buildings.get_build_pos(meta), {x=v.x, y=v.y, z=v.z})
			local name = working_villages.buildings.get_registered_nodename(v.name)
			if minetest.registered_items[name]==nil then
				node = DEFAULT_NODE
			end
			nodedata[i] = {pos=npos, node=node}
		end
	end
	working_villages.building[minetest.hash_node_position(working_villages.buildings.get_build_pos(meta))] = nodedata
end

local get_materials = function(nodelist)
	local materials = ""
	for _,el in pairs(nodelist) do
		materials = materials .. el.node.name .. ","
	end
	return materials:sub(1,#materials-1)
end

local function show_build_form(meta)
	local title = meta:get_string("schematic"):gsub("%.we","")
	local button_build = "button_exit[5.0,1.0;3.0,0.5;build_start;Begin Build]"
	if meta:get_string("paused") == "true" then
		button_build = "button_exit[5.0,2.0;3.0,0.5;build_resume;Resume Build]"
	end
	local index = meta:get_int("index")
	local nodelist = working_villages.buildings.get(working_villages.buildings.get_build_pos(meta))
	if not nodelist then nodelist = {} end
	local formspec = "size[8,10]"
		.."label[3.0,0.0;Project: "..title.."]"
		.."label[3.0,1.0;"..math.ceil(((index-1)/#nodelist)*100).."% finished]"
		.."textlist[0.0,2.0;4.0,3.5;inv_sel;"..get_materials(nodelist)..";"..index..";]"
		..button_build
		.."button_exit[5.0,3.0;3.0,0.5;build_cancel;Cancel Build]"
	return formspec
end

local get_formspec = function(meta)
	if meta:get_string("schematic")=="" then
		local schemlist = table.concat(SCHEMS, ",") or ""
		local formspec = "size[6,5]"
			.."textlist[0.0,0.0;5.0,4.0;schemlist;"..schemlist..";;]"
			.."button_exit[5.0,4.5;1.0,0.5;;Ok]"
		return formspec
	end
	if meta:get_string("schematic") then
		return show_build_form(meta)
	end
end

local on_receive_fields = function(pos, _, fields, sender)
	local player_name = sender:get_player_name()
	local meta = minetest.get_meta(pos)
	local sender_name = sender:get_player_name()
	if minetest.is_protected(pos, sender_name) then
		minetest.record_protection_violation(pos, sender_name)
		return
	end
	if meta:get_string("owner") == player_name then
		if fields.schemlist then
			local id = tonumber(string.match(fields.schemlist, "%d+"))
			if id then
				if SCHEMS[id] then
					local bpos = {
						x=math.ceil(pos.x) + 2,
						y=math.floor(pos.y),
						z=math.ceil(pos.z) + 2
					}
					meta:set_string("schematic",SCHEMS[id])
					meta:set_string("build_pos",minetest.pos_to_string(bpos))
					load_schematic(meta:get_string("schematic"),pos)
				end
			end
		elseif fields.build_cancel then
			--reset_build()
			working_villages.building[minetest.hash_node_position(working_villages.buildings.get_build_pos(meta))] = nil
			meta:set_string("schematic","")
			meta:set_int("index",1)
		end
	end
	if fields.build_start then
		local nodelist = working_villages.buildings.get(working_villages.buildings.get_build_pos(meta))
		for _,v in ipairs(nodelist) do
			minetest.remove_node(v.pos)
			--FIXME: the villager ought to do this
		end
		meta:set_int("index",1)
	elseif fields.build_resume then
		meta:set_string("paused","false")
	end
	meta:set_string("formspec",get_formspec(meta))
end

minetest.register_node("working_villages:building_marker", {
	description = "building marker for working_villages",
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
		meta:set_string("formspec",get_formspec(meta))
		meta:set_int("index",1)
	end,
	on_receive_fields = on_receive_fields,
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")
		local pname = player:get_player_name()
		return pname == owner or pname == minetest.setting_get("name")
	end,
})