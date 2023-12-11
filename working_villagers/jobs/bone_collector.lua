local func = working_villages.require("jobs/util")

local bones = {
  -- more priority definitions
	names = {
		["bones:bones"]={},
	},
  -- less priority definitions
	groups = {
		["bones"]={}, -- I made these up
	},
}

function bones.get_bone(item_name)
  -- check more priority definitions
	for key, value in pairs(bones.names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(bones.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end

function bones.is_bone(item_name)
  local data = bones.get_bone(item_name);
  if (not data) then
    return false;
  end
  return true;
end

local function find_bug_node(self)
	return function(pos)
		if minetest.is_protected(pos, self:get_player_name()) then return false end
		if working_villages.failed_pos_test(pos) then return false end

		local node = minetest.get_node(pos);
  		local data = bones.get_bone(node.name);
  		if (not data) then
    			return false;
  		end

  		return true;
	end
end

local searching_range = {x = 10, y = 5, z = 10}

local bonecollecting_demands = {
	--["fireflies:bug_net"] = 1,
}
local function put_func(_,stack)
  return bonecollecting_demands[stack:get_name()] == nil
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not bonecollecting_demands[item_name] then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(bonecollecting_demands[item_name])
	--return (not inv:contains_item("wield_item", itemstack))
	return (not inv:contains_item("main", itemstack))
end

-- copied from the plant/herb collector
working_villages.register_job("working_villages:job_bonecollector", {
	description      = "bone collector (working_villages)",
	long_description = "I look for all sorts of bones and collect them.",
	inventory_image  = "default_paper.png^working_villages_herb_collector.png",
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(take_func, put_func)
		local stack  = self:get_wield_item_stack()
		if stack:is_empty() then
		self:move_main_to_wield(function(name)
  			return bonecollecting_demands[name] ~= nil
		end)
		end
		self:handle_job_pos()

		self:count_timer("bonecollector:search")
		self:count_timer("bonecollector:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("bonecollector:search",20) then
			self:collect_nearest_item_by_condition(bones.is_bone, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_bug_node(self), searching_range)
			if target ~= nil then
				local destination = func.find_adjacent_clear(target)
				if destination then
				  destination = func.find_ground_below(destination)
				end
				if destination==false then
					print("failure: no adjacent walkable found")
					destination = target
				end
				self:set_displayed_action("collecting some bones")
				local success, ret = self:go_to(destination)
				if not success then
					assert(target ~= nil)
					working_villages.failed_pos_record(target)
					self:set_displayed_action("looking at the unreachable bones")
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
		elseif self:timer_exceeded("bonecollector:change_dir",50) then
			-- TODO get death positions of players and bone-spawning entities or use a search pattern
			self:change_direction_randomly()
		end
	end,
})

working_villages.bones = bones
