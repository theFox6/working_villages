local func = working_villages.require("jobs/util")

local gems = {
  -- more priority definitions
	names = {
		["default:stone_with_tin"]={},
		["default:stone_with_coal"]={},
		["default:stone_with_gold"]={},
		["default:stone_with_iron"]={},
		["default:stone_with_mese"]={},
		["default:stone_with_copper"]={},
		["default:stone_diamond"]={},
	},
  -- less priority definitions
	groups = {
		["ore"]={},
	},
}

function gems.get_ore(item_name)
  -- check more priority definitions
	for key, value in pairs(gems.names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(gems.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end

function gems.is_ore(item_name)
  local data = gems.get_ore(item_name);
  if (not data) then
    return false;
  end
  return true;
end

local function find_ore_node(self)
	return function(pos)
		if minetest.is_protected(pos, self:get_player_name()) then return false end
		if working_villages.failed_pos_test(pos) then return false end

		local node = minetest.get_node(pos);
  		local data = gems.get_ore(node.name);
  		if (not data) then
    			return false;
  		end

  		return true;
	end
end

local searching_range = {x = 10, y = 5, z = 10}

local mining_demands = {
	["default:pick_wood"] = 1,
	["default:pick_mese"] = 1,
	["default:pick_steel"] = 1,
	["default:pick_stone"] = 1,
	["default:pick_bronze"] = 1,
	["default:pick_diamond"] = 1,
}
local function put_func(_,stack)
	return mining_demands[item_name] == nil
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not mining_demands[item_name] then return false end
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(mining_demands[item_name])
	return (not inv:contains_item("main", itemstack))
end

working_villages.register_job("working_villages:job_gem_miner", {
	description      = "gem miner (working_villages)",
	long_description = "I look for fancy rocks and collect them.",
	inventory_image  = "default_paper.png^working_villages_builder.png",
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(take_func, put_func)
		local stack  = self:get_wield_item_stack()
		if stack:is_empty() then
		self:move_main_to_wield(function(name)
  			return mining_demands[name] ~= nil
		end)
		end
		self:handle_job_pos()

		self:count_timer("gemminer:search")
		self:count_timer("gemminer:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("gemminer:search",20) then
			searching_range.h = 2 -- this doesn't prevent burrowing
			self:collect_nearest_item_by_condition(gems.is_ore, searching_range)
			local target = func.search_surrounding_inv(self.object:get_pos(), find_ore_node(self), searching_range) -- that should fix 'em
			if target ~= nil then
				local destination = func.find_adjacent_clear(target)
				if destination then -- this definitely makes him burrow
				  destination = func.find_ground_below(destination)
				end
				if destination==false then
					print("failure: no adjacent walkable found")
					destination = target
				end
				self:set_displayed_action("mining some rocks")
				-- We may not be able to reach the log
				local success, ret = self:go_to(destination)
				if not success then
					assert(target ~= nil)
					working_villages.failed_pos_record(target)
					self:set_displayed_action("looking at the unreachable rocks")
					self:delay(100)
				else
					success, ret = self:dig(target,true)
					if not success then
						assert(target ~= nil)
						working_villages.failed_pos_record(target)
						self:set_displayed_action("confused as to why mining failed")
						self:delay(100)
					end
				end
			end
		elseif self:timer_exceeded("gemminer:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.gems = gems
