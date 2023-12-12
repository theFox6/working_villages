-- PoC for on_rightclick

local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")
local log = working_villages.require("log")

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
	long_description = "I look for snowcone machines and start putting syrup on some shaved ice.",
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
		--if stack:is_empty() then
			self:handle_chest(take_func, put_func)
		--end
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




				self:set_displayed_action("making some snowcones")
				local success, ret = self:go_to(destination)
				if not success then
					assert(target ~= nil)
					working_villages.failed_pos_record(target)
					self:set_displayed_action("looking at the unreachable snowcone machine")
					self:delay(100)
				else
					local meta = minetest.get_meta(target)
					local flavor = meta:get_string("flavor")
					local level = meta:get_int("level")

					if level + 16 <= 64 then
						--if level == 0 then -- refill the machine
						self:set_displayed_action("refilling snowcone machine")
						log.action("refilling snowcone machine")
						self:move_main_to_wield(function(name)
							if flavor ~= nil then -- use same flavor that's already in the machine
								return name:match("^snowcone:bucket_syrup_"..flavor)
							end
							-- use any flavor
  							return snowcone_refills[name] ~= nil
						end)
						
						local stack  = self:get_wield_item_stack()
						local name   = stack:get_name()
						if name:match("^snowcone:bucket_syrup_") then
							--local flag, new_stack = working_villages.use_item(self, stack, target)
							local new_stack, flag = working_villages.place_item(self, stack, target)
							--local flag, new_stack = working_villages.punch_node(self, stack, target)
							if flag then
								stack:clear() -- testing, take(1)
								self:set_wield_item_stack(new_stack)
								self:set_displayed_action("refilled snowcone machine, new stack: "..new_stack:get_name())
								log.action("refilled snowcone machine, new stack: "..new_stack:get_name())
							else
								self:set_displayed_action("problem refilling snowcone machine, old stack: "..stack:get_name())
								log.action("problem refilling snowcone machine, old stack: "..stack:get_name())
							end
						end
					end
						

					--else -- make snowcones
					self:set_displayed_action("making snowcone")
					log.action("making snowcone")
					
					self:move_main_to_wield(function(name)
						return snowcone_demands[name] ~= nil
					end)

					local stack = self:get_wield_item_stack()
					if level > 0 and stack:get_name() == "snowcone:raw" then
						--local flag, new_stack = working_villages.use_item(self, stack, target)
						local new_stack, flag = working_villages.place_item(self, stack, target)
						--local flag, new_stack = working_villages.punch_node(self, stack, target)
						if flag then
							-- place_item() when level is 0 ==> unknown item. name is empty string ?
							if new_stack ~= nil then
								if not new_stack:is_empty() then
									self:set_wield_item_stack(new_stack)
								else -- TODO ?
								end
								self:set_displayed_action("made snowcone, new stack: "..new_stack:get_name())
								log.action("made snowcone, new stack: "..new_stack:get_name())
							else
								self:set_displayed_action("made snowcone, but new stack is nil")
								log.action("made snowcone, but new stack is nil")
							end
						else
							self:set_displayed_action("problem making snowcone, old stack: "..stack:get_name())
							log.action("problem making snowcone, old stack: "..stack:get_name())
						end
					end
				end
			end
		elseif self:timer_exceeded("snowcone:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.fruteria_nodes = fruteria_nodes
