local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")
local trivia = working_villages.require("jobs/trivia")

local rentals = {
	names = {
		["smartrenting:panel"]={},
	},
}


-- TODO fix these dummy items
local tradables = {
	sell_names = {
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
	sell_groups = {
		--["cash"]=99,
	},
  -- more priority definitions
	buy_names = {
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
	buy_groups = {
		["ore"]=99,
		["sand"]=99,
	},
}
function tradables.get_tradable(item_name)
	for key, value in pairs(tradables.sell_names) do
		if item_name==key then
			return value
		end
	end
  -- check more priority definitions
	for key, value in pairs(tradables.buy_names) do
		if item_name==key then
			return value
		end
	end
	for key, value in pairs(tradables.sell_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
  -- check less priority definitions
	for key, value in pairs(tradables.buy_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function tradables.is_tradable(item_name)
  local data = tradables.get_tradable(item_name);
  return data ~= nil
end
function tradables.get_buyable(item_name)
  -- check more priority definitions
	for key, value in pairs(tradables.buy_names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(tradables.buy_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function tradables.is_buyable(item_name)
  local data = tradables.get_buyable(item_name);
  return data ~= nil
end
function tradables.get_sellable(item_name)
  -- check more priority definitions
	for key, value in pairs(tradables.sell_names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(tradables.sell_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function tradables.is_sellable(item_name)
  local data = tradables.get_sellable(item_name);
  return data ~= nil
end






function rentals.get_rental(item_name)
	-- check more priority definitions
	for key, value in pairs(rentals.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function rentals.is_rental(item_name)
	local data = rentals.get_rental(item_name);
	return data ~= nil
end

local function find_rental_node(pos)
	local node = minetest.get_node(pos);
	local data = rentals.get_rental(node.name);
	return data ~= nil
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(_,stack)
	return not tradables.is_tradable(stack:get_name())
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not tradables.is_tradable(item_name) then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(tradables.get_tradable(item_name))
	return (not inv:contains_item("main", itemstack))
end

local function put_sellable(_,stack)
	return tradables.is_sellable(stack:get_name())
end

local function put_buyable(_,stack)
	return tradables.is_buyable(stack:get_name())
end

local function put_not_sellable(_,stack)
	return not tradables.is_sellable(stack:get_name())
end

working_villages.register_job("working_villages:job_landlord", {
	description = S("landlord (working_villages)"),
	long_description = S("I look for a rental and configure it to source special items."),
	trivia          = trivia.get_trivia({
	}, {trivia.appliances,trivia.special,trivia.meta,}),
	workflow        = {
		S("Wake up"),
		S("Handle my chest"),
		S("Go to work"),
		S("Search for rentals"),
		S("Go to rental"),
		S("Handle rental"),
		S("Periodically look away thoughtfully"),
	},
	inventory_image	= "default_paper.png^working_villages_builder.png",
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(
			--take_func, -- take buyable + sell
			--put_func   -- put not(buyable or sell)
			take_sellable, -- take the junk we need to offload to the player
			--put_buyable,   -- put the goodies we need from the player
			put_not_sellable  -- put the goodies we need from the player
		)
		self:handle_job_pos()

		self:count_timer("landlord:search")
		self:count_timer("landlord:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("landlord:search",20) then
			self:collect_nearest_item_by_condition(rentals.is_rental, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_rental_node, searching_range)
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
					self:set_displayed_action("looking at the unreachable rental")
					self:delay(100)
				else
					local target_def = minetest.get_node(target)
					local plant_data = rentals.get_rental(target_def.name);
					if plant_data then
						self:set_displayed_action("operating the rental")

						local meta   = minetest.get_meta(target) --; if not meta then return end
						local owner = meta:get_string("owner")
						local my_name = self:get_player_name()
						if owner == "" -- claim unowned rentals
						or owner == self.owner_name -- operate rentals for your owner
						-- TODO or if griefing, then imminent domain
						then
							meta:set_string("owner", my_name)
							owner = my_name
						end
						if owner == my_name then
							local rentable = meta:get_int("rentable")

							if rentable == 0 then
								-- prepare
								-- TODO maybe these can be gotten from the builder's schematics ?
								--meta:set_int("right")
								--meta:set_int("front")
								--meta:set_int("left")
								--meta:set_int("back")
								--meta:set_int("up")
								--meta:set_int("down")
								--meta:set_int("every")
								--meta:set_int("count")
								--meta:set_string("category")
								--meta:set_int("keep")
								local inv = meta:get_inventory()
								local buyable = "default:gold_lump" -- TODO cycle through the needed items list
								inv:set_stack("pay", 1, buyable)
							elseif rentable == 1 then
								-- rent out
							elseif rentable == 2 then
								-- able for renting
							elseif rentable == 3 then
								-- rented
							else assert(false) end

							-- if rentable & owner
							--   set paying to what we need
							--self:set_displayed_action("waiting on rental")
						end
					end
				end
			end
		elseif self:timer_exceeded("landlord:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.tradables = tradables
