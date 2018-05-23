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