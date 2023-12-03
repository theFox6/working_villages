
local func = working_villages.require("jobs/util")

-- limited support to two replant definitions
local liquids = {
	names = {
		["default:water_source"]      ="bucket:bucket_water",
		["default:river_water_source"]="bucket:bucket_river_water",
		["default:lava_source"]       ="bucket:bucket_lava",
	},
}

local bucketing_demands = {
	["bucket:bucket_empty"] = 99,
}

function liquids.get_liquid(item_name)
	-- check more priority definitions
	for key, value in pairs(liquids.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function liquids.is_liquid(item_name)
	local data = liquids.get_liquid(item_name);
	if (not data) then
		return false;
	end
	return true;
end

local function find_liquid_nodes(pos)
		if minetest.is_protected(p, "") then return false end
		if working_villages.failed_pos_test(p) then return false end

	local node = minetest.get_node(pos);
	local data = liquids.get_liquid(node.name);
	if (not data) then
		return false;
	end
	return true;
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(_,stack)
	return bucketing_demands[stack:get_name()] == nil
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not bucketing_demands[item_name] then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(bucketing_demands[item_name])
	--return (not inv:contains_item("wield_item", itemstack))
	return (not inv:contains_item("main", itemstack))
end

working_villages.register_job("working_villages:job_watercarrier", {
	description			= "water carrier (working_villages)",
	long_description = "I look for all sorts of liquids and collect them.",
	inventory_image  = "default_paper.png^working_villages_builder.png",
	jobfunc = function(self)
		self:handle_night()
		--self:handle_chest2(take_func, put_func)
		self:handle_chest(take_func, put_func)
		local stack  = self:get_wield_item_stack()
		if stack:is_empty() then
		self:move_main_to_wield(function(name)
  			return bucketing_demands[name] ~= nil
		end)
		end
		self:handle_job_pos()

		self:count_timer("watercarrier:search")
		self:count_timer("watercarrier:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("watercarrier:search",20) then
			self:collect_nearest_item_by_condition(liquids.is_liquid, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_liquid_nodes, searching_range)
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
					self:set_displayed_action("looking at the unreachable snow")
					self:delay(100)
				else
					local plant_data = liquids.get_liquid(minetest.get_node(target).name);

					-- TODO wield the bucket instead
					-- first we need an empty bucket
					self:set_displayed_action("checking for empty bucket")
					local item_name = "bucket:bucket_empty"
					local inv = self:get_inventory()
					local itemstack = ItemStack(item_name)
					itemstack:set_count(1)
					--if (not inv:contains_item("wield_item", itemstack)) then
					if (not inv:contains_item("main", itemstack)) then
						-- need a bucket
						self.job_data.manipulated_chest2 = false
						return
					end

					-- next we need the filled bucket
					self:set_displayed_action("checking for room for filled bucket")
					local plantstack = ItemStack(plant_data)
					plantstack:set_count(1)
					if not inv:room_for_item("main", plantstack) then
						-- no room for new bucket
						self.job_data.manipulated_chest2 = false
						return
					end

					self:set_displayed_action("bucketing some liquid")
					-- now we can do the action
					--self:dig(target,true) -- bucketing is different than digging
					minetest.remove_node(target)

					--local taken = inv:remove_item("wield_item", itemstack)
					local taken = inv:remove_item("main", itemstack)
					assert(taken:get_count() == 1)

					local leftover = inv:add_item("main", plantstack)
					assert(leftover:get_count() == 0)

					for _=0,10 do coroutine.yield() end --wait 10 steps
				end
			end
		elseif self:timer_exceeded("watercarrier:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.liquids = liquids

-- move to wield item
--local log = working_villages.require("log")
--function working_villages.villager:manipulate_chest2(chest_pos, take_func, put_func, data)
--	if func.is_chest(chest_pos) then
--		-- try to put items
--		local vil_inv = self:get_inventory();
--
--		-- from villager to chest
--		if put_func then
--			local size = vil_inv:get_size("main");
--			for index = 1,size do
--				local stack = vil_inv:get_stack("main", index);
--				if (not stack:is_empty()) and (put_func(self, stack, data)) then
--					local chest_meta = minetest.get_meta(chest_pos);
--					local chest_inv = chest_meta:get_inventory();
--					local leftover = chest_inv:add_item("main", stack);
--					vil_inv:set_stack("main", index, leftover);
--					for _=0,10 do coroutine.yield() end --wait 10 steps
--				end
--			end
--		end
--		-- from chest to villager
--		if take_func then
--			local chest_meta = minetest.get_meta(chest_pos);
--			local chest_inv = chest_meta:get_inventory();
--			local size = chest_inv:get_size("main");
--			for index = 1,size do
--				chest_meta = minetest.get_meta(chest_pos);
--				chest_inv = chest_meta:get_inventory();
--				local stack = chest_inv:get_stack("main", index);
--				if (not stack:is_empty()) and (take_func(self, stack, data)) then
--					local leftover = vil_inv:add_item("wield_item", stack);
--					chest_inv:set_stack("main", index, leftover);
--					for _=0,10 do coroutine.yield() end --wait 10 steps
--				end
--			end
--		end
--	else
--		log.error("Villager %s doe's not find cheston position %s.", self.inventory_name, minetest.pos_to_string(chest_pos))
--	end
--end
--
--function working_villages.villager:handle_chest2(take_func, put_func, data)
--	if (not self.job_data.manipulated_chest2) then
--		local chest_pos = self.pos_data.chest_pos
--		if (chest_pos~=nil) then
--			log.action("villager %s is handling chest at %s", self.inventory_name, minetest.pos_to_string(chest_pos))
--			self:set_state_info("I am taking and puting items from/to my chest.")
--			self:set_displayed_action("active")
--			local chest = minetest.get_node(chest_pos);
--			local dir = minetest.facedir_to_dir(chest.param2);
--			local destination = vector.subtract(chest_pos, dir);
--			self:go_to(destination)
--			self:manipulate_chest2(chest_pos, take_func, put_func, data);
--		end
--		self.job_data.manipulated_chest2 = true;
--	end
--end

