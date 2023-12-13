local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")
local trivia = working_villages.require("jobs/trivia")

-- limited support to two replant definitions
local beehives = {
	names = {
		["church_candles:hive"]={},
		["church_candles:hive_empty"]={},
	},
}
-- other mods' beehives work differently
local bees = {
  -- more priority definitions
	names = {
		--["petz:bee"] = 99,
		--["mobs_animal:bee"] = 99,
	},
  -- less priority definitions
	groups = {
		--["bee"]=99,
	},
}
function bees.get_bee(item_name)
  -- check more priority definitions
	for key, value in pairs(bees.names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(bees.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function bees.is_bee(item_name)
  local data = bees.get_bee(item_name);
  return data ~= nil
end


function beehives.get_beehive(item_name)
	-- check more priority definitions
	for key, value in pairs(beehives.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function beehives.is_beehive(item_name)
	local data = beehives.get_beehive(item_name);
	return data ~= nil
end

local function find_beehive_node(pos)
	local node = minetest.get_node(pos);
	local data = beehives.get_beehive(node.name);
	return data ~= nil
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(_,stack)
	return not bees.is_bee(stack:get_name())
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not bees.is_bee(item_name) then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(99)
	return (not inv:contains_item("main", itemstack))
end

local function put_bee(_,stack)
	return bees.is_bee(stack:get_name())
end

working_villages.register_job("working_villages:job_beekeeper", {
	description = S("beekeeper (working_villages)"),
	long_description = S("I look for a beehive and start taking that sweet, sweet honey."),
	trivia = trivia.get_trivia({
		S("I'm the reason the herb collector has a no-raze (responsible foraging) option."),
	}, {trivia.break_basket,trivia.appliances,})
	workflow = {
		S("Wake up"),
		S("Handle my chest"),
		S("Go to work"),
		S("Search for beehives"),
		S("Go to beehive"),
		S("Handle beehive"),
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

		self:count_timer("beekeeper:search")
		self:count_timer("beekeeper:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("beekeeper:search",20) then
			self:collect_nearest_item_by_condition(beehives.is_beehive, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_beehive_node, searching_range)
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
					self:set_displayed_action("looking at the unreachable beehive")
					self:delay(100)
				else
					local target_def = minetest.get_node(target)
					local plant_data = beehives.get_beehive(target_def.name);
					if plant_data then
						self:set_displayed_action("operating the beehive")
						self:handle_beehive(
						        target,
							func.take_everything, -- take everything
							put_bee -- put what we need to beehive
						)
						--self.job_data.manipulated_chest   = false;
						--self.job_data.manipulated_beehive = false;
						--self:set_displayed_action("waiting on beehive")
					end
				end
			end
		elseif self:timer_exceeded("beekeeper:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.beehive_names = beehive_names
