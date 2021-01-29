-- storage

local storage = minetest.get_mod_storage();

-- use key with _ prefix, for non villager data
function working_villages.get_stored_table(key)
  local data = storage:get_string(key);
  if data then
    data = minetest.deserialize(data, false);
    if data then
      return data;
    end
  end
  return {};
end

function working_villages.set_stored_table(key, data)
  storage:set_string(key, minetest.serialize(data));
end


function working_villages.get_stored_villager_table(self)
  local data = storage:get_string(self.inventory_name);
  if data then
    data = minetest.deserialize(data, false);
    if data then
      return data;
    end
  end
  return {};
end

function working_villages.set_stored_villager_table(self, data)
  storage:set_string(self.inventory_name, minetest.serialize(data));
end

