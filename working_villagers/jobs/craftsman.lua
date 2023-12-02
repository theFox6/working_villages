-- TODO not working

-- TODO I can't find a craft table that I like

--CRAFT_TABLE_TYPE = "craft_table"
CRAFT_TABLE_TYPE = "crafting_bench"


local func = working_villages.require("jobs/util")
local log = working_villages.require("log")

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
}

function recipe_requires(recipe, item_name, target_x, target_y)
	if type(recipe) ~= "table" then
		assert(type(recipe) == "string")
		if recipe == item_name then return 1 end
		return 0
	end

	if target_x ~= nil
	or target_y ~= nil then
		assert(target_x ~= nil)
		assert(target_y ~= nil)
		return recipe[target_y][target_x] == item_name
	end
	assert(target_x == nil)
	assert(target_y == nil)

	local count = 0
	for _,dep in pairs(recipe) do
		count = count + recipe_requires(dep, item_name, nil, nil)
	end
	return count
end

-- called by take_func for all iterations
function craft_tables.get_craftingsupplies(self, item_name, iteration, target_x, target_y)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
	local recipe = recipes[iteration]
	assert(recipe ~= nil)
	local count = recipe_requires(recipe, item_name, target_x, target_y)
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
























local function put_func2(villager,stack,data)
	assert(villager  ~= nil)
	assert(stack     ~= nil)

	local target_x
	if data == nil then target_x = nil else target_x = data.target_x end
	local target_y
	if data == nil then target_y = nil else target_y = data.target_y end

	-- TODO allow to specify number to put in each slot
	
	if data ~= nil and data.iteration ~= nil then
		return craft_tables.is_craftingsupplies(villager,stack:get_name(), data.iteration, target_x, target_y)
	end

	local ntarget = #recipes
	for iteration=1,ntarget,1 do
		if craft_tables.is_craftingsupplies(villager,stack:get_name(), iteration, target_x, target_y) then
			return true
		end
	end
	return false
end


local function take_func2(villager,stack)
	assert(villager  ~= nil)
	assert(stack     ~= nil)
	-- TODO take all dyes and non-target wool
	local item_name = stack:get_name()
	local inv = villager:get_inventory()
	return (inv:room_for_item("main", stack))
end




















working_villages.register_job("working_villages:job_craftsman", {
	description			= "craftsman (working_villages)",
	long_description = "I look for a craft table and carry out trade-specific recipes.",
	inventory_image	= "default_paper.png^working_villages_herb_collector.png",
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(
			take_func, -- take dyeable + dye
			put_func   -- put not(dyeable or dye)
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
				self:go_to(destination)
				local target_def = minetest.get_node(target)
				local plant_data = craft_tables.get_craft_table(target_def.name);
				if plant_data then
					self:set_displayed_action("operating the furnace")
					self:handle_craft_table(
					        target,
						take_func2, -- take everything
						put_func2
					)
				end
			end
		elseif self:timer_exceeded("craftsman:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})



function func.is_craft_table(pos)
	local node = minetest.get_node(pos)
  if (node==nil) then
    return false;
  end
  if node.name=="crafting_bench:workbench"
  or node.name=="craft_table:simple" then
    return true;
  end
  local is_chest = minetest.get_item_group(node.name, "craft_table");
  if (is_chest~=0) then
    return true;
  end
  return false;
end




--function working_villages.villager:handle_dyemixer(dyemixer_pos, take_func, put_func, put_lock, data)
function working_villages.villager:handle_craft_table(craft_table_pos, take_func, put_func, data)
	assert(craft_table_pos     ~= nil)
	assert(take_func        ~= nil)
	assert(put_func         ~= nil)
	assert(data             == nil)
	assert(func.is_craft_table ~= nil)
	local my_data = {
		appliance_id  = 'my_craft_table',
		appliance_pos = craft_table_pos,
		is_appliance  = func.is_craft_table,
		operations    = {},
	}
	local ntarget = #recipes
	local index = 0
	for iteration=ntarget,1,-1 do
		-- TODO handle shapless, small shapes, etc.
		local list_name
		if CRAFT_TABLE_TYPE == "craft_table" then
			list_name = "craft"
		elseif CRAFT_TABLE_TYPE == "crafting_bench" then
			list_name = "rec"
		else assert(false) end
		for x=1,3,1 do -- 3 x 3 = 9
			for y=1,3,1 do
				local xy = 3*(x-1)+y
				index = index + 1
				my_data.operations[index]   = {
					list      = list_name,
					is_put    = true,
					put_func  = put_func,
					data      = {
						iteration    = iteration,
						recipe_x     = x,
						recipe_y     = y,
						target_index = xy,
						target_count = 1,
					},
				}
			end
		end

		if CRAFT_TABLE_TYPE == "crafting_bench" then
		index = index + 1
		my_data.operations[index]   = {
			list      = "src",
			is_put    = true,
			put_func  = put_func,
			data      = {
				iteration    = iteration,
				--recipe_x     = x,
				--recipe_y     = y,
				--target_index = xy,
			},
		}
		
		index = index + 1
		my_data.operations[index]   = {
			noop = 300,
		}

		index = index + 1
		my_data.operations[index]   = {
			list      = "dst",
			is_take   = true,
			take_func = take_func,
		}

		index = index + 1
		my_data.operations[index]   = {
			list      = "rec",
			is_take   = true,
			take_func = take_func,
		}

		index = index + 1
		my_data.operations[index]   = {
			list      = "src",
			is_take   = true,
			take_func = take_func,
		}

		end
	end
	for iteration=1,#my_data.operations,1 do
		assert(my_data.operations[iteration] ~= nil)
	end
	self:handle_appliance(my_data)
end

