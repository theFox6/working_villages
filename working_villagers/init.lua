local init = os.clock()
minetest.log("action", "["..minetest.get_current_modname().."] loading init")

local modpath = minetest.get_modpath("working_villages")
local log = modutil.require("log").make_loggers()

working_villages={
	modpath = modpath,
	func = {},
	log = log,
  check_modname_prefix = modutil.require("check_prefix"),
}

local modules = {
  init = working_villages, -- just in case anybody tries funny stuff
  log = log -- caution: this will prevent loading a file named log.lua
}

function working_villages.require(module)
  if not modules[module] then
    log.info("loading "..module)
    modules[module] = dofile(modpath.."/"..module..".lua") or true
    log.info("loaded "..module)
  end
  return modules[module]
end

--helpers
working_villages.require("failures")
working_villages.require("pathfinder")

--content
working_villages.require("forms")
working_villages.require("talking")
working_villages.require("building")

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

--ready
local time_to_load= os.clock() - init
log.action("loaded init in %.4f s", time_to_load)
