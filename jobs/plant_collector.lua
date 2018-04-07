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
actions.COLLECT = {to_state=function(self, path, destination, target)
				self.path = path
				self.destination = destination
				self.target = target
				self.time_counters[1] = 0 -- find path interval
				self.time_counters[2] = 0
				self.time_counters[3] = 0
				if self.path ~= nil then
					self:change_direction(self.path[1])
				else
					self:change_direction(self.destination)
				end
				self:set_animation(working_villages.animation_frames.WALK)
			end,
			func = function(self)
				if self:is_near({x=self.destination.x,y=self.object:getpos().y,z=self.destination.z}, 0.5) then
					working_villages.func.get_back_to_searching(self)
				end
				local MAX_WALK_TIME = 800
				local FIND_PATH_TIME_INTERVAL = 200
				if self.time_counters[2] >= MAX_WALK_TIME then -- time over.
					working_villages.func.get_back_to_searching(self)
					return
				end

				self.time_counters[1] = self.time_counters[1] + 1
				self.time_counters[2] = self.time_counters[2] + 1
				self.time_counters[3] = self.time_counters[3] + 1

				if self.time_counters[3] >= 30 then
					self.time_counters[3] = 0
					self:change_direction(self.path[1])
				end

				if self.time_counters[1] >= FIND_PATH_TIME_INTERVAL then
					self.time_counters[1] = 0
					local val_pos = working_villages.func.validate_pos(self.object:getpos())
					local path = working_villages.pathfinder.find_path(val_pos, self.destination, self)
					if path == nil then
						working_villages.func.get_back_to_searching(self)
						return
					end
					self.path = path
				end

				-- follow path
				if self.path == nil then
					self.path={}
					self.path[1]=self.destination
				end
				if self:is_near(self.path[1], 0.5) then
					table.remove(self.path, 1)

					if #self.path == 0 then -- end of path
						working_villages.func.get_back_to_searching(self)
					else -- else next step, follow next path.
						self:change_direction(self.path[1])
						self.time_counters[1] = 0
					end
				else
					-- if villager is stopped by obstacles, the villager must jump.
					working_villages.func.handle_obstacles(self,false,true)
				end
			end,
			target_getter=function(self, searching_range)
				local sapling = self:get_nearest_item_by_condition(working_villages.func.is_herb, searching_range)
				if sapling ~= nil then
					local pos = sapling:getpos()
					--print("found a sapling at:".. pos.x .. "," .. pos.y .. "," .. pos.z)
					local inv=self:get_inventory()
					if inv:room_for_item("main", ItemStack(sapling:get_luaentity().itemstring)) then
						return pos
					end
				end
				return nil
			end,}
actions.WALK_TO_CLEAR = {to_state=function(self, path, destination,target)
				--print("going to herb at: " .. destination.x .. "," .. destination.y .. "," .. destination.z)
				self.path = path
				self.destination = destination
				self.target = target
				self.time_counters[1] = 0 -- folow path interval
				self.time_counters[2] = 0
				if self.path ~= nil then
					self:change_direction(self.path[1])
				else
					self:change_direction(self.destination)
				end
				self:set_animation(working_villages.animation_frames.WALK)
			end,
			func = function(self)
				if self:is_near(self.destination, 1.5) then
					return true
				end
				local MAX_WALK_TIME = 800
				local FIND_PATH_TIME_INTERVAL = 50
				if self.time_counters[2] >= MAX_WALK_TIME then 
					--print("time over: back to searching")
					working_villages.func.get_back_to_searching(self)
					return
				end

				self.time_counters[1] = self.time_counters[1] + 1
				self.time_counters[2] = self.time_counters[2] + 1

				if self.time_counters[1] >= FIND_PATH_TIME_INTERVAL then
					self.time_counters[1] = 0
					--print("looking for a new path")
					local val_pos = working_villages.func.validate_pos(self.object:getpos())
					local path = minetest.find_path(val_pos, self.destination, 10, 1, 1, "A*")
					if path == nil then
						--print("no new path found: back to searching")
						working_villages.func.get_back_to_searching(self)
						return
					end
					self.path = path
				end

				-- follow path

				if self.path == nil then
					self.path={}
					self.path[1]=self.destination
				end
				if self.path[1] == nil then
					self.path[1]=self.destination
				end
				if self:is_near(self.path[1], 0.5) then
					table.remove(self.path, 1)

					if #self.path == 0 then -- end of path
						return true
					else -- else next step, follow next path.
						self:change_direction(self.path[1])
						self.time_counters[1] = 0
					end

				else
					-- if villager is stopped by obstacles, the villager must jump.
					local velocity = self.object:getvelocity()
					if velocity.y == 0 then
						local front_node = self:get_front_node()
						if front_node.name ~= "air" and minetest.registered_nodes[front_node.name] ~= nil
						and minetest.registered_nodes[front_node.name].walkable
						and not (minetest.get_item_group(front_node.name, "fence") > 0) then
							self.object:setvelocity{x = velocity.x, y = 6, z = velocity.z}
						end
					end
				end
			end,
			search_condition = find_herb,
}
actions.CLEAR = {to_state=function(self)
			self.time_counters[1] = 0
			self.object:setvelocity{x = 0, y = 0, z = 0}
			self:set_animation(working_villages.animation_frames.MINE)
			self:set_yaw_by_direction(vector.subtract(self.target, self.object:getpos()))
		end,
		func = function(self, dtime)
			if self.time_counters[1] >= 30 then
				local destnode = minetest.get_node(self.target)
				minetest.remove_node(self.target)
				local stacks = minetest.get_node_drops(destnode.name)
				for _, stack in ipairs(stacks) do
					local leftover = self:add_item_to_main(stack)
					minetest.add_item(self.target, leftover)
				end
				local sounds = minetest.registered_nodes[destnode.name].sounds
				if sounds then
					local sound = sounds.dug
					if sound then
						minetest.sound_play(sound,{object=self.object, max_hear_distance = 10})
					end
				end
				working_villages.func.get_back_to_searching(self)
			else
				self.time_counters[1] = self.time_counters[1] + 1
			end
		end,}
actions.WALK_TO_CLEAR.next_state = actions.CLEAR
working_villages.func.villager_state_machine_job("job_herbcollector","herb collector",actions, {})