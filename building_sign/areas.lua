local areas = {}

function areas.to_string(area)
  return ("%s %s"):format(minetest.pos_to_string(area[1]),minetest.pos_to_string(area[2]))
end

function areas.check_existing(pos)
  for poshash,building in pairs(building_sign.building_store) do
    if areas.is_within(building.area, pos) then
      return building
    end
  end
end

building_sign.areas = areas
return areas
