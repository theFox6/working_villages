local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")
local trivia = working_villages.require("jobs/trivia")

local stones = {
  -- more priority definitions
	names = {
		["default:cobble"]={},
		["default:mossycobble"]={},
		["default:desert_cobble"]={},

		["default:stone"]={},
		["default:desert_stone"]={},
		["default:sandstone"]={},
		["default:desert_sandstone"]={},
		["default:silver_sandstone"]={},

		["default:permafrost_with_stones"]={},

		--["default:gravel"]={},
	},
  -- less priority definitions
	groups = {
		--["rock"]={},
		["stone"]={},
	},
}

function stones.get_stone(item_name)
  -- check more priority definitions
	for key, value in pairs(stones.names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(stones.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end

function stones.is_stone(item_name)
  local data = stones.get_stone(item_name);
  if (not data) then
    return false;
  end
  return true;
end

local function find_stone_node(self)
	return function(pos)
		if minetest.is_protected(pos, self:get_player_name()) then return false end
		if working_villages.failed_pos_test(pos) then return false end

		local node = minetest.get_node(pos);
  		local data = stones.get_stone(node.name);
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
	--return (not inv:contains_item("wield_item", itemstack))
	return (not inv:contains_item("main", itemstack))
end

working_villages.register_job("working_villages:job_miner", {
	description      = S("miner (working_villages)"),
	long_description = S("I look for all sorts of rocks and collect them."),
	trivia = trivia.get_trivia({}, {trivia.griefers,}),
	workflow = {
		S("Wake up"),
		S("Handle my chest"),
		S("Equip my tool"),
		S("Go to work"),
		S("Search for stone"),
		S("Go to stone"),
		S("Dig stone"),
		S("Periodically look away thoughtfully"),
	},
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

		self:count_timer("miner:search")
		self:count_timer("miner:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("miner:search",20) then
			searching_range.h = 2 -- this doesn't prevent burrowing
			self:collect_nearest_item_by_condition(stones.is_stone, searching_range)
			local target = func.search_surrounding_inv(self.object:get_pos(), find_stone_node(self), searching_range) -- that should fix 'em
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
						self:set_displayed_action("confused as to why mining failed at (x="..target.x..', y='..target.y..', z='..target.z..')')
						self:delay(100)
					end
				end
			end
		elseif self:timer_exceeded("miner:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.stones = stones
