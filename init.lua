local init = os.clock()
minetest.log("action", "["..minetest.get_current_modname().."] loading...")

working_villages={
	modpath=minetest.get_modpath("working_villages"),
	func = {}
}

--helpers
dofile(working_villages.modpath.."/util.lua")
dofile(working_villages.modpath.."/pathfinder.lua")
dofile(working_villages.modpath.."/forms.lua")
dofile(working_villages.modpath.."/building.lua")

--base
dofile(working_villages.modpath.."/api.lua")
dofile(working_villages.modpath.."/register.lua")
dofile(working_villages.modpath.."/commanding_sceptre.lua")

dofile(working_villages.modpath.."/deprecated.lua")

--jobs
dofile(working_villages.modpath.."/jobs/util.lua")
dofile(working_villages.modpath.."/jobs/empty.lua")

dofile(working_villages.modpath.."/jobs/builder.lua")
dofile(working_villages.modpath.."/jobs/follow_player.lua")
dofile(working_villages.modpath.."/jobs/plant_collector.lua")
dofile(working_villages.modpath.."/jobs/woodcutter.lua")
--testing jobs
dofile(working_villages.modpath.."/jobs/torcher.lua")
dofile(working_villages.modpath.."/jobs/snowclearer.lua")

--ready
local time_to_load= os.clock() - init
working_villages.log.action(false, "loaded in %.4f s", time_to_load)
