local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")
local trivia = working_villages.require("jobs/trivia")

local vendorkiosks = {
	names = {
		["fancy_vend:player_vendor"]={},
	},
}


-- TODO
local tradables = {
	buyable_names = {
		["default:coalblock"] = 99,
		["default:coal_lump"] = 99,
		["bucket:bucket_lava"] = 99,
		["default:lava_source"] = 99,
	},
	buyable_groups = {
	},
  -- more priority definitions
	sellable_names = {
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
	sellable_groups = {
		["ore"]=99,
		["sand"]=99,
	},
}
function tradables.get_tradable(item_name)
	for key, value in pairs(tradables.buyable_names) do
		if item_name==key then
			return value
		end
	end
  -- check more priority definitions
	for key, value in pairs(tradables.sellable_names) do
		if item_name==key then
			return value
		end
	end
	for key, value in pairs(tradables.buyable_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
  -- check less priority definitions
	for key, value in pairs(tradables.sellable_groups) do
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
function tradables.get_sellable(item_name)
  -- check more priority definitions
	for key, value in pairs(tradables.sellable_names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(tradables.sellable_groups) do
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
function tradables.get_buyable(item_name)
  -- check more priority definitions
	for key, value in pairs(tradables.buyable_names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(tradables.buyable_groups) do
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






function vendorkiosks.get_vendorkiosk(item_name)
	-- check more priority definitions
	for key, value in pairs(vendorkiosks.sellable_names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function vendorkiosks.is_vendorkiosk(item_name)
	local data = vendorkiosks.get_vendorkiosk(item_name);
	return data ~= nil
end

local function find_vendorkiosk_node(pos)
	local node = minetest.get_node(pos);
	local data = vendorkiosks.get_vendorkiosk(node.name);
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

local function put_buyable(_,stack)
	return tradables.is_buyable(stack:get_name())
end

local function put_sellable(_,stack)
	return tradables.is_sellable(stack:get_name())
end

working_villages.register_job("working_villages:job_vendor", {
	description = S("vendor (working_villages)"),
	long_description = S("I look for a vendor kiosk and start putting the contents of your chest into it."),
	trivia          = trivia.get_trivia({
	}, {trivia.appliances,trivia.special,trivia.meta,}),
	workflow        = {
		S("Wake up"),
		S("Handle my chest"),
		S("Go to work"),
		S("Search for vendor kiosks"),
		S("Go to vendor kiosk"),
		S("Handle vendor kiosk"),
		S("Periodically look away thoughtfully"),
	},
	inventory_image	= "default_paper.png^working_villages_builder.png",
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(
			take_func, -- take sellable + buyable
			put_func   -- put not(sellable or buyable)
		)
		self:handle_job_pos()

		self:count_timer("vendor:search")
		self:count_timer("vendor:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("vendor:search",20) then
			self:collect_nearest_item_by_condition(vendorkiosks.is_vendorkiosk, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_vendorkiosk_node, searching_range)
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
					self:set_displayed_action("looking at the unreachable vendor kiosk")
					self:delay(100)
				else
					local target_def = minetest.get_node(target)
					local plant_data = vendorkiosks.get_vendorkiosk(target_def.name);
					if plant_data then
						self:set_displayed_action("operating the vendor kiosk")
-- if vendor is configured
--   if we don't own the vendor
--     if it sells what we need
--       do buy
--   if we own the vendor
--       re-configure it to buy what we need (if necessary)
-- if vendor is unconfigured
--   if we own the vendor
--     configure it to buy what we need
--     => player can deposit eg gold to get eg food
--   if we don't own the vendor
--     configure it to sell what we need
--     => villager can deposit eg food to get eg gold
					end
				end
			end
		elseif self:timer_exceeded("vendor:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.tradables = tradables
