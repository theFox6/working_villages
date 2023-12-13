building_sign.register_schematic("simple_hut.we")
building_sign.register_schematic("fancy_hut.we")

-- TODO the .we files have are leaking usernames

if  minetest.get_modpath("fancy_vend") 
and minetest.get_modpath("smartrenting") then
	building_sign.register_schematic("vendor_stall.we")
end

if minetest.get_modpath("mesecons_pressureplates")
and minetest.get_modpath("mesecons_pistons")
and minetest.get_modpath("mesecons_extrawires")
and minetest.get_modpath("meseconds_gates")
and minetest.get_modpath("meseconds_delayer") then
	building_sign.register_schematic("one_way_door_vertical.we")
	building_sign.register_schematic("one_way_door_horizontal.we")
end

if minetest.get_modpath("mesecons_pistons")
and minetest.get_modpath("mesecons_extrawires")
and minetest.get_modpath("mesecons_gates")
and minetest.get_modpath("mesecons_delayer")
and minetest.get_modpath("mesecons_detector") then
	building_sign.register_schematic("lava_bath.we")
end

if minetest.get_modpath("mesecons_pistons")
and minetest.get_modpath("mesecons_extrawires")
and minetest.get_modpath("mesecons_gates")
and minetest.get_modpath("mesecons_delayer")
and minetest.get_modpath("mesecons_detector")
and minetest.get_modpath("technic")
and minetest.get_modpath("mesecons_luacontroller")
and minetest.get_modpath("digilines")
and minetest.get_modpath("spacecannon") then
	building_sign.register_schematic("rail_pit.we")
end

if minetest.get_modpath("building_blocks")
and minetest.get_modpath("homedecor_windows_and_treatments")
and minetest.get_modpath("ontime_clocks")
and minetest.get_modpath("moreblocks")
and minetest.get_modpath("stairsplus")
and minetest.get_modpath("itemframes")
and minetest.get_modpath("church_altar")
and minetest.get_modpath("church_bell")
and minetest.get_modpath("church_pews")
and minetest.get_modpath("church_podium")
and minetest.get_modpath("homedecor_plasmascreen")
and minetest.get_modpath("lavalamp")
and minetest.get_modpath("homedecor_inbox")
and minetest.get_modpath("3d_armor_stand")
and minetest.get_modpath("chakram") -- TODO it's kinda unstable nowadays
and minetest.get_modpath("books")
and minetest.get_modpath("markdown_poster")
and minetest.get_modpath("homedecor_lighting")
and minetest.get_modpath("homedecor_bathroom")
--and minetest.get_modpath("doors")
and minetest.get_modpath("homedecor_doors_and_gates")
and minetest.get_modpath("stairsplus_legacy")
and minetest.get_modpath("homedecor_misc")
and minetest.get_modpath("homedecor_office")
and minetest.get_modpath("homedecor_kitchen")
and minetest.get_modpath("generic_flags") then
	-- TODO it's missing the rumala sahib
	-- TODO parshad
	-- TODO other gulaks
	-- TODO holy books should probably be distinct from generic books
	-- TODO display_lib doesn't like being used in schematics, so I need to look into how to properly handle the nil font error in it
	building_sign.register_schematic("gurudwara_v1.we")
end

-- TODO finish power station
-- TODO finish apartments v1 & v2
-- TODO finish workshops
-- TODO finish industrial farming complex
-- TODO other religious sites

-- TODO wolf3d-nostalgia in a separate mod
