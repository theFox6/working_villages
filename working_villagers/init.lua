local init = os.clock()
minetest.log("action", "["..minetest.get_current_modname().."] loading init")

working_villages={
	modpath = minetest.get_modpath("working_villages"),
}

if not minetest.get_modpath("modutil") then
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
working_villages.require("fake_player")
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
working_villages.require("jobs/farmer")
working_villages.require("jobs/woodcutter")
--testing jobs
working_villages.require("jobs/torcher")
working_villages.require("jobs/snowclearer")
-- IA jobs
working_villages.require("jobs/thief")
working_villages.require("jobs/brush_collector")
working_villages.require("jobs/bug_collector")
working_villages.require("jobs/bone_collector")
working_villages.require("jobs/landscaper")
working_villages.require("jobs/watercarrier")
working_villages.require("jobs/miner")
working_villages.require("jobs/gem_miner")
working_villages.require("jobs/mayor")
working_villages.require("jobs/baker")
--working_villages.require("jobs/hider")
if minetest.get_modpath("mcg_lockworkshop") then
	working_villages.require("jobs/locksmith")
end
if minetest.get_modpath("fakery") then
	working_villages.require("jobs/counterfeiter")
end
if minetest.get_modpath("mcg_dyemixer") then
	working_villages.require("jobs/dyemixer")
end
if minetest.get_modpath("claycrafter") then
	working_villages.require("jobs/claycrafter")
end
if minetest.get_modpath("decraft") then
	working_villages.require("jobs/recycler")
end
if minetest.get_modpath("crafting_bench")
or minetest.get_modpath("craft_table") then
	working_villages.require("jobs/craftsman")
end
if minetest.get_modpath("iadiscordia") then
	working_villages.require("jobs/wizard")
end
working_villages.require("jobs/gardener")
if minetest.get_modpath("biofuel") then
	working_villages.require("jobs/biofuel")
end
if minetest.get_modpath("composting") then
	working_villages.require("jobs/composter")
end
if minetest.get_modpath("snowcone") then
	working_villages.require("jobs/snowcone")
end
if minetest.get_modpath("waffles") then
	working_villages.require("jobs/waffle")
end
if minetest.get_modpath("church_candles") then
	working_villages.require("jobs/beekeeper")
end
if minetest.get_modpath("hopper") then
	working_villages.require("jobs/trasher")
end
-- TODO WIP
--if minetest.get_modpath("wine") then
--	working_villages.require("jobs/brewer")
--end

if working_villages.setting_enabled("spawn",false) then
  working_villages.require("spawn")
end

if working_villages.setting_enabled("debug_tools",false) then
  working_villages.require("util_test")
end

--ready
local time_to_load= os.clock() - init
log.action("loaded init in %.4f s", time_to_load)

