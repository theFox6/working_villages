-- PoC for on_punch + on_rightclick

local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")
local log = working_villages.require("log")
local trivia = working_villages.require("jobs/trivia")

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
	description = S("waffle (working_villages)"),
	long_description = S("I look for waffle machines and start making mudkips and bekfast."),
	trivia = trivia.get_trivia({
		"My job is the first to punch-operate appliance nodes",
		"Derivatives of my job core will press your buttons!",
	}, {trivia.bread_basket, trivia.punchy, trivia.meta,})
	workflow = {
		S("Wake up"),
		S("Handle my chest"),
		S("Equip my tool"),
		S("Go to work"),
		S("Search for waffle makers"),
		S("Go to waffle maker"),
		S("Wait if there are waffles cooking"),
		S("Open the wafflemaker"),
		S("Punch any waffles from the wafflemaker"),
		S("Use batter in the wafflemaker"),
		S("Close the wafflemaker"),
		S("Wait until waffle maker opens"),
		S("Periodically look away thoughtfully"),
	},
	inventory_image	= "default_paper.png^working_villages_farmer.png",
	jobfunc = function(self)
		self:handle_night()
		local stack  = self:get_wield_item_stack()
		--if stack:is_empty() then
			self:handle_chest(take_func, put_func)
		--end
		--if stack:is_empty() then
		--	self:move_main_to_wield(function(name)
  		--		--return waffle_refills[name] ~= nil
  		--		return waffle_demands[name] ~= nil
		--	end)
		--end
		self:handle_job_pos()

		if not self.job_data.waiting_for_waffles then
			self.job_data.waiting_for_waffles = 1
		end

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

					if self.job_data.waiting_for_waffles == 1 then
						if plant_name == "waffles:waffle_maker" then
							local meta   = minetest.get_meta(target)
							local cooked = meta:get_float("cooked")
							if cooked ~= nil and cooked > -1 and cooked <= 0.2 then
								-- not ready
								coroutine.yield()
							else

								self:set_displayed_action("opening waffle maker")
								log.action("opening waffle maker")
								self:move_main_to_wield(function(name)
  									return waffle_demands[name] ~= nil
								end)
								local stack  = self:get_wield_item_stack()
	
								-- right-click to open
								--local flag, new_stack = working_villages.use_item(self, stack, target)
								local new_stack, flag = working_villages.place_item(self, stack, target)
								--local flag, new_stack = working_villages.punch_node(self, stack, target)
								if flag then
									-- TODO this is doubling items
									--self:set_wield_item_stack(new_stack)
									--self:add_item_to_main(new_stack)
									self:set_displayed_action("opened waffle maker, new stack:"..new_stack:get_name().." "..new_stack:get_count())
									log.action("opened waffle maker, new stack: "..new_stack:get_name().." "..new_stack:get_count())
								else
									self:set_displayed_action("problem opening waffle maker, old stack:"..stack:get_name())
									log.action("problem opening waffle maker, old stack: "..stack:get_name())
								end
							end
						end

						self.job_data.waiting_for_waffles = 2
					--end
					elseif self.job_data.waiting_for_waffles == 2 then
						if plant_name == "waffles:waffle_maker_open" then

							local meta   = minetest.get_meta(target)
							local cooked = meta:get_float("cooked")
							if cooked ~= nil and cooked > -1 and cooked <= 0.2 then
								-- not ready
								coroutine.yield()
							else

								self:set_displayed_action("emptying waffle maker")
								log.action("emptying waffle maker")

								self:move_main_to_wield(function(name)
  									return waffle_demands[name] ~= nil
								end)
								local stack  = self:get_wield_item_stack()

								-- left-click to take waffle
								local flag, new_stack = working_villages.punch_node(self, stack, target)
								if flag then
									if new_stack ~= nil then
										self:set_displayed_action("emptied waffle maker, new stack: "..new_stack:get_name().." "..new_stack:get_count())
										log.action("emptied waffle maker, new stack: "..new_stack:get_name().." "..new_stack:get_count())
									else
										self:set_displayed_action("emptied waffle maker, but new stack is nil")
										log.action("emptied waffle maker, but new stack is nil")
									end
									--self:set_wield_item_stack(new_stack)
									self:add_item_to_main(new_stack)
								else
									self:set_displayed_action("problem emptying waffle maker, old stack: "..stack:get_name())
									log.action("problem emptying waffle maker, old stack: "..stack:get_name())
								end
							end
						end

						self.job_data.waiting_for_waffles = 3
					--end
					elseif self.job_data.waiting_for_waffles == 3 then
						if plant_name == "waffles:waffle_maker_open" then

							self:set_displayed_action("placing waffle batter")
							log.action("placing waffle batter")

							self:move_main_to_wield(function(name)
  								return waffle_demands[name] ~= nil
							end)
							local stack  = self:get_wield_item_stack()
							if stack:get_name() == "waffles:waffle_batter" then

								-- right-click to place waffle batter
								--local flag, new_stack = working_villages.use_item(self, stack, target)
								local new_stack, flag = working_villages.place_item(self, stack, target)
								if flag then
									self:set_wield_item_stack(new_stack)
									self:set_displayed_action("placed waffle batter, new stack: "..new_stack:get_name().." "..new_stack:get_count())
									log.action("placed waffle batter, new stack: "..new_stack:get_name().." "..new_stack:get_count())
								else
									self:set_displayed_action("problem placing waffle batter, old stack: "..stack:get_name())
									log.action("problem placing waffle batter, old stack: "..stack:get_name())
								end
							end
						end
						
						self.job_data.waiting_for_waffles = 4
					--end
					elseif self.job_data.waiting_for_waffles == 4 then
						if plant_name == "waffles:waffle_maker_open" then

							self:set_displayed_action("closing waffle maker")
							log.action("closing waffle maker")

							-- TODO remove wield stack real quick
							self:move_main_to_wield(function(name)
  								return waffle_demands[name] == nil
							end)
							local stack  = self:get_wield_item_stack()
							if stack:get_name() ~= "waffles:waffle_batter" then

								-- right-click to close waffle maker
								--local flag, new_stack = working_villages.use_item(self, stack, target)
								local new_stack, flag = working_villages.place_item(self, stack, target)
								if flag then
									-- TODO this may also be double items
									--self:set_wield_item_stack(new_stack)
									--self:add_item_to_main(new_stack)
									self:set_displayed_action("closed waffle maker, new stack: "..new_stack:get_name().." "..new_stack:get_count())
									log.action("closed waffle maker, new stack: "..new_stack:get_name().." "..new_stack:get_count())
								else
									self:set_displayed_action("problem closing waffle maker, old stack: "..stack:get_name())
									log.action("problem closing waffle maker, old stack: "..stack:get_name())
								end
							end
						end

						-- TODO check result first
						self.job_data.waiting_for_waffles = 5
					--end
					elseif self.job_data.waiting_for_waffles == 5 then

						if plant_name == "waffles:waffle_maker" then
							-- noop
							self:set_displayed_action("waiting till waffle maker opens")
							log.action("waiting till waffle maker opens")

							local meta   = minetest.get_meta(target)
							local cooked = meta:get_float("cooked")
							if cooked ~= nil and cooked > -1 and cooked <= 0.2 then
								-- not ready
								coroutine.yield()
							else
							--self:count_timer("waffle:reset_timer")
							--if self:timer_exceeded("waffle:reset_timer",10) then
								self.job_data.waiting_for_waffles = nil
							end
						elseif plant_name == "waffles:waffle_maker_open" then
							self:set_displayed_action("waffle maker is open, resetting...")
							log.action("waffle maker is open, resetting...")
							self.job_data.waiting_for_waffles = nil
						end
					else
						self:set_displayed_action("unexpected waffle state")
						log.action("unexpected waffle state")
						self.job_data.waiting_for_waffles = nil
					end




				end
			end
		elseif self:timer_exceeded("waffle:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.wafflehaus_nodes = wafflehaus_nodes
