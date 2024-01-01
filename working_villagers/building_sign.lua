--
-- huts
--

building_sign.register_schematic("simple_hut.we")
building_sign.register_schematic("fancy_hut.we")

-- TODO the .we files have are leaking usernames

-- use if lots of papyrus and grass
if minetest.get_modpath("sleeping_mat")
and minetest.get_modpath("claycrafter")
and minetest.get_modpath("homedecor_doors_and_gates")
and minetest.get_modpath("homedecor_misc") then
	-- use this to test the hobo patch
	building_sign.register_schematic("hobo_hut.we")
end

-- fully-furnished underground house
building_sign.register_schematic("hobbit_hut_666.we")
building_sign.register_schematic("hobbit_bunker.we")

-- use if lots of wood near water
-- wooden duplex with crosswalk, light tower, fishing hole and space for appliance
building_sign.register_schematic("dock.we")

-- has a decent view
building_sign.register_schematic("spawn_ship.we")

-- camping
if minetest.get_modpath("sleeping_mat")
and minetest.get_modpath("new_campfire") then
	building_sign.register_schematic("grass_hut.we")
end

-- TODO realistic igloo
-- TODO persian wind towers

-- housing for two villagers
-- includes furnace and crafting bench and optional well
if minetest.get_modpath("crafting_bench") then
	building_sign.register_schematic("couple_hut.we")
end
if minetest.get_modpath("crafting_bench")
and minetest.get_modpath("technic") then
	building_sign.register_schematic("couple_hut_lv.we")
end
if minetest.get_modpath("crafting_bench")
and minetest.get_modpath("homedecor_exterior") then
	building_sign.register_schematic("couple_hut_well.we")
end
if minetest.get_modpath("crafting_bench")
and minetest.get_modpath("technic") then
	building_sign.register_schematic("couple_hut_lv.we")
end
if minetest.get_modpath("crafting_bench")
and minetest.get_modpath("technic")
and minetest.get_modpath("homedecor_exterior") then
	building_sign.register_schematic("couple_hut_lv_well.we")
end

--
-- shops
--

if  minetest.get_modpath("fancy_vend") 
and minetest.get_modpath("smartrenting") then
	building_sign.register_schematic("vendor_stall.we")
end

-- needs 4 jobs:
-- - grind ice,
-- - craft raw snowcone,
-- - use snowcone machine,
-- - populate vendor
if minetest.get_modpath("snowcone")
and minetest.get_modpath("fancy_vend")
and minetest.get_modpath("technic")
and minetest.get_modpath("crafting_bench") then
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
and minetest.get_modpath("crafting_bench")
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
and minetest.get_modpath("crafting_bench")
and minetest.get_modpath("waffles")
and minetest.get_modpath("fancy_vend") then
	-- TODO create job to fill buckets from well
	building_sign.register_schematic("wafflehaus")
end

-- Punjab-inspired shoe shop
if minetest.get_modpath("crafting_bench")
and minetest.get_modpath("fancy_vend")
and minetest.get_modpath("hopper")
then
	building_sign.register_schematic("cobbler")
end

--
-- big/industrial buildings
--

-- instructions for industrial farming complex: stack the layers :) remember to cut off either the roof or floor
-- for crops that grow up to two spaces (ie player height)
building_sign.register_schematic("farm_2h.we")
building_sign.register_schematic("farm_3h.we")
-- for papyrus
building_sign.register_schematic("farm_4h.we")
-- orchard
building_sign.register_schematic("farm_13h_no_irrigation.we")
-- flora and fauna
building_sign.register_schematic("farm_2h_no_irrigation.we")
-- mushrooms
building_sign.register_schematic("farm_2h_no_light.we")

-- perimeter wall
building_sign.register_schematic("wall_segment.we")
building_sign.register_schematic("wall_gate.we")

-- use these to create a well-manicured buffer zone inside the perimeter wall
building_sign.register_schematic("park_v.we")
building_sign.register_schematic("park_h.we")
building_sign.register_schematic("crossroads.we")

-- space stations
building_sign.register_schematic("ring.we")
building_sign.register_schematic("kolab.we")

--
-- miscellaneous / extra
--

-- simple decorative fountain
if minetest.get_modpath("pipeworks") then
	building_sign.register_schematic("fountain.we")
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

--
-- traps
--

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

-- blocks the passage and floods it
if minetest.get_modpath("mesecons_pistons")
and minetest.get_modpath("mesecons_extrawires")
and minetest.get_modpath("mesecons_gates")
and minetest.get_modpath("mesecons_delayer")
and minetest.get_modpath("mesecons_detector")
and minetest.get_modpath("pipeworks") then
	building_sign.register_schematic("shower.we")
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
	-- TODO auto-injector operator bot
	building_sign.register_schematic("rail_pit.we")
end

--
-- utilities / electrical / plumbing
--

-- bi-directional rail system with underground utilities and lighting
if minetest.get_modpath("pipeworks")           -- plumbing
and minetest.get_modpath("technic")            -- electric
and minetest.get_modpath("mesecons_insulated") -- easy machines
and minetest.get_modpath("digilines")          -- complex machines
then
	building_sign.register_schematic("road.we")
end

-- trees don't need irrigation, so industrial orchards will have a different construction

-- underground road-connected switching station with digiline-connected components
-- we generate HV and step it down to MV then to LV
-- batteries sold separately
if minetest.get_modpath("technic")            -- electric
and minetest.get_modpath("digilines")          -- complex machines
then
	-- default design
	building_sign.register_schematic("switching_station_solar.we")
	-- use if less sunlight
	building_sign.register_schematic("switching_station.we")
	-- compact design
	building_sign.register_schematic("switching_station_manhole.we")
end

-- 5 fuel burners with random load balancing, housing and manhole access
if minetest.get_modpath("technic")            -- electric
and minetest.get_modpath("digilines")          -- complex machines
and minetest.get_modpath("pipeworks")          -- random load balancing
then
	-- TODO random load balancing is primitive.
	-- round-robin would be better
	-- and detecting least-utilized devices would be optimal
	-- TODO need a bot to put fuel into the injector
	building_sign.register_schematic("fuel_burner.we")
end

if minetest.get_modpath("technic") then
	building_sign.register_schematic("nuke_reacc_hole.we") -- I left a hole to service the appliance
	building_sign.register_schematic("nuke_reacc.we") -- finished
	-- TODO nuclear rod operator bot
end

--
-- ships
--

-- self-contained living situation
if minetest.get_modpath("mesecons_luacontroller") -- should move the boat on tick TODO it keeps overheating
and minetest.get_modpath("digilines") -- display y coords
and minetest.get_modpath("jumpdrive") -- makes it a ship
and minetest.get_modpath("technic")
and minetest.get_modpath("crafting_bench") -- nice to have when we resize the player's crafting grid to 2x2
and minetest.get_modpath("biofuel") -- for your poop
then
	-- geothermal power should be ok in deep oceans
	building_sign.register_schematic("unterseeboot.we")
	-- solar power should be ok in the sky
	building_sign.register_schematic("airship.we")
end

if and minetest.get_modpath("jumpdrive") -- makes it a ship
and minetest.get_modpath("technic")
and minetest.get_modpath("biofuel") -- for your poop
and minetest.get_modpath("technic")
then
	building_sign.register_schematic("passenger_ship.we")
end

if minetest.get_modpath("mesecons_luacontroller") -- fire ma lazor... repeatedly
and minetest.get_modpath("digilines") -- display y coords
and minetest.get_modpath("jumpdrive") -- makes it a ship
and minetest.get_modpath("spacecannon") -- for "gracefully handling" the wolf3d-nostalgic infrastructure
and minetest.get_modpath("pipeworks") -- load balancing
and minetest.get_modpath("technic")
then
	-- penetrating cannons for taking out buildings and sniping ship components
	-- TODO wip, but the cannons are functional for offensive purposes
	-- on/off lever for cannons
	-- flight controls
	-- better load-balancing
	building_sign.register_schematic("rail_ship.we")
end

if minetest.get_modpath("mesecons_luacontroller") -- fire ma lazor... repeatedly
and minetest.get_modpath("digilines") -- display y coords
and minetest.get_modpath("spacecannon") -- for dealing with the rail ship
and minetest.get_modpath("technic")
and minetest.get_modpath("jumpdrive") -- makes it a ship
then
	-- TODO doors
	-- on/off lever for cannons
	-- flight controls
	building_sign.register_schematic("nova_ship.we")
end

-- not a ship
if minetest.get_modpath("mesecons_luacontroller") -- fire ma lazor... repeatedly
if minetest.get_modpath("mesecons_walllever") -- fire ma lazor... repeatedly
if minetest.get_modpath("mesecons_extrawires") -- fire ma lazor... repeatedly
if minetest.get_modpath("mesecons_lamp") -- fire ma lazor... repeatedly
and minetest.get_modpath("digilines") -- display y coords
and minetest.get_modpath("spacecannon") -- for dealing with the air ships
and minetest.get_modpath("technic")
then
	-- TODO bed, furnace
	building_sign.register_schematic("bomb_shelter.we")
end


-- TODO apartments
-- TODO barracks
--      - v2 is cyclopean and can have other buildings inside its courtyard. namely the industrial farm.
--      - v2 is too big. needs to be build in sectors.
--      - v2 includes a bit of an open field between the wall and the building (for security), which should be a separate schematic
--      - v2 includes a self-healing perimeter wall which should be a separate schematic

-- TODO finish workshops
--      - basically just pre-furnished huts

-- TODO other religious sites

-- TODO juice stand - `drinks`
-- TODO ice cream parlor - `icecream`
-- TODO more restaurant types

-- TODO IA tower
--      - pyramid
--      - "cross"
--      - "funnel"
--      - lobby
