-- TODO he uses the tool till it breaks... it would be better if he takes it back to his chest




local func = working_villages.require("jobs/util")

-- limited support to two replant definitions
local gardening_nodes = {
	names = {
		["default:dirt"]={replant={"farming:soil"}},
		["default:dirt_with_grass"]={replant={"farming:soil"}},
		["default:dirt_with_rainforest_litter"]={replant={"farming:soil"}},
	},
}

local gardening_demands = {
	-- maybe we need bonemeal or something
	["farming:hoe_wood"] = 99,
	["farming:hoe_stone"] = 99,
	["farming:hoe_steel"] = 99,
}
local gardening_tools = gardening_demands
--{
--	["farming:hoe_wood"] = 99,
--	["farming:hoe_stone"] = 99,
--	["farming:hoe_steel"] = 99,
--}

function gardening_nodes.get_dirt(item_name)
	-- check more priority definitions
	for key, value in pairs(gardening_nodes.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function gardening_nodes.is_dirt(item_name)
	local data = gardening_nodes.get_dirt(item_name);
	if (not data) then
		return false;
	end
	return true;
end

local function find_dirt_node(self)
	return function(pos)
		if minetest.is_protected(pos, self:get_player_name()) then return false end
		if working_villages.failed_pos_test(pos) then return false end

		local node = minetest.get_node(pos);
		local data = gardening_nodes.get_dirt(node.name);
		if (not data) then
			return false;
		end
		local water_rad   = 3
		local water_names = {
			"default:water_source",
			"default:river_water_source",
		}
		local water_pos = minetest.find_node_near(pos, water_rad, water_names)
		return water_pos ~= nil
	end
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(_,stack)
	if gardening_demands[stack:get_name()] then
		return false
	end
	return true;
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if gardening_demands[item_name] then
		local inv = villager:get_inventory()
		local itemstack = ItemStack(item_name)
		itemstack:set_count(gardening_demands[item_name])
		if (not inv:contains_item("main", itemstack)) then
			return true
		end
	end
	return false
end

working_villages.register_job("working_villages:job_gardener", {
	description			= "gardener (working_villages)",
	long_description = "I look for dirt nodes and hoe them for the farmer.",
	inventory_image	= "default_paper.png^working_villages_farmer.png",
	jobfunc = function(self)
		self:handle_night()
		local stack  = self:get_wield_item_stack()
		if stack:is_empty() then
			self:handle_chest(take_func, put_func)
		end
		if stack:is_empty() then
			self:move_main_to_wield(function(name)
  				return gardening_tools[name] ~= nil
			end)
		end
		-- TODO
		-- if stack wear is too much, then cycle tools
		-- I'm still working on the blacksmith to repair tools
		-- should work great with toolranks
		self:handle_job_pos()

		self:count_timer("gardener:search")
		self:count_timer("gardener:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("gardener:search",20) then
			self:collect_nearest_item_by_condition(gardening_nodes.is_dirt, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_dirt_node(self), searching_range)
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
				self:set_displayed_action("tilling some "..plant_name)
				local success, ret = self:go_to(destination)
				if not success then
					assert(target ~= nil)
					working_villages.failed_pos_record(target)
					self:set_displayed_action("looking at the unreachable dirt")
					self:delay(100)
				else
					local plant_data = gardening_nodes.get_dirt(plant_name)
					--self:dig(target,true)
					--if plant_data and plant_data.replant then
					--	for index, value in ipairs(plant_data.replant) do
					--		self:place(value, vector.add(target, vector.new(0,index-1,0)))
					--	end
					--end
					local name   = stack:get_name()
					if name == nil then return end
					local def    = minetest.registered_items[name]
					if def == nil then return end
					local on_use = def.on_use
					if on_use == nil then return end
					local user   = self
					local pointed_thing = {under=target, type="node",}
					local new_stack = on_use(stack, user, pointed_thing)
					-- TODO register position failure ?
					self:set_wield_item_stack(new_stack)
					for _=0,10 do coroutine.yield() end --wait 10 steps
				end
			end
		elseif self:timer_exceeded("gardener:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.gardening_nodes = gardening_nodes
