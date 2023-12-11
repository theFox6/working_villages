-- TODO under development

local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")

local fermenting_barrels = {
	names = {
		["wine:wine_barrel"]={},
	},
}

local fermentables = {
	-- filled buckets
	bucket_names = {
		"bucket:bucket_water" = 99,
		"bucket:bucket_river_water" = 99,
		"wooden_bucket:bucket_wood_water" = 99,
		"wooden_bucket:bucket_wood_river_water" = 99,
		"bucket_wooden:bucket_water" = 99,
		"bucket_wooden:bucket_river_water" = 99,
		"mcl_buckets:bucket_water" = 99,
		"farming:glass_water" = 99,
		"default:water_source" = 99,
		"default:river_water_source" = 99,
		"mcl_core:water_source" = 99,
		"bucket:bucket_water_uni_gold" = 99,
		"bucket:bucket_water_uni_mese" = 99,
		"bucket:bucket_water_uni_wood" = 99,
		"bucket:bucket_water_uni_steel" = 99,
		"bucket:bucket_water_uni_stone" = 99,
		"bucket:bucket_water_uni_bronze" = 99,
		"bucket:bucket_water_uni_diamond" = 99,
		"bucket:bucket_water_river_gold" = 99,
		"bucket:bucket_water_river_mese" = 99,
		"bucket:bucket_water_river_wood" = 99,
		"bucket:bucket_water_river_steel" = 99,
		"bucket:bucket_water_river_stone" = 99,
		"bucket:bucket_water_river_bronze" = 99,
		"bucket:bucket_water_river_diamond" = 99,
		"mesecraft_bucket:bucket_water" = 99,
		"mesecraft_bucket:bucket_river_water" = 99,
	},
	bucket_groups = {
		--["bucket"]=99,
	},
	-- fermentables
  -- more priority definitions
	names = {
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
		--["food"]=99,
	},
}
function fermentables.get_fermentable(item_name)
	for key, value in pairs(fermentables.bucket_names) do
		if item_name==key then
			return value
		end
	end
  -- check more priority definitions
	for key, value in pairs(fermentables.names) do
		if item_name==key then
			return value
		end
	end
	for key, value in pairs(fermentables.bucket_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
  -- check less priority definitions
	for key, value in pairs(fermentables.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function fermentables.is_fermentable(item_name)
  local data = fermentables.get_fermentable(item_name);
  return data ~= nil
end
function fermentables.get_cookable(item_name)
  -- check more priority definitions
	for key, value in pairs(fermentables.names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(fermentables.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function fermentables.is_cookable(item_name)
  local data = fermentables.get_cookable(item_name);
  return data ~= nil
end
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

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(_,stack)
	return not fermentables.is_fermentable(stack:get_name())
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not fermentables.is_fermentable(item_name) then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(fermentables.get_fermentable(item_name))
	return (not inv:contains_item("main", itemstack))
end

local function put_bucket(_,stack)
	return fermentables.is_bucket(stack:get_name())
end

local function put_cookable(_,stack)
	return fermentables.is_cookable(stack:get_name())
end

working_villages.register_job("working_villages:job_brewer", {
	description			= "brewer (working_villages)",
	long_description = "I look for a barrel and start preserving the farming surplus.",
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
						 	put_cookable, -- put what we need to fermenting_barrel
							put_bucket
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


	




-- TODO ok this is a bit more complex than I remember.
-- looks like this is a cross between the craftsman and the baker
-- src, src_b, dst

---- wine mod adds tequila by default
--wine:add_item({
--	{
--		{"wine:agave_syrup", "wine:blue_agave", "vessels:drinking_glass"},
--		"wine:glass_sparkling_agave_juice"
--	},
--	{"wine:blue_agave", "wine:glass_tequila"}
--})
--
---- default game
--if minetest.get_modpath("default") then
--
--	wine:add_item({
--		{"default:apple", "wine:glass_cider"},
--		{"default:papyrus", "wine:glass_rum"}
--	})
--end
--
---- xdecor
--if minetest.get_modpath("xdecor") then
--
--	wine:add_item({ {"xdecor:honey", "wine:glass_mead"} })
--end
--
---- mobs_animal
--if minetest.get_modpath("mobs_animal")
--or minetest.get_modpath("xanadu") then
--
--	wine:add_item({
--		{"mobs:honey", "wine:glass_mead"},
--		{{"mobs:glass_milk", "farming:wheat"}, "wine:glass_kefir"}
--	})
--end
--
---- farming
--if minetest.get_modpath("farming") then
--
--	wine:add_item({ {"farming:wheat", "wine:glass_wheat_beer"} })
--
--	if farming.mod and (farming.mod == "redo" or farming.mod == "undo") then
--
--		-- mint julep recipe
--		minetest.register_craft({
--			output = "wine:glass_mint",
--			recipe = {
--				{"farming:mint_leaf", "farming:mint_leaf", "farming:mint_leaf"},
--				{"wine:glass_bourbon", "farming:sugar", ""}
--			}
--		})
--
--		wine:add_item({
--			{"farming:grapes", "wine:glass_wine"},
--			{"farming:barley", "wine:glass_beer"},
--			{"farming:rice", "wine:glass_sake"},
--			{"farming:corn", "wine:glass_bourbon"},
--			{"farming:baked_potato", "wine:glass_vodka"},
--			{{"wine:glass_rum", "farming:coffee_beans"}, "wine:glass_coffee_liquor"},
--			{{"wine:glass_wine", "farming:sugar"}, "wine:glass_champagne"},
--			{
--				{"default:apple", "farming:sugar", "vessels:drinking_glass"},
--				"wine:glass_sparkling_apple_juice"
--			},
--			{
--				{"farming:carrot", "farming:sugar", "vessels:drinking_glass"},
--				"wine:glass_sparkling_carrot_juice"
--			},
--			{
--				{"farming:blackberry 2", "farming:sugar", "vessels:drinking_glass"},
--				"wine:glass_sparkling_blackberry_juice"
--			}
--		})
--	end
--end
--
---- ethereal
--if minetest.get_modpath("ethereal") then
--
--	wine:add_item({ {"ethereal:orange", "wine:glass_cointreau"} })
--
--	-- margarita recipe
--	minetest.register_craft({
--		output = "wine:glass_margarita 2",
--		recipe = {
--			{"wine:glass_cointreau", "wine:glass_tequila", "ethereal:lemon"}
--		}
--	})
--end
--
---- mineclone2
--if minetest.get_modpath("mcl_core") then
--
--	wine:add_item({
--		{"mcl_core:apple", "wine:glass_cider"},
--		{"mcl_core:reeds", "wine:glass_rum"},
--		{"mcl_farming:wheat_item", "wine:glass_wheat_beer"},
--		{"mcl_farming:potato_item_baked", "wine:glass_vodka"},
--		{
--			{"mcl_core:apple", "mcl_core:sugar", "vessels:drinking_glass"},
--			"wine:glass_sparkling_apple_juice"
--		},
--		{
--			{"mcl_farming:carrot_item", "mcl_core:sugar", "vessels:drinking_glass"},
--			"wine:glass_sparkling_carrot_juice"
--		}
--	})
--end
