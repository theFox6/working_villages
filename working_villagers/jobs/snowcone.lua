-- TODO under development

local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")

-- limited support to two replant definitions
local fruteria_nodes = {
	names = {
		["snowcone:container"]={},
	},
}

local snowcone_demands = {
	["snowcone:raw"] = 99,
}
local snowcone_refills = {
	["snowcone:bucket_syrup_grape"] = 99,
	["snowcone:bucket_syrup_banana"] = 99,
	["snowcone:bucket_syrup_orange"] = 99,
	["snowcone:bucket_syrup_blueberry"] = 99,
	["snowcone:bucket_syrup_pineapple"] = 99,
	["snowcone:bucket_syrup_raspberry"] = 99,
	["snowcone:bucket_syrup_strawberry"] = 99,
	["snowcone:bucket_syrup_watermelon"] = 99,
}

function fruteria_nodes.get_fruiteria(item_name)
	-- check more priority definitions
	for key, value in pairs(fruteria_nodes.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function fruteria_nodes.is_fruiteria(item_name)
	local data = fruteria_nodes.get_fruiteria(item_name);
	if (not data) then
		return false;
	end
	return true;
end

local function find_fruiteria_node(self)
	return function(pos)
		if minetest.is_protected(pos, self:get_player_name()) then return false end
		if working_villages.failed_pos_test(pos) then return false end

		local node = minetest.get_node(pos);
		local data = fruteria_nodes.get_fruiteria(node.name);
		if (not data) then
			return false;
		end
		return true
	end
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(_,stack)
	if snowcone_demands[stack:get_name()] then
		return false
	end
	if snowcone_refills[stack:get_name()] then
		return false
	end
	return true;
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if snowcone_demands[item_name]
	or snowcone_refills[item_name] then
		local inv = villager:get_inventory()
		local itemstack = ItemStack(item_name)
		local count     = snowcone_demands[item_name]
		if count == nil then
			count   = snowcone_refills[item_name]
			assert(count ~= nil)
		end
		itemstack:set_count(count)
		if (not inv:contains_item("main", itemstack)) then
			return true
		end
	end
	return false
end

working_villages.register_job("working_villages:job_snowcone", {
	description			= "snowcone (working_villages)",
	long_description = "I look for snowcone machines and start putting syrup on some shaved ice."
	inventory_image	= "default_paper.png^working_villages_farmer.png",
	trivia = {
		"I'm part of the break basket infrastructure.",
	},
	workflow = {
		"Wake up",
		"Handle my chest",
		"Go to work",
		"Search for snow cone makers",
		"Go to snow cone maker",
		"Equip my tool",
		"Refill snow cone maker",
		"Use \"raw\" snow cone on snow cone maker",
		"Periodically look away thoughtfully",
	},
	jobfunc = function(self)
		self:handle_night()
		local stack  = self:get_wield_item_stack()
		if stack:is_empty() then
			self:handle_chest(take_func, put_func)
		end
		--if stack:is_empty() then
		--	self:move_main_to_wield(function(name)
  		--		return snowcone_refills[name] ~= nil
		--	end)
		--end
		self:handle_job_pos()

		self:count_timer("snowcone:search")
		self:count_timer("snowcone:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("snowcone:search",20) then
			self:collect_nearest_item_by_condition(fruteria_nodes.is_fruiteria, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_fruiteria_node(self), searching_range)
			if target ~= nil then
				local destination = func.find_adjacent_clear(target)
				if destination then
					destination = func.find_ground_below(destination)
				end
				if destination==false then
					print("failure: no adjacent walkable found")
					destination = target
				end
				local plant_name = minetest.get_node(target).name


				local meta = minetest.get_meta(target)
				if stack:is_empty() then
					local flavor = meta:get_string("flavor")
					self:move_main_to_wield(function(name)
						if flavor ~= nil then -- use same flavor that's already in the matchine
							return item:match("^snowcone:bucket_syrup_"..flavor)
						end
						-- use any flavor
  						return snowcone_refills[name] ~= nil
					end)
				end


				self:set_displayed_action("making some snowcones")
				local success, ret = self:go_to(destination)
				if not success then
					assert(target ~= nil)
					working_villages.failed_pos_record(target)
					self:set_displayed_action("looking at the unreachable snowcone machine")
					self:delay(100)
				else
					local level = meta:get_int("level")
					if level == 0 then -- refill the machine
						local plant_data = fruteria_nodes.get_fruiteria(plant_name)
						local flag, new_stack = working_villages.use_item(self, stack)
						if flag then self:set_wield_item_stack(new_stack) end
					else -- make snowcones
				
						local vil_inv = self:get_inventory();

						-- from villager to chest
						--if put_func then
						local size = vil_inv:get_size("main");
						for index = 1,size do
							stack = vil_inv:get_stack("main", index);
							if (not stack:is_empty()) then --and (put_func(self, stack, data)) then
								--local chest_meta = minetest.get_meta(chest_pos);
								--local chest_inv = chest_meta:get_inventory();
								--local leftover = chest_inv:add_item("main", stack);
								--vil_inv:set_stack("main", index, leftover);
								--for _=0,10 do coroutine.yield() end --wait 10 steps
								flag, new_stack = working_villages.use_item(self, stack)
								if flag then vil_inv_set:stack("main", index, new_stack) end
							end
						end
						--end
					end
				end
			end
		elseif self:timer_exceeded("snowcone:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.fruteria_nodes = fruteria_nodes
