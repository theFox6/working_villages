local func = working_villages.require("jobs/util")

local herbs = {
  -- more priority definitions
	names = {
		["default:apple"]={},
		["default:cactus"]={collect_only_top=true},
		["default:papyrus"]={collect_only_top=true},
		["default:dry_shrub"]={},
		["farming:wheat_8"]={replant={"farming:seed_wheat"}},
		["flowers:mushroom_brown"]={},
		["flowers:mushroom_red"]={},
	},
  -- less priority definitions
	groups = {
		["flora"]={},
	},
}

function herbs.get_herb(item_name)
  -- check more priority definitions
	for key, value in pairs(herbs.names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(herbs.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end

function herbs.is_herb(item_name)
  local data = herbs.get_herb(item_name);
  if (not data) then
    return false;
  end
  return true;
end

local function find_herb_node(pos)
	local node = minetest.get_node(pos);
  local data = herbs.get_herb(node.name);
  if (not data) then
    return false;
  end
  
  if data.collect_only_top then
    -- prevent to collect plat part, which can continue to grow
    local pos_below = {x=pos.x, y=pos.y-1, z=pos.z}
    local node_below = minetest.get_node(pos_below);
    if (node_below.name~=node.name) then
      return false;
    end
  end
    
  return true;
end

local searching_range = {x = 10, y = 3, z = 10}

working_villages.register_job("working_villages:job_herbcollector", {
	description      = "herb collector (working_villages)",
	long_description = "I look for all sorts of plants and collect them.",
	inventory_image  = "default_paper.png^working_villages_herb_collector.png",
	jobfunc = function(self)
		self:handle_night()
		self:count_timer("herbcollector:search")
		self:count_timer("herbcollector:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("herbcollector:search",20) then
			self:collect_nearest_item_by_condition(herbs.is_herb, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_herb_node, searching_range)
			if target ~= nil then
				local destination = func.find_adjacent_clear(target)
				if destination then
				  destination = func.find_ground_below(destination)
				end
				if destination==false then
					print("failure: no adjacent walkable found")
					destination = target
				end
				self:go_to(destination)
        local herb_data = herbs.get_herb(minetest.get_node(target).name);
				self:dig(target,true)
        if herb_data and herb_data.replant then
          for index, value in ipairs(herb_data.replant) do
				    self:place(value, target)
          end
        end
			end
		elseif self:timer_exceeded("herbcollector:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.herbs = herbs
