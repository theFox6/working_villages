local function find_tree(p)
	local adj_node = minetest.get_node(p)
	if minetest.get_item_group(adj_node.name, "tree") > 0 then
		return true
	end
	return false
end

local function is_sapling(node)
	if minetest.get_item_group(node.name, "sapling") > 0 then
		return true
	end
	return false
end

local actions={}
actions.COLLECT = {to_state=function(self, path, destination, target)
				self.path = path
				self.destination = destination
				self.target = target
				self:set_state("goto_dest")
			end,
			target_getter=function(self, searching_range)
				local sapling = self:get_nearest_item_by_condition(is_sapling, searching_range)
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
actions.WALK_TO_PLANT = {to_state=function(self, path, destination, target)
				--print("found place to plant at: " .. minetest.pos_to_string(destination))
				self.path = path
				self.destination = destination
				self.target = target
				self:set_state("goto_dest")
			end,
			self_condition=function(self)
				local wield_stack = self:get_wield_item_stack()
				if minetest.get_item_group(wield_stack:get_name(), "sapling") > 0
				or self:move_main_to_wield(function(itemname)	return (minetest.get_item_group(itemname, "sapling") > 0) end) then
					return true
				end
				return false
			end,
			search_condition=function(pos)
				local node = minetest.get_node(pos)
				local lpos = vector.add(pos, {x = 0, y = -1, z = 0})
				local lnode = minetest.get_node(lpos)
				local light_level = minetest.get_node_light(pos)
				if node.name == "air"
				and minetest.get_item_group(lnode.name, "soil") > 0
				and light_level > 12 then
					return true
				end
				return false
			end,}
actions.CUT = {to_state=function(self) self:set_state("dig_target") end}
actions.WALK_TO_CUT = {to_state=function(self, path, destination,target)
				--print("found place to cut at: " .. minetest.pos_to_string(destination))
				self.path = path
				self.destination = destination
				self.target = target
				self:set_state("goto_dest")
			end,
			search_condition = find_tree,
			next_state = actions.CUT}
actions.PLANT = {to_state=function(self)
			local wield_stack = self:get_wield_item_stack()
			if minetest.get_item_group(wield_stack:get_name(), "sapling") > 0
			or self:move_main_to_wield(function(itemname)	return (minetest.get_item_group(itemname, "sapling") > 0) end) then
				self.time_counters[1] = 0
				self.object:setvelocity{x = 0, y = 0, z = 0}
				self:set_animation(working_villages.animation_frames.MINE)
				self:set_yaw_by_direction(vector.subtract(self.target, self.object:getpos()))
				return
			else
				working_villages.func.get_back_to_searching(self)
				return
			end
		end,
		func = function(self)
			if self.time_counters[1] >= 15 then
				local stack = self:get_wield_item_stack()
				local itemname = stack:get_name()
				local pointed_thing = {
					type = "node",
					under = vector.add(self.target, {x = 0, y = -1, z = 0}),
					above = self.target,
				}
				--minetest.item_place(stack, minetest.get_player_by_name(self.owner_name), pointed_thing)
				minetest.set_node(pointed_thing.above,{name = itemname})
				stack:take_item(1)
				self:set_wield_item_stack(stack)
				working_villages.func.get_back_to_searching(self)
			else
				self.time_counters[1] = self.time_counters[1] + 1
			end
		end,}
actions.WALK_TO_PLANT.next_state = actions.PLANT
local woodcutter_prop = {
	searching_range = {x = 10, y = 10, z = 10, h = 5}
}

working_villages.func.villager_state_machine_job("job_woodcutter","woodcutter",actions,woodcutter_prop)