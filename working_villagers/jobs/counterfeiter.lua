local func = working_villages.require("jobs/util")

local fakerytables = {
	names = {
		["fakery:table"]={},
	},
}

local fake_item
if minetest.get_modpath("basic_materials") then
	fake_item = "basic_materials:plastic_sheet"
else
	fake_item = "default:steel_ingot"
end

local fakables = {
	dye_names = {
		["dye:yellow"] = 99,
		["dye:cyan"] = 99,
		["dye:blue"] = 99,
		["dye:white"] = 99,
		["dye:red"] = 99,
		["dye:green"] = 99,
	},
	dye_groups = {
	--	["dye"]=99,
	},
  -- more priority definitions
	names = {
		[fake_item] = 99,
	},
  -- less priority definitions
	groups = {
	--	["ingot"]=99,
	},
}
function fakables.get_fakable(item_name)
	for key, value in pairs(fakables.dye_names) do
		if item_name==key then
			return value
		end
	end
  -- check more priority definitions
	for key, value in pairs(fakables.names) do
		if item_name==key then
			return value
		end
	end
	for key, value in pairs(fakables.dye_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
  -- check less priority definitions
	for key, value in pairs(fakables.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function fakables.is_fakable(item_name)
  local data = fakables.get_fakable(item_name);
  return data ~= nil
end
function fakables.get_cheap_replacement(item_name)
  -- check more priority definitions
	for key, value in pairs(fakables.names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(fakables.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function fakables.is_cheap_replacement(item_name)
  local data = fakables.get_cheap_replacement(item_name);
  return data ~= nil
end
function fakables.get_dye(item_name)
  -- check more priority definitions
	for key, value in pairs(fakables.dye_names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(fakables.dye_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function fakables.is_dye(item_name)
  local data = fakables.get_dye(item_name);
  return data ~= nil
end






function fakerytables.get_fakerytable(item_name)
	-- check more priority definitions
	for key, value in pairs(fakerytables.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function fakerytables.is_fakerytable(item_name)
	local data = fakerytables.get_fakerytable(item_name);
	return data ~= nil
end

local function find_fakerytable_node(pos)
	local node = minetest.get_node(pos);
	local data = fakerytables.get_fakerytable(node.name);
	return data ~= nil
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(_,stack)
	return not fakables.is_fakable(stack:get_name())
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not fakables.is_fakable(item_name) then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(fakables.get_fakable(item_name))
	return (not inv:contains_item("main", itemstack))
end
local function take_func2(villager,stack)
	local item_name = stack:get_name()
	local inv = villager:get_inventory()
	return (inv:room_for_item("main", stack))
end

local function put_dye(_,stack)
	return fakables.is_dye(stack:get_name())
end

local function put_cheap_replacement(_,stack)
	return fakables.is_cheap_replacement(stack:get_name())
end

working_villages.register_job("working_villages:job_counterfeiter", {
	description			= "counterfeiter (working_villages)",
	long_description = "I look for a fakery table and start making novelties.",
	inventory_image	= "default_paper.png^working_villages_builder.png",
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(
			take_func, -- take cheap_replacement + dyes
			put_func   -- put not(cheap_replacement or dye)
		)
		self:handle_job_pos()

		self:count_timer("counterfeiter:search")
		self:count_timer("counterfeiter:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("counterfeiter:search",20) then
			self:collect_nearest_item_by_condition(fakerytables.is_fakerytable, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_fakerytable_node, searching_range)
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
				local plant_data = fakerytables.get_fakerytable(target_def.name);
				if plant_data then
					self:set_displayed_action("operating the furnace")
					self:handle_fakerytable(
					        target,
						take_func2, -- take everything
						put_cheap_replacement, -- put what we need to furnace
						put_dye
					)
					--self.job_data.manipulated_chest   = false;
					--self.job_data.manipulated_furnace = false;
					--self:set_displayed_action("waiting on furnace")
				end
			end
		elseif self:timer_exceeded("counterfeiter:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.fakerytables = fakerytables
