print("loading [working_villages]")
working_villages={
	modpath=minetest.get_modpath("working_villages"),
	debug_logging=true,
	func = {}
}

--base
dofile(working_villages.modpath.."/pathfinder.lua")
dofile(working_villages.modpath.."/homes.lua")
dofile(working_villages.modpath.."/api.lua")
dofile(working_villages.modpath.."/register.lua")

--jobs
dofile(working_villages.modpath.."/jobs/util.lua")
dofile(working_villages.modpath.."/jobs/empty.lua")
dofile(working_villages.modpath.."/jobs/plant_collector.lua")
dofile(working_villages.modpath.."/jobs/woodcutter.lua")

dofile(working_villages.modpath.."/jobs/follow_player.lua")
dofile(working_villages.modpath.."/jobs/torcher.lua")
dofile(working_villages.modpath.."/jobs/snowclearer.lua")

--ready
if minetest.setting_getbool("log_mods") then
  minetest.log("action", "[working_villages] loaded")
end
print("[working_villages] loaded")
