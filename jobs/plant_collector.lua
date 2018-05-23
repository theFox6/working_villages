working_villages.herbs={
	groups = {
		"flora",
	},
	names = {
		"default:apple",
		"default:cactus",
		"default:papyrus",
		"default:dry_shrub",
		"flowers:mushroom_brown",
		"flowers:mushroom_red",
	}
}

function working_villages.func.is_herb(node)
	local nname=node
	if type(nname)=="table" then
		nname=nname.name
	end
	for _, i in ipairs(working_villages.herbs.groups) do
		if minetest.get_item_group(nname, i) > 0 then
			--print("found some "..i)
			return true
		end
	end
	for _, i in ipairs(working_villages.herbs.names) do
		if nname==i then
			--print("found a "..nname)
			return true
		end
	end
	return false
end

local function find_herb(p)
	return working_villages.func.is_herb(minetest.get_node(p).name)
end

local function is_night()
	return minetest.get_timeofday() < 0.2 or minetest.get_timeofday() > 0.76
end

local searching_range = {x = 10, y = 3, z = 10}

working_villages.register_job("working_villages:job_herbcollector", {
	description      = "working_villages job : herb collector",
	inventory_image  = "default_paper.png^memorandum_letters.png",
	jobfunc = function(self)
		if is_night() then
			self:goto_bed()
		else
			self:count_timer("herbcollector:search")
			self:count_timer("herbcollector:change_dir")
			self:handle_obstacles()
			if self:timer_exceeded("herbcollector:search",20) then
				local sapling = self:get_nearest_item_by_condition(working_villages.func.is_herb, searching_range)
				if sapling ~= nil then
					local pos = sapling:getpos()
					--print("found a sapling at:".. minetest.pos_to_string(pos))
					local inv=self:get_inventory()
					if inv:room_for_item("main", ItemStack(sapling:get_luaentity().itemstring)) then
						self:go_to(pos)
						self:pickup_item()
					end
				end
				local target = working_villages.func.search_surrounding(self.object:getpos(), find_herb, searching_range)
				if target ~= nil then
					local destination = working_villages.func.find_adjacent_clear(target)
					if destination==false then
						print("failure: no adjacent walkable found")
						destination = target
					end
					self:go_to(destination)
					self:dig(target)
				end
			elseif self:timer_exceeded("herbcollector:change_dir",50) then
				self:count_timer("herbcollector:search")
				self:change_direction_randomly()
			end
		end
	end,
})