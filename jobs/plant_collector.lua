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

local function find_herb(p)
	return working_villages.func.is_herb(minetest.get_node(p).name)
end

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

local actions={}
actions.COLLECT = {to_state=function(self, destination, target)
				self.destination = destination
				self.target = target
				self:set_state("goto_dest")
			end,
			target_getter=function(self, searching_range)
				local sapling = self:get_nearest_item_by_condition(working_villages.func.is_herb, searching_range)
				if sapling ~= nil then
					local pos = sapling:getpos()
					--print("found a sapling at:".. minetest.pos_to_string(pos))
					local inv=self:get_inventory()
					if inv:room_for_item("main", ItemStack(sapling:get_luaentity().itemstring)) then
						return pos
					end
				end
				return nil
			end,}
actions.CLEAR = {to_state=function(self) self:set_state("dig_target") end,}
actions.WALK_TO_CLEAR = {to_state=function(self, destination,target)
				--print("going to herb at: " .. minetest.pos_to_string(destination))
				self.destination = destination
				self.target = target
				self:set_state("goto_dest")
			end,
			search_condition = find_herb,
			next_state = actions.CLEAR
}
working_villages.func.villager_state_machine_job("job_herbcollector","herb collector",actions, {})