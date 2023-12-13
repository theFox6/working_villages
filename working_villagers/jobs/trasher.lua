-- throw poops down the hopper
-- throw shoes down the hopper

local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")
local trivia = working_villages.require("jobs/trivia")

local hoppers = {
	names = {
		["hopper:hopper"]={},
		["hopper:hopper_side"]={},
		["hopper:hopper_void"]={},
	},
}

local trashables = {
  -- more priority definitions
	names = {
		["pooper:poop_turd"] = 99,
		["3d_armor:boot_wood"] = 99, -- TODO
	},
  -- less priority definitions
	groups = {
		["boot"]=99,
	},
}
function trashables.get_trashable(item_name)
  -- check more priority definitions
	for key, value in pairs(trashables.names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(trashables.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function trashables.is_trashable(item_name)
  local data = trashables.get_trashable(item_name);
  return data ~= nil
end





function hoppers.get_hopper(item_name)
	-- check more priority definitions
	for key, value in pairs(hoppers.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function hoppers.is_hopper(item_name)
	local data = hoppers.get_hopper(item_name);
	return data ~= nil
end

local function find_hopper_node(pos)
	local node = minetest.get_node(pos);
	local data = hoppers.get_hopper(node.name);
	return data ~= nil
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(_,stack)
	return not trashables.is_trashable(stack:get_name())
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not trashables.is_trashable(item_name) then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(trashables.get_trashable(item_name))
	return (not inv:contains_item("main", itemstack))
end



working_villages.register_job("working_villages:job_trasher", {
	description = S("trasher (working_villages)"),
	long_description = S("I look for a hopper and start throwing the contents of your chest into it."),
	trivia          = trivia.get_trivia({
		"Poops and boots--that's what I do!",
		"I'd do well on the second floor of a shoe shop.",
	}, {trivia.waste_management,}),
	workflow        = {
		S("Wake up"),
		S("Handle my chest"),
		S("Go to work"),
		S("Search for hoppers"),
		S("Go to hopper"),
		S("Handle hopper"),
		S("Periodically look away thoughtfully"),
	},
	inventory_image	= "default_paper.png^working_villages_builder.png",
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(
			take_func, -- take cookable + fuel
			put_func   -- put not(cookable or fuel)
		)
		self:handle_job_pos()

		self:count_timer("trasher:search")
		self:count_timer("trasher:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("trasher:search",20) then
			self:collect_nearest_item_by_condition(hoppers.is_hopper, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_hopper_node, searching_range)
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
					self:set_displayed_action("looking at the unreachable hopper")
					self:delay(100)
				else
					local target_def = minetest.get_node(target)
					local plant_data = hoppers.get_hopper(target_def.name);
					if plant_data then
						self:set_displayed_action("operating the hopper")

						-- TODO drop items near hopper
					end
				end
			end
		elseif self:timer_exceeded("trasher:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.trashables = trashables
