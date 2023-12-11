-- TODO under development

local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")

-- limited support to two replant definitions
local wafflehaus_nodes = {
	names = {
		["waffles:waffle_maker"]={},
		["waffles:waffle_maker_open"]={},
	},
}

local waffle_demands = {
	["waffles:waffle_batter"] = 99,
}
-- TODO holy crap, why has nobody thought to put snow cone syrup on the waffles
-- or fermenting the syrup for that matter
--local waffle_refills = {
--	["waffle:bucket_syrup_grape"] = 99,
--	["waffle:bucket_syrup_banana"] = 99,
--	["waffle:bucket_syrup_orange"] = 99,
--	["waffle:bucket_syrup_blueberry"] = 99,
--	["waffle:bucket_syrup_pineapple"] = 99,
--	["waffle:bucket_syrup_raspberry"] = 99,
--	["waffle:bucket_syrup_strawberry"] = 99,
--	["waffle:bucket_syrup_watermelon"] = 99,
--}

function wafflehaus_nodes.get_wafflemaker(item_name)
	-- check more priority definitions
	for key, value in pairs(wafflehaus_nodes.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function wafflehaus_nodes.is_wafflemaker(item_name)
	local data = wafflehaus_nodes.get_wafflemaker(item_name);
	if (not data) then
		return false;
	end
	return true;
end

local function find_wafflemaker_node(self)
	return function(pos)
		if minetest.is_protected(pos, self:get_player_name()) then return false end
		if working_villages.failed_pos_test(pos) then return false end

		local node = minetest.get_node(pos);
		local data = wafflehaus_nodes.get_wafflemaker(node.name);
		if (not data) then
			return false;
		end
		return true
	end
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(_,stack)
	if waffle_demands[stack:get_name()] then
		return false
	end
	--if waffle_refills[stack:get_name()] then
	--	return false
	--end
	return true;
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if waffle_demands[item_name] then
	--or waffle_refills[item_name] then
		local inv = villager:get_inventory()
		local itemstack = ItemStack(item_name)
		local count     = waffle_demands[item_name]
		--if count == nil then
		--	count   = waffle_refills[item_name]
		--	assert(count ~= nil)
		--end
		itemstack:set_count(count)
		if (not inv:contains_item("main", itemstack)) then
			return true
		end
	end
	return false
end

working_villages.register_job("working_villages:job_waffle", {
	description			= "waffle (working_villages)",
	long_description = "I look for waffle machines and start making mudkips and bekfast.",
	inventory_image	= "default_paper.png^working_villages_farmer.png",
	trivia = {
		"I'm part of the break basket infrastructure.",
	},
	workflow = {
		"Wake up",
		"Handle my chest",
		"Equip my tool",
		"Go to work",
		"Search for waffle makers",
		"Go to waffle maker",
		"Use waffle batter on waffle maker",
		"Wait until waffle maker opens",
		"Dig waffle from waffle maker",
		"Periodically look away thoughtfully",
	},
	jobfunc = function(self)
		self:handle_night()
		local stack  = self:get_wield_item_stack()
		if stack:is_empty() then
			self:handle_chest(take_func, put_func)
		end
		if stack:is_empty() then
			self:move_main_to_wield(function(name)
  				--return waffle_refills[name] ~= nil
  				return waffle_demands[name] ~= nil
			end)
		end
		self:handle_job_pos()

		self:count_timer("waffle:search")
		self:count_timer("waffle:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("waffle:search",20) then
			self:collect_nearest_item_by_condition(wafflehaus_nodes.is_wafflemaker, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_wafflemaker_node(self), searching_range)
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
				self:set_displayed_action("making some waffles")
				local success, ret = self:go_to(destination)
				if not success then
					assert(target ~= nil)
					working_villages.failed_pos_record(target)
					self:set_displayed_action("looking at the unreachable waffle machine")
					self:delay(100)
				else

					if plant_name == "waffles:waffle_maker" then
						-- use the batter on the wafflemaker (right-click)
						local plant_data = wafflehaus_nodes.get_wafflemaker(plant_name)
						local flag, new_stack = working_villages.use_item(self, stack)
						if flag then self:set_wield_item_stack(new_stack) end
		
						-- use the wafflemaker (right-click)
						stack = nil
						local flag, new_stack = working_villages.use_item(self, stack)
					else -- wait till it opens
						assert(plant_name == "waffles:waffle_maker_open")

						-- dig the waffle from the wafflemaker (left-click)
						success, ret = self:dig(target,true)
						if not success then
							assert(target ~= nil)
							working_villages.failed_pos_record(target)
							self:set_displayed_action("confused as to why retrieval failed at (x="..target.x..', y='..target.y..', z='..target.z..')')
							self:delay(100)
						end
					end
				end
			end
		elseif self:timer_exceeded("waffle:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.wafflehaus_nodes = wafflehaus_nodes
