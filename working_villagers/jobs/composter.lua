
local func = working_villages.require("jobs/util")
local log = working_villages.require("log")

-- limited support to two replant definitions
local composter_nodes = {
	names = {
		["composting:composter"]=1,
		["composting:composter_filled"]=1,
	},
}

--local composting_demands = {
--}
local composting_tools = {
	["default:shovel_wood"] = 99,
	["default:shovel_stone"] = 99,
	["default:shovel_steel"] = 99,
	["default:shovel_mese"] = 99,
	["default:shovel_bronze"] = 99,
	["default:shovel_diamond"] = 99,
}

function composter_nodes.get_composter(item_name)
	-- check more priority definitions
	for key, value in pairs(composter_nodes.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function composter_nodes.is_composter(item_name)
	local data = composter_nodes.get_composter(item_name);
	if (not data) then
		return false;
	end
	return true;
end

local function find_composter_node(pos)
	local node = minetest.get_node(pos);
	local data = composter_nodes.get_composter(node.name);
	if (not data) then
		return false;
	end
	return true
end

local searching_range = {x = 10, y = 3, z = 10}

function is_compostable(item_name)
	local stack = ItemStack(item_name)
	local item_def = stack:get_definition() -- minetest.registered_items[item_name]
      	return item_def and item_def._compost
end

local function put_func(_,stack)
	local item_name = stack:get_name()
	if composting_tools[item_name] then
		return false
	end
	return not is_compostable(item_name)
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	local count     = composting_tools[item_name]
	if count == nil
	and is_compostable(item_name) then count = 99 end
	if count then
		local inv = villager:get_inventory()
		local itemstack = ItemStack(item_name)
		itemstack:set_count(count)
		if (not inv:contains_item("main", itemstack)) then
			return true
		end
	end
	return false
end

working_villages.register_job("working_villages:job_composter", {
	description			= "composter (working_villages)",
	long_description = "I look for composters and start making soil for the farmer",
	inventory_image	= "default_paper.png^working_villages_farmer.png",
	jobfunc = function(self)
		self:handle_night()
		--if stack:is_empty() then
		self:handle_chest(take_func, put_func)
		--end
		--if stack:is_empty() then
		--	self:move_main_to_wield(function(name)
  		--		return composting_tools[name] ~= nil
		--	end)
		--end
		-- if stack wear is too much, then cycle tools
		-- I'm still working on the blacksmith to repair tools
		-- should work great with toolranks
		self:handle_job_pos()

		self:count_timer("composter:search")
		self:count_timer("composter:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("composter:search",20) then
			self:collect_nearest_item_by_condition(composter_nodes.is_composter, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_composter_node, searching_range)
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
				local node          = minetest.get_node(target)
				assert(node ~= nil)
				local plant_data    = composter_nodes.get_composter(node.name)
				assert(plant_data ~= nil)
				local pointed_thing = {under=target, type="node",}
				local puncher       = self
				-- if filled, then punch with shovel
				-- else punch with compostable
				--


				if --node.name == "composting:composter" and
				self:move_main_to_wield(is_compostable) then
    					local wield_item = self:get_wielded_item();
    					assert(wield_item ~= nil)
    					local item_name = wield_item:get_name();
    					assert(item_name ~= nil)
					log.action("composting %s",item_name)
					self:set_displayed_action("composting "..item_name)
					--if true then
					minetest.registered_nodes[node.name].on_punch(target, node, puncher, pointed_thing)
					--minetest.node_punch(target, node, puncher, pointed_thing)
    					if wield_item:get_count() == self:get_wielded_item():get_count() then
	    					-- TODO separate failed_pos registries: the shovel might work
						working_villages.failed_pos_record(target)
						log.error("something wrong composting %s",item_name)
						self:set_displayed_action("something wrong composting "..item_name)
    					end
					--[[
					else -- TODO #50
    						local def = wield_item:get_definition() -- minetest.registered_items[item_name]
    						local on_use = def.on_use
    						local new_stack = on_use(wield_item, self, pointed_thing)
    						self:set_wield_item_stack(new_stack)
					end
					--]]
					for _=0,10 do coroutine.yield() end --wait 10 steps
				end

				if --node.name == "composting:composter_filled" and
				self:move_main_to_wield(function(name)
  					return composting_tools[name] ~= nil
				end) then
    					local wield_item = self:get_wielded_item();
    					assert(wield_item ~= nil)
    					local item_name = wield_item:get_name();
    					assert(item_name ~= nil)
					log.action("using %s",item_name)
					self:set_displayed_action("using "..item_name)
					--if true then
					minetest.registered_nodes[node.name].on_punch(target, node, puncher, pointed_thing)
					--minetest.node_punch(target, node, puncher, pointed_thing)
    					if wield_item:get_count() == self:get_wielded_item():get_count() then
	    					-- TODO separate failed_pos registries: adding more leaves might work
						working_villages.failed_pos_record(target)
						log.error("something wrong composting %s",item_name)
						self:set_displayed_action("something wrong composting "..item_name)
    					end
					--[[
					else -- TODO #50
    					local def = wield_item:get_definition() -- minetest.registered_items[item_name]
    					local on_use = def.on_use
    					local new_stack = on_use(wield_item, self, pointed_thing)
    					self:set_wield_item_stack(new_stack)
					end
					--]]
					for _=0,10 do coroutine.yield() end --wait 10 steps
				end
			end
		elseif self:timer_exceeded("composter:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.composter_nodes = composter_nodes
