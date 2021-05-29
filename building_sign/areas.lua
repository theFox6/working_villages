local building_store = building_sign.require("building_store","venus")
local log = building_sign.require("log")

local areas = {}
local store = AreaStore()
local file_name = minetest.get_worldpath() .. "/building_sign_areas"

function areas.load()
  local success,err = store:from_file(file_name)
  if not success then
    log.error("error while trying to load building_sign_areas: "..err)
  end
end

areas.load()

function areas.save()
  local success,err = store:to_file(file_name)
  if not success then
    log.error("error while trying to save building_sign_areas: "..err)
  end
end

minetest.register_on_shutdown(areas.save)

--[[unused?
function areas.to_string(area)
  return ("%s %s"):format(minetest.pos_to_string(area[1]),minetest.pos_to_string(area[2]))
end
]]

local function map(t,f)
  local ret = {}
  for i,v in pairs(t) do
    ret[i] = f(v)
  end
  return ret
end

function areas.get_building(pos)
  local a = store:get_areas_for_pos(pos, false, true)
  local f = next(a)
  if f == nil then
    return false
  end
  local s = next(a,f)
  if s then
    log.warning("found multiple buildings at pos: " .. minetest.pos_to_string(pos))
    return map(a,function(d) return building_store[d.data] end)
  end
  local ph = f.data
  local building = building_store[ph]
  if building == nil then
    log.warning("building area without building data for "..ph)
  end
  return building
end

function areas.add_building(building)
  store:insert_area(building.area[1], building.area[2], building.id)
end

function areas.remove_building(building)
  local found = store:get_areas_in_area(building.area[1], building.area[2], false, false, true)
  for id,a in pairs(found) do
    if tonumber(a.data) == building.id then
      store:remove_area(id)
      return true
    end
  end
end

building_sign.areas = areas
return areas
