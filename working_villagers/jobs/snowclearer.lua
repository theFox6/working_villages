local func = working_villages.require("jobs/util")
local S = minetest.get_translator("working_villages")
local trivia = working_villages.require("jobs/trivia")

local function find_snow(self)
	return function(p)
		if minetest.is_protected(p, self:get_player_name()) then return false end
		if working_villages.failed_pos_test(p) then return false end
		-- TODO what about ice? better bring bucket boy if you enable better ice
		return minetest.get_node(p).name == "default:snow"
	end
end

local searching_range = {x = 10, y = 3, z = 10}

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

working_villages.register_job("working_villages:job_snowclearer", {
	description      = S("snowclearer (working_villages)"),
	long_description = S("I clear away snow you know.\
My job is for testing not for harvesting.\
I must confess this job seems useless.\
I'm doing anyway, clearing the snow away."),
	trivia = trivia.get_trivia({}, {trivia.og, trivia.griefers,}),
	workflow = {
		S("Wake up"),
		S("Handle my chest"),
		--S("Equip my tool"),
		S("Go to work"),
		S("Search for snow"),
		S("Go to snow"),
		S("Dig snow"),
		S("Periodically look away thoughtfully"),
	},
	inventory_image  = "default_paper.png^memorandum_letters.png",
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

		self:count_timer("snowclearer:search")
		self:count_timer("snowclearer:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("snowclearer:search",20) then
			local target = func.search_surrounding(self.object:get_pos(), find_snow(self), searching_range)
			if target ~= nil then
				local destination = func.find_adjacent_clear(target)
				if destination==false then
					print("failure: no adjacent walkable found")
					destination = target
				end
				self:set_displayed_action("clearing snow away")
				--self:go_to(destination)
				--self:dig(target,true)
				local success, ret = self:go_to(destination)
				if not success then
					assert(target ~= nil)
					working_villages.failed_pos_record(target)
					self:set_displayed_action("looking at the unreachable snow")
					self:delay(100)
				else
					success, ret = self:dig(target,true)
					if not success then
						assert(target ~= nil)
						working_villages.failed_pos_record(target)
						self:set_displayed_action("confused as to why clearing failed")
						self:delay(100)
					end
				end
			end
			self:set_displayed_action("looking for work")
		elseif self:timer_exceeded("snowclearer:change_dir",50) then
			self:count_timer("snowclearer:search")
			self:change_direction_randomly()
		end
	end,
})
