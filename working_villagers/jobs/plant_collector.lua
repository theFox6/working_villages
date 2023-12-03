local func = working_villages.require("jobs/util")

local herbs = {
  -- more priority definitions
	names = {
		["default:apple"]={},
		["default:cactus"]={collect_only_top=true},
		["default:papyrus"]={collect_only_top=true},
		["default:dry_shrub"]={},
		["flowers:mushroom_brown"]={responsible_foraging=true},
		["flowers:mushroom_red"]={responsible_foraging=true},
	},
  -- less priority definitions
	groups = {
		["flora"]={responsible_foraging=true},
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
		if minetest.is_protected(p, "") then return false end
		if working_villages.failed_pos_test(p) then return false end

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
    local pos_above = {x=pos.x, y=pos.y+1, z=pos.z}
    local node_above = minetest.get_node(pos_above);
    if (node_above.name==node.name) then
      return false;
    end
  end

  if data.responsible_foraging then
    return minetest.find_node_near(pos, 9, node.name) ~= nil
  end

  return true;
end

local searching_range = {x = 10, y = 5, z = 10}

local function put_func()
  return true;
end

working_villages.register_job("working_villages:job_herbcollector", {
	description      = "herb collector (working_villages)",
	long_description = "I look for all sorts of plants and collect them.",
	inventory_image  = "default_paper.png^working_villages_herb_collector.png",
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(nil, put_func)
		self:handle_job_pos()

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
				--self:go_to(destination)
				self:set_displayed_action("collecting some plants")
				local success, ret = self:go_to(destination)
        --local herb_data = herbs.get_herb(minetest.get_node(target).name);
        --herbs.get_herb(minetest.get_node(target).name);
				--self:dig(target,true)
				if not success then
					working_villages.failed_pos_record(target)
					self:set_displayed_action("looking at the unreachable plant")
					self:delay(100)
				else
					success, ret = self:dig(target,true)
					if not success then
						working_villages.failed_pos_record(target)
						self:set_displayed_action("confused as to why collecting failed")
						self:delay(100)
					end
				end
			end
		elseif self:timer_exceeded("herbcollector:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.herbs = herbs
