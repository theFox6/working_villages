local func = working_villages.require("jobs/util")

local recyclers = {
	names = {
		["decraft:table"]={},
		["uncraft:uncrafttable"]={},
	},
}

local recyclables = {
	whitelist_names = { -- TODO whitelist
		--["vessels:drinking_glass"] = 99,
		--["recycler:glass_of_water"] = 99,
	},
	whitelist_groups = { },
  -- more priority definitions
	blacklist_names = {
		["bucket:bucket_water"] = 1,
		["default:obsidian"] = 1,
		["default:steel_ingot"] = 1,
		["vessels:steel_bottle"] = 1,
		["default:papyrus"] = 1,
	},
  -- less priority definitions
	blacklist_groups = { },
}
function recyclables.get_recyclable(item_name)
  -- check more priority definitions
	for key, value in pairs(recyclables.whitelist_names) do
		if item_name==key then
			return value
		end
	end
	for key, value in pairs(recyclables.whitelist_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
  -- check less priority definitions
	for key, value in pairs(recyclables.blacklist_names) do
		if item_name==key then
			--return value
			return nil
		end
	end
	for key, value in pairs(recyclables.blacklist_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			--return value;
			return nil
		end
	end
	--return nil
	return 99
end
function recyclables.is_recyclable(item_name)
  local data = recyclables.get_recyclable(item_name);
  return data ~= nil
end





function recyclers.get_recycler(item_name)
	-- check more priority definitions
	for key, value in pairs(recyclers.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function recyclers.is_recycler(item_name)
	local data = recyclers.get_recycler(item_name);
	return data ~= nil
end

local function find_recycler_node(pos)
	local node = minetest.get_node(pos);
	local data = recyclers.get_recycler(node.name);
	return data ~= nil
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(villager,stack)
	assert(villager ~= nil)
	assert(stack    ~= nil)
	if not func.is_half_empty(villager) then return true end
	return not recyclables.is_recyclable(stack:get_name())
end
local function take_func(villager,stack)
	assert(villager ~= nil)
	assert(stack    ~= nil)
	if not func.is_half_empty(villager) then return false end
	local item_name = stack:get_name()
	if not recyclables.is_recyclable(item_name) then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(recyclables.get_recyclable(item_name))
	return (not inv:contains_item("main", itemstack))
end

local function put_recyclables(villager,stack)
	assert(villager ~= nil)
	assert(stack    ~= nil)
	--if not func.is_half_empty(villager) then return true end
	return recyclables.is_recyclable(stack:get_name())
end

working_villages.register_job("working_villages:job_recycler", {
	description			= "recycler (working_villages)",
	long_description = "I look for a recycler and save the planet with your junk.",
	trivia = {
		"I'm part of the pooper scooper crew!",
		"I clean up after the military-industrial complex.",
	},
	workflow = {
		"Wake up",
		"Handle my chest",
		--"Equip my tool",
		"Go to work",
		"Search for recyclers",
		"Go to recycler",
		"Handle recycler",
		"Periodically look away thoughtfully",
	},
	inventory_image	= "default_paper.png^working_villages_builder.png",
	jobfunc = function(self)
		self:handle_night()
		
		--self.job_data.manipulated_chest = false
		assert(take_func ~= nil)
		assert(put_func  ~= nil)
		self:handle_chest(
			take_func, -- take unlocked + locks
			put_func   -- put not(unlocked or whitelist)
		)
		--assert(func.is_half_empty(self))
		self:handle_job_pos()

		self:count_timer("recycler:search")
		self:count_timer("recycler:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("recycler:search",20) then
			self:collect_nearest_item_by_condition(recyclers.is_recycler, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_recycler_node, searching_range)
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
				local success, ret = self:go_to(destination)
				if not success then
					working_villages.failed_pos_record(target)
					self:set_displayed_action("looking at the unreachable recycler")
					self:delay(100)
				else
					local target_def = minetest.get_node(target)
					local plant_data = recyclers.get_recycler(target_def.name);
					if plant_data then
						self:set_displayed_action("operating the recycler")
						assert(put_recyclables  ~= nil)
						self:handle_recycler(
						        target,
							func.take_everything, -- take everything
							put_recyclables -- put what we need to furnace
						)
						--self.job_data.manipulated_chest   = false;
						--self.job_data.manipulated_furnace = false;
						--self:set_displayed_action("waiting on furnace")
					end
					self.job_data.manipulated_chest = self.job_data.manipulated_chest and not func.is_half_empty(self)
				end
			end
		elseif self:timer_exceeded("recycler:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.recyclers = recyclers

