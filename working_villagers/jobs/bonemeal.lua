-- TODO he uses the tool till it breaks... it would be better if he takes it back to his chest

local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")
local trivia = working_villages.require("jobs/trivia")

-- limited support to two replant definitions
local fertilizing_nodes = {
	names = {
		["default:dirt"]={replant={"farming:soil"}},
		["default:dirt_with_grass"]={replant={"farming:soil"}},
		["default:dirt_with_rainforest_litter"]={replant={"farming:soil"}},

		["default:dry_dirt"]={replant={"farming:soil"}},
		--["default:dirt_with_snow"]={replant={"farming:soil"}},
		["default:dirt_with_dry_grass"]={replant={"farming:soil"}},
		["default:dry_dirt_with_dry_grass"]={replant={"farming:soil"}},
		["default:dirt_with_coniferous_litter"]={replant={"farming:soil"}},

		["default:sand"]={},
		["default:desert_sand"]={},
		["default:silver_sand"]={},
	},
}

--local fertilizing_tools = {
--	-- maybe we need bonemeal or something
--	["farming:hoe_wood"] = 99,
--	["farming:hoe_stone"] = 99,
--	["farming:hoe_steel"] = 99,
--}
local fertilizing_demands = {
	["bonemeal:bonemeal"] = 99,
	["bonemeal:fertiliser"] = 99,
	["bonemeal:mulch"] = 99,
	["basalt_fertilizer:fertilizer"] = 99,
}

function fertilizing_nodes.get_dirt(item_name)
	-- check more priority definitions
	for key, value in pairs(fertilizing_nodes.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function fertilizing_nodes.is_dirt(item_name)
	local data = fertilizing_nodes.get_dirt(item_name);
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
		local data = fertilizing_nodes.get_dirt(node.name);
		if (not data) then
			return false;
		end
		--local water_rad   = 3
		--local water_names = {
		--	"default:water_source",
		--	"default:river_water_source",
		--}
		--local water_pos = minetest.find_node_near(pos, water_rad, water_names)
		--return water_pos ~= nil
		return true
	end
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(_,stack)
	if fertilizing_demands[stack:get_name()] then
		return false
	end
	--if fertilizing_tools[stack:get_name()] then
	--	return false
	--end
	return true;
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	-- TODO dedup
	if fertilizing_demands[item_name] then
		local inv = villager:get_inventory()
		local itemstack = ItemStack(item_name)
		itemstack:set_count(fertilizing_demands[item_name])
		if (not inv:contains_item("main", itemstack)) then
			return true
		end
	end
	--if fertilizing_tools[item_name] then
	--	local inv = villager:get_inventory()
	--	local itemstack = ItemStack(item_name)
	--	itemstack:set_count(fertilizing_tools[item_name])
	--	if (not inv:contains_item("main", itemstack)) then
	--		return true
	--	end
	--end
	return false
end

working_villages.register_job("working_villages:job_fertilizer", {
	description = S("fertilizer (working_villages)"),
	long_description = S("I look for dirt nodes and hoe them for the farmer."),
  	trivia = trivia.get_trivia({}, {trivia.waste_management, trivia.bread_basket, trivia.griefers, trivia.construction, }),
	workflow = {
		S("Wake up"),
		S("Handle my chest"),
		S("Equip my tool"),
		S("Go to work"),
		S("Search for dirt near water"),
		S("Go to dirt near water"),
		S("Use tool on dirt near water"),
		S("Periodically look away thoughtfully"),
	},
	inventory_image	= "default_paper.png^working_villages_farmer.png",
	jobfunc = function(self)
		self:handle_night()
		local stack  = self:get_wield_item_stack()
		--if stack:is_empty() then
			self:handle_chest(take_func, put_func)
		--end
		if stack:is_empty() then
			self:move_main_to_wield(function(name)
  				--return fertilizing_tools[name] ~= nil
  				return fertilizing_demands[name] ~= nil
			end)
		end
		-- TODO
		-- if stack wear is too much, then cycle tools
		-- I'm still working on the blacksmith to repair tools
		-- should work great with toolranks
		self:handle_job_pos()

		self:count_timer("fertilizer:search")
		self:count_timer("fertilizer:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("fertilizer:search",20) then
			self:collect_nearest_item_by_condition(fertilizing_nodes.is_dirt, searching_range)
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
					local plant_data = fertilizing_nodes.get_dirt(plant_name)
					local flag, new_stack = working_villages.use_item(self, stack, target)
					if flag then self:set_wield_item_stack(new_stack) end
					-- TODO don't keep re-fertilizing the same node
					working_villages.failed_pos_record(target)
				end
			end
		elseif self:timer_exceeded("fertilizer:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.fertilizing_nodes = fertilizing_nodes
