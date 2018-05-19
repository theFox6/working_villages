working_villages.register_state("idle",{})

working_villages.register_state("job",{
	on_step = function(self,dtime)
		--[[ if owner didn't login, the villager does nothing.
		if not minetest.get_player_by_name(self.owner_name) then
			return
		end--]]


		local job = self:get_job()
		if not job then return end
		if type(job.on_step)=="function" then
			job.on_step(self, dtime)
		elseif self.job_thread then
			if coroutine.status(self.job_thread) == "dead" then
				self.job_thread = coroutine.create(job.jobfunc)
			end
			if coroutine.status(self.job_thread) == "suspended" then
				local state, err = coroutine.resume(self.job_thread, self)
				if state == false then
					error("error in job_thread " .. err)
				end
			end
		end
	end
})

working_villages.register_state("goto_dest",{
	on_start = function(self)
		self.destination=vector.round(self.destination)
		if working_villages.func.walkable_pos(self.destination) then
			self.destination=working_villages.pathfinder.get_ground_level(vector.round(self.destination))
		end
		local val_pos = working_villages.func.validate_pos(self.object:getpos())
		--FIXME: doesn't seem to be right if villager is right below a roof
		self.path = working_villages.pathfinder.get_reachable(val_pos,self.destination,self)
		self:set_timer("goto_dest:find_path",0) -- find path interval
		self:set_timer("goto_dest:change_dir",0)
		self:set_timer("goto_dest:give_up",0)
		if self.path == nil then
			self.path = {self.destination}
		end
		--print("the first waypiont on his path:" .. minetest.pos_to_string(self.path[1]))
		self:change_direction(self.path[1])
		self:set_animation(working_villages.animation_frames.WALK)
	end,
	on_step = function(self)
		self:count_timer("goto_dest:find_path")
		self:count_timer("goto_dest:change_dir")
		if self:timer_exceeded("goto_dest:find_path",100) then
			local val_pos = working_villages.func.validate_pos(self.object:getpos())
			local path = working_villages.pathfinder.get_reachable(val_pos,self.destination,self)
			if path == nil then
				self:count_timer("goto_dest:give_up")
				if self:timer_exceeded("goto_dest:give_up",3) then
					self.destination=vector.round(self.destination)
					if working_villages.func.walkable_pos(self.destination) then
						self.destination=working_villages.pathfinder.get_ground_level(vector.round(self.destination))
					end
					print("villager can't find path")
					--FIXME: we ought to give up at this point
				end
			else
				self.path = path
			end
		end

		if self:timer_exceeded("goto_dest:change_dir",30) then
			self:change_direction(self.path[1])
		end

		-- follow path
		if self:is_near({x=self.path[1].x,y=self.object:getpos().y,z=self.path[1].z}, 1) then
			table.remove(self.path, 1)
			--print("removed path element")

			if #self.path == 0 then -- end of path
				self:set_state("job")
			else -- else next step, follow next path.
				self:set_timer("goto_dest:find_path",0)
				self:change_direction(self.path[1])
			end
		else
			-- if vilager is stopped by obstacles, the villager must jump.
			self:handle_obstacles()
		end
	end,
	on_finish = function(self)
		self.object:setvelocity{x = 0, y = 0, z = 0}
		self.path = nil
		self:set_animation(working_villages.animation_frames.STAND)
	end
})

working_villages.register_state("dig_target",{
	on_start = function(self)
		self:set_timer("dig_target:animation",0)
		self.object:setvelocity{x = 0, y = 0, z = 0}
		self:set_animation(working_villages.animation_frames.MINE)
		self:set_yaw_by_direction(vector.subtract(self.target, self.object:getpos()))
	end,
	on_step = function(self)
		if self:timer_exceeded("dig_target:animation",30) then
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
			self:set_state("job")
		else
			self:count_timer("dig_target:animation")
		end
	end,
	on_finish = function(self)
		self:set_animation(working_villages.animation_frames.STAND)
	end
})

working_villages.register_state("place_wield", {
	on_start = function(self)
		if type(self.target)~="table" then
			error("no self.target position given")
		end
		local wield_stack = self:get_wield_item_stack()
		if wield_stack:get_name()=="" then
			self:set_state("job")
		end
		self:set_timer("place_wield:animation",0)
		if self.object:getvelocity().x==0 and self.object:getvelocity().z==0 then
			self:set_animation(working_villages.animation_frames.MINE)
		else
			self:set_animation(working_villages.animation_frames.WALK_MINE)
		end
		self:set_yaw_by_direction(vector.subtract(self.target, self.object:getpos()))
	end,
	on_step = function(self)
		if self:timer_exceeded("place_wield:animation",15) then
			local stack = self:get_wield_item_stack()
			local itemname = stack:get_name()
			local pointed_thing = {
				type = "node",
				above = self.target,
				under = vector.add(self.target, {x = 0, y = -1, z = 0}),
			}
			--minetest.item_place(stack, minetest.get_player_by_name(self.owner_name), pointed_thing)
			minetest.set_node(pointed_thing.above, {name = itemname})
			stack:take_item(1)
			self:set_wield_item_stack(stack)
			local sounds = minetest.registered_nodes[itemname].sounds
			if sounds then
				local sound = sounds.place
				if sound then
					minetest.sound_play(sound,{object=self.object, max_hear_distance = 10})
				end
			end
			self:set_state("job")
		else
			self:count_timer("place_wield:animation")
		end
	end,
	on_finish = function(self)
		if self.object:getvelocity().x==0 and self.object:getvelocity().z==0 then
			self:set_animation(working_villages.animation_frames.STAND)
		else
			self:set_animation(working_villages.animation_frames.WALK)
		end
	end
})