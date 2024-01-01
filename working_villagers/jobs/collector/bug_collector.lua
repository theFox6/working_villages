local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")
local trivia = working_villages.require("jobs/trivia")

local bugs = {
  -- more priority definitions
	names = {
		["fireflies:firefly"]={},
		["butterflies:butterfly_red"]={},
		["butterflies:butterfly_white"]={},
		["butterflies:butterfly_violet"]={},
	},
  -- less priority definitions
	groups = {
		["bugs"]={}, -- I made these up
		["butterflies"]={}, -- whatever
	},
}

function bugs.get_bug(item_name)
  -- check more priority definitions
	for key, value in pairs(bugs.names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(bugs.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end

function bugs.is_bug(item_name)
  local data = bugs.get_bug(item_name);
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
  		local data = bugs.get_bug(node.name);
  		if (not data) then
    			return false;
  		end

  		return true;
	end
end

local searching_range = {x = 10, y = 5, z = 10}

local bugcatching_demands = {
	["fireflies:bug_net"] = 1,
}
local function put_func(_,stack)
  return bugcatching_demands[stack:get_name()] == nil
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not bugcatching_demands[item_name] then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(bugcatching_demands[item_name])
	--return (not inv:contains_item("wield_item", itemstack))
	return (not inv:contains_item("main", itemstack))
end

-- copied from the plant/herb collector
working_villages.register_job("working_villages:job_bugcollector", {
	description      = S("bug collector (working_villages)"),
	long_description = S("I look for all sorts of bugs and collect them."),
	trivia = trivia.get_trivia({}, {trivia.herb_collector,}),
	workflow = {
		--S("Wake up"),
		S("Handle my chest"),
		S("Equip my tool"),
		S("Go to work"),
		S("Search for bugs"),
		S("Go to bugs"),
		-- TODO handle entity-type bugs
		S("Collect (dig) bugs"),
		S("Periodically look away thoughtfully"),
	},
	inventory_image  = "default_paper.png^working_villages_herb_collector.png",
	jobfunc = function(self)
		local shift_mode = self:get_job_data("mode") or "dayshift"

		if shift_mode == "dayshift" then
			self:handle_night()
		elseif shift_mode == "nightshift" then
			self.handle_day()
		else
			self:set_displayed_action("No sleep schedule assigned!")
			assert(false)
		end
			
		self:handle_chest(take_func, put_func)
		local stack  = self:get_wield_item_stack()
		if stack:is_empty() then
		self:move_main_to_wield(function(name)
  			return bugcatching_demands[name] ~= nil
		end)
		end
		self:handle_job_pos()

		self:count_timer("bugcollector:search")
		self:count_timer("bugcollector:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("bugcollector:search",20) then
			self:collect_nearest_item_by_condition(bugs.is_bug, searching_range)
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
				self:set_displayed_action("collecting some bugs")
				local success, ret = self:go_to(destination)
				if not success then
					assert(target ~= nil)
					working_villages.failed_pos_record(target)
					self:set_displayed_action("looking at the unreachable bugs")
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
		elseif self:timer_exceeded("bugcollector:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.bugs = bugs
