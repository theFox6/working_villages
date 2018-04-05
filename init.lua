local init = os.clock()
if minetest.settings:get_bool("log_mods") then
  minetest.log("action", "[MOD] "..minetest.get_current_modname()..": loading")
else
  print("[MOD] "..minetest.get_current_modname()..": loading")
end

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

dofile(working_villages.modpath.."/capture_rod.lua")

--jobs
dofile(working_villages.modpath.."/jobs/util.lua")
dofile(working_villages.modpath.."/jobs/empty.lua")

dofile(working_villages.modpath.."/jobs/plant_collector.lua")
dofile(working_villages.modpath.."/jobs/woodcutter.lua")
--testing jobs
dofile(working_villages.modpath.."/jobs/follow_player.lua")
dofile(working_villages.modpath.."/jobs/torcher.lua")
dofile(working_villages.modpath.."/jobs/snowclearer.lua")

--ready
local time_to_load= os.clock() - init
if minetest.settings:get_bool("log_mods") then
  minetest.log("action", string.format("[MOD] "..minetest.get_current_modname()..": loaded in %.4f s", time_to_load))
else
  print(string.format("[MOD] "..minetest.get_current_modname()..": loaded in %.4f s", time_to_load))
end
