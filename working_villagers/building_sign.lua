building_sign.register_schematic("simple_hut.we")
building_sign.register_schematic("fancy_hut.we")

-- TODO the .we files have are leaking usernames

if  minetest.get_modpath("fancy_vend") 
and minetest.get_modpath("smartrenting") then
	building_sign.register_schematic("vendor_stall.we")
end

-- fancy mechanized doors for dungeons and other secure areas
if minetest.get_modpath("mesecons_pressureplates")
and minetest.get_modpath("mesecons_pistons")
and minetest.get_modpath("mesecons_extrawires")
and minetest.get_modpath("meseconds_gates")
and minetest.get_modpath("meseconds_delayer") then
	building_sign.register_schematic("one_way_door_vertical.we")
	building_sign.register_schematic("one_way_door_horizontal.we")
end

-- opens the ground beneath the player so he can take a bath... in lava
if minetest.get_modpath("mesecons_pistons")
and minetest.get_modpath("mesecons_extrawires")
and minetest.get_modpath("mesecons_gates")
and minetest.get_modpath("mesecons_delayer")
and minetest.get_modpath("mesecons_detector") then
	building_sign.register_schematic("lava_bath.we")
end

-- opens the ground beneath the player, fires a railgun from above the player => digs a bottomless pit
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

-- bigger gurdwara usually have a separate langar hall,
-- but this layout is reasonable for a small building.
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
	-- TODO it would be good to add a guard-type that checks whether the player is wearing shoes. the thief's logic could be adapted for this.
	-- TODO it's missing the rumala sahib
	-- TODO parshad
	-- TODO other gulaks
	-- TODO holy books should probably be distinct from generic books
	-- TODO display_lib doesn't like being used in schematics, so I need to look into how to properly handle the nil font error in it
	building_sign.register_schematic("gurudwara_v1.we")
end

-- use if lots of papyrus and grass
if minetest.get_modpath("sleeping_mat")
and minetest.get_modpath("claycrafter")
and minetest.get_modpath("homedecor_doors_and_gates")
and minetest.get_modpath("homedecor_misc") then
	-- TODO handle_chest should handle all sorts of inventory types
	building_sign.register_schematic("hobo_hut.we")
end

-- use if lots of wood near water
-- wooden duplex with crosswalk, light tower, fishing hole and space for appliance
building_sign.register_schematic("dock.we")

-- camping
if minetest.get_modpath("sleeping_mat")
and minetest.get_modpath("new_campfire") then
	building_sign.register_schematic("grass_hut.we")
end

-- TODO realistic igloo
-- TODO persian wind towers

-- bi-directional rail system with underground utilities and lighting
if minetest.get_modpath("pipeworks")           -- plumbing
and minetest.get_modpath("technic")            -- electric
and minetest.get_modpath("mesecons_insulated") -- easy machines
and minetest.get_modpath("digilines")          -- complex machines
then
	building_sign.register_schematic("road.we")
end

-- needs 4 jobs:
-- - grind ice,
-- - craft raw snowcone,
-- - use snowcone machine,
-- - populate vendor
if minetest.get_modpath("snowcone")
and minetest.get_modpath("fancy_vend")
and minetest.get_modpath("technic")
and minetest.get_modpath("craft_table") then
	-- TODO create grinder job to grind ice from icehaus
	-- TODO update craftsman to put snow on cups
	building_sign.register_schematic("fruteria.we")
end

-- needs 3 jobs:
-- - get ice from machine (TODO create job),
-- - craft ice block (TODO update craftsman),
-- - populate vendor (TODO finish)
if minetest.get_modpath("icemachine")
and minetest.get_modpath("pipeworks")
and minetest.get_modpath("craft_table")
and minetest.get_modpath("fancy_vend") then
	-- TODO create icemachine job to get ice from machine
	building_sign.register_schematic("icehaus.we")
end

-- needs 4 jobs:
-- - fill bucket with water from well (TODO create job),
-- - craft waffle batter (TODO update craftsman),
-- - use wafflemaker,
-- - populates vendor (TODO finish)
if minetest.get_modpath("homedecor_exterior")
and minetest.get_modpath("craft_table")
and minetest.get_modpath("waffles")
and minetest.get_modpath("fancy_vend") then
	-- TODO create job to fill buckets from well
	building_sign.register_schematic("wafflehaus")
end

if minetest.get_modpath("craft_table")
and minetest.get_modpath("fancy_vend")
and minetest.get_modpath("hopper")
then
	building_sign.register_schematic("cobbler")
end


-- TODO finish power station
--      - the geometry is good to step down HV->MV->LV
--      - but there should be different types of power stations
--        - nuclear
--        - fuel-burning
--        - solar
--      - but I still need to compute how many batteries should be included for each
--      - and then decide on a fairly compact geometry that will output the correct wires for the roads
-- TODO homer simpson .. ahem I mean nuclear rod operator
-- TODO finish apartments v1 & v2
--      - v2 is cyclopean and can have other buildings inside its courtyard. namely the industrial farm.
-- TODO finish workshops
--      - basically just pre-furnished huts
-- TODO finish industrial farming complex
--      - I need to figure out about how much area a single farmer can handle,
--        and then put one farmer per level
--        and figure out a geometry for their housing
-- TODO other religious sites

-- TODO juice stand - `drinks`
-- TODO ice cream parlor - `icecream`
-- TODO more restaurant types
