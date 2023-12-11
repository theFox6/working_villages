local func = working_villages.require("jobs/util")

local lockworkshops = {
	names = {
		["mcg_lockworkshop:lock_workshop"]={},
	},
}

local lockables = {
	lock_names = {
		["mcg_lockworkshop:lock"] = 99,
	},
	lock_groups = {
		["lock"]=99,
	},
  -- more priority definitions
	names = {
		["default:chest"] = 99,
		["3d_armor_stand:armor_stand"] = 99,
	},
  -- less priority definitions
	groups = {
		--["ore"]=99,
	},
}
function lockables.get_lockable(item_name)
	for key, value in pairs(lockables.lock_names) do
		if item_name==key then
			return value
		end
	end
  -- check more priority definitions
	for key, value in pairs(lockables.names) do
		if item_name==key then
			return value
		end
	end
	for key, value in pairs(lockables.lock_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
  -- check less priority definitions
	for key, value in pairs(lockables.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function lockables.is_lockable(item_name)
  local data = lockables.get_lockable(item_name);
  return data ~= nil
end
function lockables.get_unlocked(item_name)
  -- check more priority definitions
	for key, value in pairs(lockables.names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(lockables.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function lockables.is_unlocked(item_name)
  local data = lockables.get_unlocked(item_name);
  return data ~= nil
end
function lockables.get_lock(item_name)
  -- check more priority definitions
	for key, value in pairs(lockables.lock_names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(lockables.lock_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function lockables.is_lock(item_name)
  local data = lockables.get_lock(item_name);
  return data ~= nil
end






function lockworkshops.get_lockworkshop(item_name)
	-- check more priority definitions
	for key, value in pairs(lockworkshops.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function lockworkshops.is_lockworkshop(item_name)
	local data = lockworkshops.get_lockworkshop(item_name);
	return data ~= nil
end

local function find_lockworkshop_node(pos)
	local node = minetest.get_node(pos);
	local data = lockworkshops.get_lockworkshop(node.name);
	return data ~= nil
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(_,stack)
	return not lockables.is_lockable(stack:get_name())
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not lockables.is_lockable(item_name) then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(lockables.get_lockable(item_name))
	return (not inv:contains_item("main", itemstack))
end

local function put_lock(_,stack)
	return lockables.is_lock(stack:get_name())
end

local function put_unlocked(_,stack)
	return lockables.is_unlocked(stack:get_name())
end

working_villages.register_job("working_villages:job_locksmith", {
	description			= "locksmith (working_villages)",
	long_description = "I look for a lock workshop and start putting locks on things from the chest.",
	inventory_image	= "default_paper.png^working_villages_builder.png",
	trivia = {
		"We've got big plans!",
	},
	workflow = {
		"Wake up",
		"Handle my chest",
		"Go to work",
		"Search for lock workshops",
		"Go to lock workshop",
		"Handle lock workshop",
		"Periodically look away thoughtfully",
	},
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(
			take_func, -- take unlocked + locks
			put_func   -- put not(unlocked or fuel)
		)
		self:handle_job_pos()

		self:count_timer("locksmith:search")
		self:count_timer("locksmith:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("locksmith:search",20) then
			self:collect_nearest_item_by_condition(lockworkshops.is_lockworkshop, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_lockworkshop_node, searching_range)
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
					self:set_displayed_action("looking at the unreachable lock workshop")
					self:delay(100)
				else
					local target_def = minetest.get_node(target)
					local plant_data = lockworkshops.get_lockworkshop(target_def.name);
					if plant_data then
						self:set_displayed_action("operating the lock workshop")
						self:handle_lockworkshop(
						        target,
							func.take_everything, -- take everything
							put_unlocked, -- put what we need to furnace
							put_lock
						)
						--self.job_data.manipulated_chest   = false;
						--self.job_data.manipulated_furnace = false;
						--self:set_displayed_action("waiting on furnace")
					end
				end
			end
		elseif self:timer_exceeded("locksmith:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.lockworkshops = lockworkshops
