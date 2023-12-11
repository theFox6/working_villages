local func = working_villages.require("jobs/util")

local claycrafters = {
	names = {
		["claycrafter:claycrafter"]={},
		["claycrafter:claycrafter_active"]={},
	},
}

local craftables = {
	fuel_names = {
		--["vessels:drinking_glass"] = 99,
		["claycrafter:glass_of_water"] = 99,
	},
	fuel_groups = { },
  -- more priority definitions
	names = {
		["moreblocks:dirt_compressed"] = 99,
		["claycrafter:compressed_dirt"] = 99,
	},
  -- less priority definitions
	groups = { },
}
function craftables.get_craftable(item_name)
	for key, value in pairs(craftables.fuel_names) do
		if item_name==key then
			return value
		end
	end
  -- check more priority definitions
	for key, value in pairs(craftables.names) do
		if item_name==key then
			return value
		end
	end
	for key, value in pairs(craftables.fuel_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
  -- check less priority definitions
	for key, value in pairs(craftables.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function craftables.is_craftable(item_name)
  local data = craftables.get_craftable(item_name);
  return data ~= nil
end
function craftables.get_dirts(item_name)
  -- check more priority definitions
	for key, value in pairs(craftables.names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(craftables.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function craftables.is_dirts(item_name)
  local data = craftables.get_dirts(item_name);
  return data ~= nil
end
function craftables.get_fuel(item_name)
  -- check more priority definitions
	for key, value in pairs(craftables.fuel_names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(craftables.fuel_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function craftables.is_fuel(item_name)
  local data = craftables.get_fuel(item_name);
  return data ~= nil
end






function claycrafters.get_claycrafter(item_name)
	-- check more priority definitions
	for key, value in pairs(claycrafters.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function claycrafters.is_claycrafter(item_name)
	local data = claycrafters.get_claycrafter(item_name);
	return data ~= nil
end

local function find_claycrafter_node(pos)
	local node = minetest.get_node(pos);
	local data = claycrafters.get_claycrafter(node.name);
	return data ~= nil
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(_,stack)
	return not craftables.is_craftable(stack:get_name())
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not craftables.is_craftable(item_name) then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(craftables.get_craftable(item_name))
	return (not inv:contains_item("main", itemstack))
end
local function take_func2(villager,stack)
	local item_name = stack:get_name()
	local inv = villager:get_inventory()
	return (inv:room_for_item("main", stack))
end

local function put_lock(_,stack)
	return craftables.is_fuel(stack:get_name())
end

local function put_unlocked(_,stack)
	return craftables.is_dirts(stack:get_name())
end

working_villages.register_job("working_villages:job_claycrafter", {
	description			= "claycrafter (working_villages)",
	long_description = "I look for a clay crafter and start sieving dirt.",
	inventory_image	= "default_paper.png^working_villages_builder.png",
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(
			take_func,
			put_func
		)
		self:handle_job_pos()

		self:count_timer("claycrafter:search")
		self:count_timer("claycrafter:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("claycrafter:search",20) then
			self:collect_nearest_item_by_condition(claycrafters.is_claycrafter, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_claycrafter_node, searching_range)
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
				local target_def = minetest.get_node(target)
				local plant_data = claycrafters.get_claycrafter(target_def.name);
				if plant_data then
					self:set_displayed_action("operating the claycrafter")
					self:handle_claycrafter(
					        target,
						take_func2,
						put_unlocked,
						put_lock
					)
					--self.job_data.manipulated_chest   = false;
					--self.job_data.manipulated_furnace = false;
					--self:set_displayed_action("waiting on furnace")
				end
			end
		elseif self:timer_exceeded("claycrafter:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.claycrafters = claycrafters
