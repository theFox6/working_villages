
local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")

-- limited support to two replant definitions
local refineries = {
	names = {
		["biofuel:refinery"]={},
		["biofuel:refinery_active"]={},
	},
}

local function is_convertible(input)
                if biomass.convertible_items[input] then
                        return true
                end
        if food_fuel then
                if biomass.food_waste[input] then
                        return true
                end
        else end
        for _, v in pairs(biomass.convertible_groups) do
                if minetest.get_item_group(input, v) > 0 then
                        return true
                end
        end
        return false
end

function refineries.get_refinery(item_name)
	-- check more priority definitions
	for key, value in pairs(refineries.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function refineries.is_refinery(item_name)
	local data = refineries.get_refinery(item_name);
	return data ~= nil
end

local function find_refinery_node(pos)
	local node = minetest.get_node(pos);
	local data = refineries.get_refinery(node.name);
	return data ~= nil
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(_,stack)
	return not is_convertible(stack:get_name())
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not is_convertible(item_name) then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(99)
	return (not inv:contains_item("main", itemstack))
end

local function put_cookable(_,stack)
	return is_convertible(stack:get_name())
end

working_villages.register_job("working_villages:job_biofuel", {
	description			= "biofuel (working_villages)",
	long_description = "I look for a refinery and start putting the contents of your chest into it.",
	trivia = {
		"I'm part of the pooper scooper crew!",
		"I fuel the military-industrial complex.",
	},
	workflow = {
		"Wake up",
		"Handle my chest",
		"Go to work",
		"Search for refineries",
		"Go to refinery",
		"Handle refinery",
		"Periodically look away thoughtfully",
	},
	inventory_image	= "default_paper.png^working_villages_builder.png",
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(
			take_func, -- take cookable + fuel
			put_func   -- put not(cookable or fuel)
		)
		self:handle_job_pos()

		self:count_timer("biofuel:search")
		self:count_timer("biofuel:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("biofuel:search",20) then
			self:collect_nearest_item_by_condition(refineries.is_refinery, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_refinery_node, searching_range)
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
					self:set_displayed_action("looking at the unreachable refinery")
					self:delay(100)
				else
					local target_def = minetest.get_node(target)
					local plant_data = refineries.get_refinery(target_def.name);
					if plant_data then
						self:set_displayed_action("operating the refinery")
						self:handle_refinery(
						        target,
							func.take_everything, -- take everything
							put_cookable -- put what we need to refinery
						)
						--self.job_data.manipulated_chest   = false;
						--self.job_data.manipulated_refinery = false;
						--self:set_displayed_action("waiting on refinery")
					end
				end
			end
		elseif self:timer_exceeded("biofuel:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.refinery_names = refinery_names
