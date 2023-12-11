local func = working_villages.require("jobs/util")
local dyemixer_recipes = working_villages.require("jobs/dyemixer_recipes")
local log = working_villages.require("log")

local dyemixers = {
	names = {
		["mcg_dyemixer:dye_mixer"]={},
	},
}

local wools = {
	dye_groups = {
	},
	groups = {
		["wool"]=99,
	},
}


-- called by take_func for all iterations
function wools.get_dyingsupplies(self, item_name, iteration)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
	--if iteration == nil then iteration = 0 end -- TODO
	if self.job_data.wools.dye_names[iteration] ~= nil then
		for k,v in pairs(self.job_data.wools.dye_names[iteration]) do
	for key, value in pairs(v) do
		if item_name==key then
			return value
		end
	end
		end
	end
	if self.job_data.wools.target[iteration] ~= nil then
	for key, value in pairs(self.job_data.wools.target[iteration]) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	end
	for key, value in pairs(self.job_data.wools.names) do
		if item_name==key then
			return value
		end
	end
	for key, value in pairs(wools.dye_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	for key, value in pairs(wools.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
-- called by put_func for all iterations
function wools.is_dyingsupplies(self, item_name, iteration)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
	-- TODO 
  local data = wools.get_dyingsupplies(self, item_name, iteration);
  return data ~= nil
end
function wools.get_dyeable(self,item_name)
	assert(item_name ~= nil)
	for key, value in pairs(self.job_data.wools.names) do
		if item_name==key then
			return value
		end
	end
	for key, value in pairs(wools.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function wools.is_dyeable(self, item_name)
	assert(item_name ~= nil)
  local data = wools.get_dyeable(self, item_name);
  return data ~= nil
end
function wools.get_dye(self, item_name, iteration,ab)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
	assert(ab        ~= nil)
	--if iteration == nil then iteration = 0 end -- TODO
	if self.job_data.wools.dye_names[iteration] ~= nil then
	for key, value in pairs(self.job_data.wools.dye_names[iteration][ab]) do
		if item_name==key then
			return value
		end
	end
	end
	for key, value in pairs(wools.dye_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function wools.is_dye(self, item_name, iteration,ab)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
	assert(ab        ~= nil)
  local data = wools.get_dye(self, item_name, iteration,ab);
  return data ~= nil
end

function wools.get_target(self, item_name, iteration)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
	if self.job_data.wools.target[iteration] == nil then return nil end
	for key, value in pairs(self.job_data.wools.target[iteration]) do
		if item_name==key then
			return value
		end
	end
end
function wools.is_target(self, item_name, iteration)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
  local data = wools.get_target(self, item_name, iteration);
  return data ~= nil
end


function dyemixers.get_dyemixer(item_name)
	assert(item_name ~= nil)
	for key, value in pairs(dyemixers.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function dyemixers.is_dyemixer(item_name)
	assert(item_name ~= nil)
	local data = dyemixers.get_dyemixer(item_name);
	return data ~= nil
end

local function find_dyemixer_node(pos)
	assert(pos       ~= nil)
	local node = minetest.get_node(pos);
	local data = dyemixers.get_dyemixer(node.name);
	return data ~= nil
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(villager,stack)
	assert(villager  ~= nil)
	assert(stack     ~= nil)
	local ntarget = villager.job_data.wools.target
	      ntarget = #ntarget
	for iteration=0,ntarget,1 do
		if wools.is_dyingsupplies(villager,stack:get_name(), iteration) then -- TODO all iterations
			return false
		end
	end
	return true;
end
local function take_func(villager,stack)
	assert(villager  ~= nil)
	assert(stack     ~= nil)
	local item_name = stack:get_name()
	local ntarget = villager.job_data.wools.target
	      ntarget = #ntarget
	for iteration=0,ntarget,1 do
		if wools.is_dyingsupplies(villager,item_name, iteration) then
			local inv = villager:get_inventory()
			local itemstack = ItemStack(item_name)
			itemstack:set_count(wools.get_dyingsupplies(villager,item_name, iteration)) -- TODO all iterations
			if (not inv:contains_item("main", itemstack)) then
				return true
			end
		end
	end
	return false
end

local function put_dye(villager,stack,data)--,iteration,ab)
	assert(villager  ~= nil)
	assert(stack     ~= nil)
	assert(data      ~= nil)
	local iteration = data.iteration
	assert(iteration ~= nil)
	local ab        = data.ab
	assert(ab        ~= nil)
	return wools.is_dye(villager,stack:get_name(), iteration,ab) -- TODO
end

local function put_dyeable(villager,stack)
	assert(villager  ~= nil)
	assert(stack     ~= nil)
	return wools.is_dyeable(villager,stack:get_name())
end

local function put_target(villager,stack)--,data,iteration)
	assert(villager  ~= nil)
	assert(stack     ~= nil)
	local iteration = 1
	return wools.is_target(villager,stack:get_name(), iteration) -- TODO
end
local function take_target(villager,stack)--,data,iteration)
	assert(villager  ~= nil)
	assert(stack     ~= nil)
	local inv = villager:get_inventory()
	return (inv:room_for_item("main", stack))
end

local colors = {
	"red",     "blue",      "cyan",  "grey",   "pink",   "black",
	"brown",   "green",     "white", "orange", "violet", "yellow",
	"magenta", "dark_grey", "dark_green",
}


working_villages.register_job("working_villages:job_dyemixer", {
	description			= "dyemixer (working_villages)",
	long_description = "I look for a dyemixer and start putting your wools into it.",
	inventory_image	= "default_paper.png^working_villages_herb_collector.png",
	trivia = {
		"My job position was the first to craft recipes.",
		"My job position was the first to manage multi-step recipes.",
		"My job position contributed to the complexity and general applicability of our appliance-handling logic.",
	},
	workflow = {
		"Fashion season!",
		"Wake up",
		"Handle my chest",
		"Go to work",
		"Search for dyemixers",
		"Go to dyemixer",
		"Handle dyemixer",
		"Periodically look away thoughtfully",
	},
	jobfunc = function(self)
		dyemixer_recipes.fashion_season(self)

		self:handle_night()
		self:handle_chest(
			take_func, -- take dyeable + dye
			put_func   -- put not(dyeable or dye)
		)
		self:handle_job_pos()

		self:count_timer("dyemixer:search")
		self:count_timer("dyemixer:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("dyemixer:search",20) then
			self:collect_nearest_item_by_condition(dyemixers.is_dyemixer, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_dyemixer_node, searching_range)
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
					self:set_displayed_action("looking at the unreachable dyemixer")
					self:delay(100)
				else
					local target_def = minetest.get_node(target)
					local plant_data = dyemixers.get_dyemixer(target_def.name);
					if plant_data then
						self:set_displayed_action("operating the dyemixer")
						self:handle_dyemixer(
						        target,
							func.take_everything, -- take everything
							put_dyeable, -- put what we need to furnace
							put_dye,
							take_target,
							put_target
						)
					end
				end
			end
		elseif self:timer_exceeded("dyemixer:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})



