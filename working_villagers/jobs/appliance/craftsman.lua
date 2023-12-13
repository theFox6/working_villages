-- TODO sometimes the recipe stacks get messed up and he makes the wrong thing

--CRAFT_TABLE_TYPE = "craft_table"
CRAFT_TABLE_TYPE = "crafting_bench"


local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")
local log = working_villages.require("log")
local trivia = working_villages.require("jobs/trivia")

local craft_tables
if CRAFT_TABLE_TYPE == "craft_table" then
	craft_tables = {
		names = {
			["craft_table:simple"]={},
		},
	}
elseif CRAFT_TABLE_TYPE == "crafting_bench" then
	craft_tables = {
		names = {
			["crafting_bench:workbench"]={},
		},
	}
else assert(false)
end

local recipes = {
	[1] = {
		{"default:mese_crystal", "default:mese_crystal", "default:mese_crystal",},
		{"default:mese_crystal", "default:mese_crystal", "default:mese_crystal",},
		{"default:mese_crystal", "default:mese_crystal", "default:mese_crystal",},
	},
	[2] = {
		{"default:stone", "default:stone",},
		{"default:stone", "default:stone",},
	},
	[3] = {
		{"default:steel_ingot", "",                    "default:steel_ingot",},
		{"",                    "default:steel_ingot", "",},
		{"",                    "",                    "",},
	},
}

function craft_tables.recipe_requires(recipe, item_name, target_x, target_y)
	if type(recipe) ~= "table" then
		assert(type(recipe) == "string")
		if recipe == item_name then return 1 end
		return 0
	end

	if target_x ~= nil
	or target_y ~= nil then
		assert(target_x ~= nil)
		assert(target_y ~= nil)
		--print(dump(recipe))
		if recipe[target_y][target_x] == item_name then return 1 end
		return 0
	end
	assert(target_x == nil)
	assert(target_y == nil)

	local count = 0
	for _,dep in pairs(recipe) do
		count = count + craft_tables.recipe_requires(dep, item_name, nil, nil)
	end
	return count
end

-- called by take_func for all iterations
function craft_tables.get_craftingsupplies(self, item_name, iteration, target_x, target_y)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
	local recipe = recipes[iteration]
	assert(recipe ~= nil)
	local count = craft_tables.recipe_requires(recipe, item_name, target_x, target_y)
	if count == 0 then return nil end
	return count
end
-- called by put_func for all iterations
function craft_tables.is_craftingsupplies(self, item_name, iteration, target_x, target_y)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
	-- TODO 
  local data = craft_tables.get_craftingsupplies(self, item_name, iteration, target_x, target_y);
  return data ~= nil
end

function craft_tables.get_craft_table(item_name)
	assert(item_name ~= nil)
	for key, value in pairs(craft_tables.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function craft_tables.is_craft_table(item_name)
	assert(item_name ~= nil)
	local data = craft_tables.get_craft_table(item_name);
	return data ~= nil
end

local function find_craft_table_node(pos)
	assert(pos       ~= nil)
	local node = minetest.get_node(pos);
	local data = craft_tables.get_craft_table(node.name);
	return data ~= nil
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(villager,stack,data)
	assert(villager  ~= nil)
	assert(stack     ~= nil)

	local target_x
	if data == nil then target_x = nil else target_x = data.target_x end
	local target_y
	if data == nil then target_y = nil else target_y = data.target_y end

	if data ~= nil and data.iteration ~= nil then
		return not craft_tables.is_craftingsupplies(villager,stack:get_name(), data.iteration, target_x, target_y)
	end

	local ntarget = #recipes
	for iteration=1,ntarget,1 do
		if craft_tables.is_craftingsupplies(villager,stack:get_name(), iteration, target_x, target_y) then
			return false
		end
	end
	return true;
end
local function take_func(villager,stack,data)
	assert(villager  ~= nil)
	assert(stack     ~= nil)
	assert(data      == nil)
	local item_name = stack:get_name()
	local ntarget = #recipes
	for iteration=1,ntarget,1 do
		if craft_tables.is_craftingsupplies(villager,item_name, iteration, nil, nil) then
			local inv = villager:get_inventory()
			local itemstack = ItemStack(item_name)
			local count = craft_tables.get_craftingsupplies(villager,item_name, iteration, nil, nil)
			assert(count ~= nil)
			assert(count ~= 0)
			-- TODO allow to specify number of copies to make
			itemstack:set_count(craft_tables.get_craftingsupplies(villager,item_name, iteration, nil, nil))
			if (not inv:contains_item("main", itemstack)) then
				return true
			end
		end
	end
	return false
end

local function put_craftingsupplies(villager,stack,data)
	assert(villager  ~= nil)
	assert(stack     ~= nil)

	local target_x
	if data == nil then target_x = nil else target_x = data.target_x end
	local target_y
	if data == nil then target_y = nil else target_y = data.target_y end

	-- TODO allow to specify number to put in each slot

	local name = stack:get_name()
	if data ~= nil and data.iteration ~= nil then
		return craft_tables.is_craftingsupplies(villager,name, data.iteration, target_x, target_y)
	end
	assert(data.iteration ~= nil)

	local ntarget = #recipes
	for iteration=1,ntarget,1 do
		if craft_tables.is_craftingsupplies(villager,name, iteration, target_x, target_y) then
			return true
		end
	end
	return false
end

working_villages.register_job("working_villages:job_craftsman", {
	description = S("craftsman (working_villages)"),
	long_description = S("I look for a craft table and carry out trade-specific recipes."),
	inventory_image	= "default_paper.png^working_villages_herb_collector.png",
	trivia = trivia.get_trivia({
		"My job position contributed to the complexity and general applicability of our appliance-handling logic.",
	}, {trivia.unfinished, trivia.appliances,}),
	workflow = {
		S("Wake up"),
		S("Handle my chest"),
		S("Go to work"),
		S("Search for crafting tables"),
		S("Go to crafting table"),
		S("Handle crafting table"),
		S("Periodically look away thoughtfully"),
	},
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(
			take_func,
			put_func
		)
		self:handle_job_pos()

		self:count_timer("craftsman:search")
		self:count_timer("craftsman:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("craftsman:search",20) then
			self:collect_nearest_item_by_condition(craft_tables.is_craft_table, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_craft_table_node, searching_range)
			if target ~= nil then
				local destination = func.find_adjacent_clear(target)
				if destination then
					destination = func.find_ground_below(destination)
				end
				if destination==false then
					print("failure: no adjacent walkable found")
					destination = target
				end
				local success, ret = self:go_to(destination)
				if not success then
					assert(target ~= nil)
					working_villages.failed_pos_record(target)
					self:set_displayed_action("looking at the unreachable crafting table")
					self:delay(100)
				else
					local target_def = minetest.get_node(target)
					local plant_data = craft_tables.get_craft_table(target_def.name);
					if plant_data then
						self:set_displayed_action("operating the crafting table")
						self:handle_craft_table(
						        target,
							func.take_everything, -- take everything
							put_craftingsupplies,
							{ recipes = recipes, }
						)
					end
				end
			end
		elseif self:timer_exceeded("craftsman:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.craft_tables = craft_tables
