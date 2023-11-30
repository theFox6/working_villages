
local func = working_villages.require("jobs/util")

-- limited support to two replant definitions
local refineries = {
	names = {
		["biofuel:refinery"]={},
		["biofuel:refinery_active"]={},
	},
}

--local bakables = {
--	names = {
--		["farming:flour"] = 99,
--		["default:cobble"] = 99,
--		["default:mossycobble"] = 99,
--		["default:desert_cobble"] = 99,
--		["default:clay_lump"] = 99,
--		["default:iron_lump"] = 99,
--		["default:copper_lump"] = 99,
--		["default:tin_lump"] = 99,
--		["default:gold_lump"] = 99,
--		["vessels:glass_fragments"] = 99,
--		["default:obsidian_shard"] = 99,
--	},
--  -- less priority definitions
--	groups = {
--		["ore"]=99,
--		["sand"]=99,
--	},
--}


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





--function bakables.get_bakable(item_name)
--  -- check more priority definitions
--	for key, value in pairs(bakables.names) do
--		if item_name==key then
--			return value
--		end
--	end
--  -- check less priority definitions
--	for key, value in pairs(bakables.groups) do
--		if minetest.get_item_group(item_name, key) > 0 then
--			return value;
--		end
--	end
--	return nil
--end
--function bakables.is_bakable(item_name)
--  local data = bakables.get_bakable(item_name);
--  return data ~= nil
--end
--function bakables.get_cookable(item_name)
--  -- check more priority definitions
--	for key, value in pairs(bakables.names) do
--		if item_name==key then
--			return value
--		end
--	end
--  -- check less priority definitions
--	for key, value in pairs(bakables.groups) do
--		if minetest.get_item_group(item_name, key) > 0 then
--			return value;
--		end
--	end
--	return nil
--end
--function bakables.is_cookable(item_name)
--  local data = bakables.get_cookable(item_name);
--  return data ~= nil
--end





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
	--return not bakables.is_bakable(stack:get_name())
	return not is_convertible(stack:get_name())
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	--if not bakables.is_bakable(item_name) then return false end
	if not is_convertible(item_name) then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	--itemstack:set_count(bakables.get_bakable(item_name))
	itemstack:set_count(99)
	return (not inv:contains_item("main", itemstack))
end
local function take_func2(villager,stack)
	local item_name = stack:get_name()
	local inv = villager:get_inventory()
	return (inv:room_for_item("main", stack))
end

local function put_cookable(_,stack)
	--return bakables.is_cookable(stack:get_name())
	return is_convertible(stack:get_name())
end

working_villages.register_job("working_villages:job_biofuel", {
	description			= "biofuel (working_villages)",
	long_description = "I look for a refinery and start putting the contents of your chest into it.",
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
				self:go_to(destination)
				local target_def = minetest.get_node(target)
				local plant_data = refineries.get_refinery(target_def.name);
				if plant_data then
					self:set_displayed_action("operating the refinery")
					self:handle_refinery(
					        target,
						take_func2, -- take everything
						put_cookable -- put what we need to refinery
					)
					--self.job_data.manipulated_chest   = false;
					--self.job_data.manipulated_refinery = false;
					--self:set_displayed_action("waiting on refinery")
				end
			end
		elseif self:timer_exceeded("biofuel:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.refinery_names = refinery_names
