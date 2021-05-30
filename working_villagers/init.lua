local init = os.clock()
minetest.log("action", "["..minetest.get_current_modname().."] loading init") 

working_villages={
	modpath = minetest.get_modpath("working_villages"),
}

if not modutil then
    dofile(working_villages.modpath.."/modutil/portable.lua")
end

modutil.require("local_require")(working_villages)
local log = working_villages.require("log")

function working_villages.setting_enabled(name, default)
  local b = minetest.settings:get_bool("working_villages_enable_"..name)
  if b == nil then
    if default == nil then
      return false
    end
    return default
  end
  return b
end

working_villages.require("groups")
--TODO: check for which preloading is needed
--content
working_villages.require("forms")
working_villages.require("talking")
--TODO: instead use the building sign mod when it is ready
working_villages.require("building")
working_villages.require("storage")

--base
working_villages.require("api")
working_villages.require("register")
working_villages.require("commanding_sceptre")

working_villages.require("deprecated")

--job helpers
working_villages.require("jobs/util")
working_villages.require("jobs/empty")
--base jobs
working_villages.require("jobs/builder")
working_villages.require("jobs/follow_player")
working_villages.require("jobs/guard")
working_villages.require("jobs/plant_collector")
working_villages.require("jobs/woodcutter")
--testing jobs
working_villages.require("jobs/torcher")
working_villages.require("jobs/snowclearer")

if working_villages.setting_enabled("debug_tools",false) then
  working_villages.require("util_test")
end

--ready
local time_to_load= os.clock() - init
log.action("loaded init in %.4f s", time_to_load)
