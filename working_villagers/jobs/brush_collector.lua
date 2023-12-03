local func = working_villages.require("jobs/util")

local shrubs = {
  -- more priority definitions
	names = {
		["default:blueberry_bush_leaves_with_berries"]={},
		["default:cactus"]={collect_only_top=true},
		["default:papyrus"]={collect_only_top=true},
		["default:bush_leaves"]={},
		["default:bush_stem"]={},
		--["flowers:mushroom_red"]={},
	},
  -- less priority definitions
	groups = {
		["leaves"]={},
		--["wood"]={},
	},
}

function shrubs.get_shrub(item_name)
  -- check more priority definitions
	for key, value in pairs(shrubs.names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(shrubs.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end

function shrubs.is_shrub(item_name)
  local data = shrubs.get_shrub(item_name);
  if (not data) then
    return false;
  end
  return true;
end

local function find_herb_node(self)
	return function(pos)
		if minetest.is_protected(pos, self:get_player_name()) then return false end
		if working_villages.failed_pos_test(pos) then return false end

		local node = minetest.get_node(pos);
  		local data = shrubs.get_shrub(node.name);
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

  		return true;
	end
end

local searching_range = {x = 10, y = 5, z = 10}

local function put_func()
  return true;
end

-- copied from the plant/herb collector
working_villages.register_job("working_villages:job_brushcollector", {
	description      = "brush collector (working_villages)",
	long_description = "I look for all sorts of brush and collect it.",
	inventory_image  = "default_paper.png^working_villages_herb_collector.png",
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(nil, put_func)
		self:handle_job_pos()

		self:count_timer("brushcollector:search")
		self:count_timer("brushcollector:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("brushcollector:search",20) then
			self:collect_nearest_item_by_condition(shrubs.is_shrub, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_herb_node(self), searching_range)
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
        --local herb_data = shrubs.get_shrub(minetest.get_node(target).name);
        --shrubs.get_shrub(minetest.get_node(target).name);
				--self:dig(target,true)
				self:set_displayed_action("collecting some brush")
				local success, ret = self:go_to(destination)
				if not success then
					assert(target ~= nil)
					working_villages.failed_pos_record(target)
					self:set_displayed_action("looking at the unreachable brush")
					self:delay(100)
				else
					success, ret = self:dig(target,true)
					if not success then
						assert(target ~= nil)
						working_villages.failed_pos_record(target)
						self:set_displayed_action("confused as to why collecting failed")
						self:delay(100)
					end
				end
			end
		elseif self:timer_exceeded("brushcollector:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.shrubs = shrubs
