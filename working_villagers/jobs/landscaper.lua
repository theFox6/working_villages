local func = working_villages.require("jobs/util")

local dirts = {
  -- more priority definitions
	names = {
		["default:dirt"]={},
		["default:dry_dirt"]={},
		["default:dirt_with_grass"]={},
		["default:dirt_with_dry_grass"]={},
		["default:dry_dirt_with_dry_grass"]={},
		["default:dirt_with_snow"]={},
		["default:dirt_with_coniferous_litter"]={},
		["default:dirt_with_rainforest_litter"]={},

		["default:sand"]={},
		["default:desert_sand"]={},
		["default:silver_sand"]={},

		["default:gravel"]={},
	},
  -- less priority definitions
	groups = {
		--["dirt"]={},
		--["soil"]={}, -- keep this guy away from the farmer
		["sand"]={},
		--["falling"]={},
	},
}

function dirts.get_dirt(item_name)
  -- check more priority definitions
	for key, value in pairs(dirts.names) do
		if item_name==key then
			return value
		end
	end
  -- check less priority definitions
	for key, value in pairs(dirts.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end

function dirts.is_dirt(item_name)
  local data = dirts.get_dirt(item_name);
  if (not data) then
    return false;
  end
  return true;
end

local function find_dirt_node(self)
	return function(pos)
		if minetest.is_protected(pos, self:get_player_name()) then return false end
		if working_villages.failed_pos_test(pos) then return false end

		local node = minetest.get_node(pos);
  		local data = dirts.get_dirt(node.name);
  		if (not data) then
    			return false;
  		end

  		return true;
	end
end

local searching_range = {x = 10, y = 5, z = 10}

local landscaping_demands = {
	["default:shovel_wood"] = 1,
	["default:shovel_mese"] = 1,
	["default:shovel_steel"] = 1,
	["default:shovel_stone"] = 1,
	["default:shovel_bronze"] = 1,
	["default:shovel_diamond"] = 1,
}
local function put_func(_,stack)
	return landscaping_demands[item_name] == nil
end
local function take_func(villager,stack)
	local item_name = stack:get_name()
	if not landscaping_demands[item_name] then return false end
	-- TODO don't take more than one shovel
	local inv = villager:get_inventory()
	local itemstack = ItemStack(item_name)
	itemstack:set_count(landscaping_demands[item_name])
	--return (not inv:contains_item("wield_item", itemstack))
	return (not inv:contains_item("main", itemstack))
end

working_villages.register_job("working_villages:job_landscaper", {
	description      = "landscaper (working_villages)",
	long_description = "I look for all sorts of dirt and collect it.",
	inventory_image  = "default_paper.png^working_villages_builder.png",
	jobfunc = function(self)
		self:handle_night()
		self:handle_chest(take_func, put_func)
		local stack  = self:get_wield_item_stack()
		if stack:is_empty() then
		self:move_main_to_wield(function(name)
  			return landscaping_demands[name] ~= nil
		end)
		end
		self:handle_job_pos()

		self:count_timer("landscaper:search")
		self:count_timer("landscaper:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("landscaper:search",20) then
			searching_range.h = 2 -- this doesn't really work to keep him from burrowing
			self:collect_nearest_item_by_condition(dirts.is_dirt, searching_range)
			local target = func.search_surrounding_inv(self.object:get_pos(), find_dirt_node(self), searching_range)
			if target ~= nil then
				local destination = func.find_adjacent_clear(target)
				if destination then -- I'm pretty sure this makes him burrow
				  destination = func.find_ground_below(destination)
				end
				if destination==false then
					print("failure: no adjacent walkable found")
					destination = target
				end
				self:set_displayed_action("digging some dirt")
				-- We may not be able to reach the log
				local success, ret = self:go_to(destination)
				if not success then
					assert(target ~= nil)
					working_villages.failed_pos_record(target)
					self:set_displayed_action("looking at the unreachable dirt")
					self:delay(100)
				else
					success, ret = self:dig(target,true)
					if not success then
						assert(target ~= nil)
						working_villages.failed_pos_record(target)
						self:set_displayed_action("confused as to why digging failed at (x="..target.x..', y='..target.y..', z='..target.z..')')
						self:delay(100)
					end
				end
			end
		elseif self:timer_exceeded("landscaper:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

working_villages.dirts = dirts
