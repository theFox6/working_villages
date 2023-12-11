
local func = working_villages.require("jobs/util")

local furnaces = {
	names = {
		["default:furnace"]={},
		["default:furnace_active"]={},
	},
}

local bakables = {
	fuel_names = {
		["default:coalblock"] = 99,
		["default:coal_lump"] = 99,
		["bucket:bucket_lava"] = 99,
		["default:lava_source"] = 99,
		-- burn all your stuff
		--["default:jungletree"] = 99,
		--["default:acacia_tree"] = 99,
		--["default:tree"] = 99,
		--["default:pine_tree"] = 99,
		--["default:aspen_tree"] = 99,
		--["default:cactus"] = 99,
		--["default:acacia_bush_stem"] = 99,
		--["default:bush_stem"] = 99,
		--["default:pine_bush_stem"] = 99,
		--["farming:straw"] = 99,
		--["default:dry_shrub"] = 99,
		--["default:dry_grass"] = 99,
		--["default:marram_grass"] = 99,
		--["default:grass"] = 99,
		--["default:fern"] = 99,
	},
	fuel_groups = {
		["fuel"]=99,
		--["tree"]=99,
		--["wood"]=99,
		--["leaves"]=99,
	},
  -- more priority definitions
	names = {
		-- TODO farming mod support => separate jobs for baker and smelter
		["farming:flour"] = 99,
		["default:cobble"] = 99,
		["default:mossycobble"] = 99,
		["default:desert_cobble"] = 99,
		["default:clay_lump"] = 99,
		["default:iron_lump"] = 99,
		["default:copper_lump"] = 99,
		["default:tin_lump"] = 99,
		["default:gold_lump"] = 99,
		["vessels:glass_fragments"] = 99,
		["default:obsidian_shard"] = 99,
	},
  -- less priority definitions
	groups = {
		["ore"]=99,
		["sand"]=99,
	},
}
function bakables.get_bakable(item_name)
	for key, value in pairs(bakables.fuel_names) do
		if item_name==key then
			return value
		end
	end
  -- check more priority definitions
	for key, value in pairs(bakables.names) do
		if item_name==key then
			return value
		end
	end
	for key, value in pairs(bakables.fuel_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
  -- check less priority definitions
	for key, value in pairs(bakables.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function bakables.is_bakable(item_name)
  local data = bakables.get_bakable(item_name);
  return data ~= nil
end
function bakables.get_cookable(item_name)
  -- check more priority definitions
	for key, value in pairs(bakables.names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(bakables.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function bakables.is_cookable(item_name)
  local data = bakables.get_cookable(item_name);
  return data ~= nil
end
function bakables.get_fuel(item_name)
  -- check more priority definitions
	for key, value in pairs(bakables.fuel_names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(bakables.fuel_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function bakables.is_fuel(item_name)
  local data = bakables.get_fuel(item_name);
  return data ~= nil
end






function furnaces.get_furnace(item_name)
	-- check more priority definitions
	for key, value in pairs(furnaces.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function furnaces.is_furnace(item_name)
	local data = furnaces.get_furnace(item_name);
	return data ~= nil
end

local function find_furnace_node(pos)
	local node = minetest.get_node(pos);
	local data = furnaces.get_furnace(node.name);
	return data ~= nil
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(_,stack)
	return not bakables.is_bakable(stack:get_name())
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not bakables.is_bakable(item_name) then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(bakables.get_bakable(item_name))
	return (not inv:contains_item("main", itemstack))
end

local function put_fuel(_,stack)
	return bakables.is_fuel(stack:get_name())
end

local function put_cookable(_,stack)
	return bakables.is_cookable(stack:get_name())
end

working_villages.register_job("working_villages:job_baker", {
	description			= "baker (working_villages)",
	long_description = "I look for a furnace and start putting the contents of your chest into it.",
	trivia          = {
		"My job position was the first to use appliances.",
	},
	workflow        = {
		"Wake up",
		"Handle my chest",
		"Go to work",
		"Search for furnaces",
		"Go to furnace",
		"Handle furnace",
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

		self:count_timer("baker:search")
		self:count_timer("baker:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("baker:search",20) then
			self:collect_nearest_item_by_condition(furnaces.is_furnace, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_furnace_node, searching_range)
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
					self:set_displayed_action("looking at the unreachable furnace")
					self:delay(100)
				else
					local target_def = minetest.get_node(target)
					local plant_data = furnaces.get_furnace(target_def.name);
					if plant_data then
						self:set_displayed_action("operating the furnace")
						self:handle_furnace(
					        	target,
						    	func.take_everything, -- take everything
						 	put_cookable, -- put what we need to furnace
							put_fuel
						)
						--self.job_data.manipulated_chest   = false;
						--self.job_data.manipulated_furnace = false;
						--self:set_displayed_action("waiting on furnace")
					end
				end
			end
		elseif self:timer_exceeded("baker:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.bakables = bakables
