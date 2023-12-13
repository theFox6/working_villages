-- TODO under development
-- TODO ok this is a bit more complex than I remember.
-- looks like this is a cross between the craftsman and the baker
-- I think handle_appliance() can handle this without modification
-- src, src_b, dst

local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")
local trivia = working_villages.require("jobs/trivia")

local recipes = {
	[1] = {
		{"wine:agave_syrup",       "wine:blue_agave",},
		{"vessels:drinking_glass", "",},
	},
	[2] = {
		{"wine:blue_agave",        "",},
		{"vessels:drinking_glass", "",},
	},
	[3] = {
		{"default:apple",          "",},
		{"vessels:drinking_glass", "",},
	},
	[4] = {
		{"default:papyrus",        "",},
		{"vessels:drinking_glass", "",},
	},
	[5] = {
		{"xdecor:honey",           "",},
		{"vessels:drinking_glass", "",},
	},
	[6] = {
		{"church_candles:honey",   "",},
		{"vessels:drinking_glass", "",},
	}, -- TODO only add this if `church_candles`+`iadecor` are present
	[7] = {
		{"mobs:honey",             "",},
		{"vessels:drinking_glass", "",},
	},
	-- TODO jar/bottle of honey
	[8] = {
		{"mobs:glass_milk",        "farming:wheat",},
		{"",                       "",},
	},
	[9] = {
		{"farming:wheat",          "",},
		{"vessels:drinking_glass", "",},
	},
	[10] = {
		{"farming:grapes",         "",},
		{"vessels:drinking_glass", "",},
	}, -- TODO patch `wine` to distingish between white wine, red wine and blush processes, as well as more types of fortified wines
	-- TODO patch farming to include grape varietals, such as reisling in cold climates
	-- TODO okay this needs to be in a WSET/sommelier mod
	-- geez, imagine a full-blown food safety mod
	[11] = {
		{"farming:barley",         "",},
		{"vessels:drinking_glass", "",},
	},
	[12] = {
		{"farming:rice",           "",},
		{"vessels:drinking_glass", "",},
	},
	[13] = {
		{"farming:corn",           "",},
		{"vessels:drinking_glass", "",},
	},
	[14] = {
		{"farming:baked_potato",   "",},
		{"vessels:drinking_glass", "",},
	},
	[15] = {
		{"wine:glass_rum",         "farming:coffee_beans",},
		{"",                       "",},
	},
	[16] = {
		{"wine:glass_wine",        "farming:sugar",},
		{"",                       "",},
	},
	[17] = {
		{"default:apple",          "farming:sugar",},
		{"vessels:drinking_glass", ""},
	},
	[18] = {
		{"farming:carrot",         "farming:sugar",},
		{"vessels:drinking_glass", "",},
	},
	--[19] = { {"farming:blackberry 2", "farming:sugar", "vessels:drinking_glass"}, },
	[19] = {
		{"farming:blackberry",     "farming:blackberry",},
		{"farming:sugar",          "vessels:drinking_glass",},
	},
	[20] = {
		{"ethereal_orange",        "",},
		{"vessels:drinking_glass", "",},
	},
	[21] = {
		{"wine:glass_cointreau",   "wine:glass_tequila",},
		{"ethereal:lemon",         "",},
	},
	[22] = {
		{"mcl_core:apple",         "",},
		{"vessels:drinking_glass", "",},
	},
	[23] = {
		{"mcl_core:reeds",         "",},
		{"vessels:drinking_glass", "",},
	},
	[24] = {
		{"mcl_farming:wheat_item", "",},
		{"vessels:drinking_glass", "",},
	},
	[25] = {
		{"mcl_farming:potato_item_baked", "",},
		{"vessels:drinking_glass",        "",},
	},
	[26] = {
		{"mcl_core:apple",         "mcl_core:sugar",},
		{"vessels:drinking_glass", "",},
	},
	[27] = {
		{"mcl_farming:carrot_item", "mcl_core:sugar",},
		{"vessels:drinking_glass",  "",},
	},
}


local fermenting_barrels = {
	names = {
		["wine:wine_barrel"]={},
	},
}

local fermentables = {
	-- filled buckets
	bucket_names = {
		["bucket:bucket_water"] = 99,
		["bucket:bucket_river_water"] = 99,
		["wooden_bucket:bucket_wood_water"] = 99,
		["wooden_bucket:bucket_wood_river_water"] = 99,
		["bucket_wooden:bucket_water"] = 99,
		["bucket_wooden:bucket_river_water"] = 99,
		["mcl_buckets:bucket_water"] = 99,
		["farming:glass_water"] = 99,
		["default:water_source"] = 99,
		["default:river_water_source"] = 99,
		["mcl_core:water_source"] = 99,
		["bucket:bucket_water_uni_gold"] = 99,
		["bucket:bucket_water_uni_mese"] = 99,
		["bucket:bucket_water_uni_wood"] = 99,
		["bucket:bucket_water_uni_steel"] = 99,
		["bucket:bucket_water_uni_stone"] = 99,
		["bucket:bucket_water_uni_bronze"] = 99,
		["bucket:bucket_water_uni_diamond"] = 99,
		["bucket:bucket_water_river_gold"] = 99,
		["bucket:bucket_water_river_mese"] = 99,
		["bucket:bucket_water_river_wood"] = 99,
		["bucket:bucket_water_river_steel"] = 99,
		["bucket:bucket_water_river_stone"] = 99,
		["bucket:bucket_water_river_bronze"] = 99,
		["bucket:bucket_water_river_diamond"] = 99,
		["mesecraft_bucket:bucket_water"] = 99,
		["mesecraft_bucket:bucket_river_water"] = 99,
	},
	bucket_groups = {
		--["bucket"]=99,
	},
	-- fermentables
}


function fermentables.get_bucket(item_name)
  -- check more priority definitions
	for key, value in pairs(fermentables.bucket_names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(fermentables.bucket_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function fermentables.is_bucket(item_name)
  local data = fermentables.get_bucket(item_name);
  return data ~= nil
end






function fermenting_barrels.get_fermenting_barrel(item_name)
	-- check more priority definitions
	for key, value in pairs(fermenting_barrels.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function fermenting_barrels.is_fermenting_barrel(item_name)
	local data = fermenting_barrels.get_fermenting_barrel(item_name);
	return data ~= nil
end

local function find_fermenting_barrel_node(pos)
	local node = minetest.get_node(pos);
	local data = fermenting_barrels.get_fermenting_barrel(node.name);
	return data ~= nil
end







-- TODO dedup
function fermentables.recipe_requires(recipe, item_name, target_x, target_y)
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
		count = count + fermentables.recipe_requires(dep, item_name, nil, nil)
	end
	return count
end

-- called by take_func for all iterations
function fermentables.get_craftingsupplies(self, item_name, iteration, target_x, target_y)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
	local recipe = recipes[iteration]

	--assert(recipe ~= nil)
	if recipe == nil then return nil end

	local count = fermentables.recipe_requires(recipe, item_name, target_x, target_y)
	if count == 0 then return nil end
	return count
end
-- called by put_func for all iterations
function fermentables.is_craftingsupplies(self, item_name, iteration, target_x, target_y)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
	-- TODO 
  local data = fermentables.get_craftingsupplies(self, item_name, iteration, target_x, target_y);
  return data ~= nil
end

local function put_func(villager,stack,data)
	assert(villager  ~= nil)
	assert(stack     ~= nil)

	local target_x
	if data == nil then target_x = nil else target_x = data.target_x end
	local target_y
	if data == nil then target_y = nil else target_y = data.target_y end

	local name = stack:get_name()

	if data ~= nil and data.iteration ~= nil then
		return not fermentables.is_craftingsupplies(villager,name, data.iteration, target_x, target_y)
	end
	--assert(data.iteration ~= nil)

	local ntarget = #recipes
	for iteration=1,ntarget,1 do
		if fermentables.is_craftingsupplies(villager,name, iteration, target_x, target_y) then
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
		if fermentables.is_craftingsupplies(villager,item_name, iteration, nil, nil) then
			local inv = villager:get_inventory()
			local itemstack = ItemStack(item_name)
			local count = fermentables.get_craftingsupplies(villager,item_name, iteration, nil, nil)
			assert(count ~= nil)
			assert(count ~= 0)
			-- TODO allow to specify number of copies to make
			itemstack:set_count(fermentables.get_craftingsupplies(villager,item_name, iteration, nil, nil))
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

	assert(data     ~= nil)
	assert(target_x ~= nil)
	assert(target_y ~= nil)
	
	if data ~= nil and data.iteration ~= nil then
		return fermentables.is_craftingsupplies(villager,stack:get_name(), data.iteration, target_x, target_y)
	end

	local ntarget = #recipes
	for iteration=1,ntarget,1 do
		if fermentables.is_craftingsupplies(villager,stack:get_name(), iteration, target_x, target_y) then
			return true
		end
	end
	return false
end


local searching_range = {x = 10, y = 3, z = 10}

local function put_bucket(_,stack)
	return fermentables.is_bucket(stack:get_name())
end

local function take_bucket(villager,stack,data)
	assert(villager  ~= nil)
	assert(stack     ~= nil)
	assert(data      == nil)
	local item_name = stack:get_name()
	--return item_name == "bucket:bucket_empty"
	return not fermentables.is_bucket(stack:get_name())
end


working_villages.register_job("working_villages:job_brewer", {
	description = S("brewer (working_villages)"),
	long_description = S("I look for a barrel and start preserving the farming surplus."),
	-- TODO
	trivia = trivia.get_trivia({}, {trivia.bread_basket, trivia.appliances, trivia.meta,}),
	-- TODO
	workflow = {
		S("Wake up"),
		S("Handle my chest"),
		S("Equip my tool"),
		S("Go to work"),
		S("Search for bones"),
		S("Go to bones"),
		S("Collect (dig) bones"),
		S("Periodically look away thoughtfully"),
	},
	inventory_image	= "default_paper.png^working_villages_builder.png",
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(
			take_func, -- take cookable + fuel
			put_func   -- put not(cookable or fuel)
		)
		self:handle_job_pos()

		self:count_timer("brewer:search")
		self:count_timer("brewer:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("brewer:search",20) then
			self:collect_nearest_item_by_condition(fermenting_barrels.is_fermenting_barrel, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_fermenting_barrel_node, searching_range)
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
					self:set_displayed_action("looking at the unreachable fermenting barrel")
					self:delay(100)
				else
					local target_def = minetest.get_node(target)
					local plant_data = fermenting_barrels.get_fermenting_barrel(target_def.name);
					if plant_data then
						self:set_displayed_action("operating the fermenting barrel")
						self:handle_fermenting_barrel(
					        	target,
						    	func.take_everything, -- take everything
						 	put_craftingsupplies, -- put what we need to fermenting_barrel
							take_bucket,
							put_bucket,
							{ recipes = recipes, }
						)
						--self.job_data.manipulated_chest   = false;
						--self.job_data.manipulated_fermenting_barrel = false;
						--self:set_displayed_action("waiting on fermenting_barrel")
					end
				end
			end
		elseif self:timer_exceeded("brewer:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.fermentables = fermentables


	





