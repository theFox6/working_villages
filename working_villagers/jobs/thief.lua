local fail = working_villages.require("failures")
local log = working_villages.require("log")
local co_command = working_villages.require("job_coroutines").commands
local follower = working_villages.require("jobs/follow_player")

-- "demands" to take from player
local taxable_items = {
	-- typical valuables
	["default:bronze_ingot"] = 1,
	["default:copper_ingot"] = 1,
	["default:copper_lump"] = 1,
	["default:diamond"] = 1,
	["default:gold_ingot"] = 1,
	["default:gold_lump"] = 1,
	["default:iron_ingot"] = 1,
	["default:iron_lump"] = 1,
	["default:mese_crystal"] = 1,
	["default:mese_crystal_fragment"] = 1,
	["default:tin_ingot"] = 1,
	["default:tin_lump"] = 1,
	-- hungry
	["default:apple"] = 1,
	["farming:bread"] = 1,
	["default:blueberries"] = 1,
	-- tools
	--["default:bronze_axe"] =1 ,
}
local blacklist_demands = {
	--["working_villages:commanding_sceptre"] = 1, -- this was getting annoying
}

local thief = {}

local EVERYTHING_IS_CASH = false
local ENABLE_BLACKLIST   = true
local function has_cash(inv)
	if inv == nil then return false end
    	if EVERYTHING_IS_CASH and not inv:is_empty("main") then return true end -- for testing
	-- whitelist:
	for item,count in pairs(taxable_items) do
		local stack = ItemStack(item)
		print('check whitelist for '..stack:get_name())
		if inv:contains_item("main", stack) then
			print("I'm gonna rob you")
			return true
		end
	end
	assert(inv ~= nil)
	if not ENABLE_BLACKLIST then return false end
	-- blacklist:
	local size = inv:get_size("main")
	for i=1,size,1 do
		local stack = inv:get_stack("main", i)
		local name  = stack:get_name()
		if name ~= nil then
			print('checking stack size '..name)
			if not stack:is_empty() then
				print('check blacklist for '..name)
				if  blacklist_demands[name] == nil
				and name:sub(1, 17) ~= 'working_villages:' then
					print("I'm gonna rob you")
					return true
				end
			end
		end
	end
	assert(inv ~= nil)
	return false
end

function get_nearest_player_with_cash(self, range_distance,pos)
	return self:get_nearest_player_with_condition(range_distance, pos, has_cash)
end

local function take_func(villager,stack)
	local name = stack:get_name()
	if ENABLE_BLACKLIST then
		return (blacklist_demands[name] == nil
		and     name:sub(1, 17) ~= 'working_villages:')
	end
	return (taxable_items[name] ~= nil)
end


function thief.step(self)
  			local position = self.object:get_pos()
  			local player,player_position = get_nearest_player_with_cash(self,10,position)
  			local direction = vector.new(0,0,0)
			local playername
  			if player~=nil and player:is_player() then
			playername = player:get_player_name()
			else
				playername = "something"
			end
  			if player~=nil then
				log.action("villager %s is targeting player %s", self.inventory_name, playername)
				self:set_state_info("I can lighten your load, but it'll cost ya")
    				direction = vector.subtract(player_position, position)
  			end

  			if vector.length(direction) < 3 then
    				--swim upward
    				if direction.y > 1 and minetest.get_item_group(minetest.get_node(position).name,"liquid") > 0 then
      					self:jump()
    				end

    				follower.stop(self)
				-- 
  				if player~=nil then
					log.action("villager %s is robbing player %s", self.inventory_name, playername)
					self:set_state_info("Time to pay the piper")
					local plr_inv = player:get_inventory()
					local size    = plr_inv:get_size("main")
					local vil_inv = self:get_inventory()
					for index = 1,size do
						local stack = plr_inv:get_stack("main", index);
						if (not stack:is_empty()) and (take_func(self, stack, data)) then
							log.action("villager %s is taking items %s from %s", self.inventory_name, stack:get_name(), playername)
							self:set_state_info("I am levying taxes.")
							local leftover = vil_inv:add_item("main", stack);
							plr_inv:set_stack("main", index, leftover);
							for _=0,10 do coroutine.yield() end --wait 10 steps
							self:set_state_info("Thanks for visiting our town, traveler.")
							return true
						end
					end
					return false -- TODO where does this go
				end
				
  			else
    				follower.walk_in_direction(self,direction)
  			end
			return false -- TODO whatever
end

-- copied from the torcher
working_villages.register_job("working_villages:job_thief", {
	description      = "thief (working_villages)",
	long_description = "I'm following the nearest player relieving him of his burdens.",
	inventory_image  = "default_paper.png^working_villages_torcher.png",
	jobfunc = function(self)
		-- crime doesn't sleep, so here's a hack to reset his internal state for handle_chest()
		local inv_is_full = not self:get_inventory():room_for_item("main", ItemStack("working_villages:commanding_sceptre 1"))
		self.job_data.manipulated_chest    = not inv_is_full
		self:handle_chest(nil, func.put_everything)
		--self:handle_job_pos()
		self:count_timer("thief:search")
		self:count_timer("thief:change_dir")
		--self:handle_obstacles()
		if self:timer_exceeded("thief:search",20) then
			thief.step(self)
		elseif self:timer_exceeded("thief:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})

return thief
