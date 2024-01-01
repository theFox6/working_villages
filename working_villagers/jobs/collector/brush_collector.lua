local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")
local trivia = working_villages.require("jobs/trivia")

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
		["stick"]={},
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


-- copied from the plant/herb collector
working_villages.register_job("working_villages:job_brushcollector", {
	description      = S("brush collector (working_villages)"),
	long_description = S("I look for all sorts of brush and collect it."),
	trivia = trivia.get_trivia({
		"I just pick up a few things that the herb collector and wood cutter leave behind.",
	}, {trivia.herb_collector,}),
	workflow = {
		S("Wake up"),
		S("Handle my chest"),
		S("Go to work"),
		S("Search for brush"),
		S("Go to brush"),
		S("Collect (dig) brush"),
		S("Periodically look away thoughtfully"),
	},
	inventory_image  = "default_paper.png^working_villages_herb_collector.png",
	jobfunc = function(self)
		self:handle_night()
		-- TODO wield item ?
		self:handle_chest(nil, func.put_everything)
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
