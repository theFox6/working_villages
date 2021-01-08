local log = working_villages.require("log")
local co_command = working_villages.require("job_coroutines").commands

--modes: stationary,escort,patrol,wandering

working_villages.register_job("working_villages:job_guard", {
	description      = "guard (working_villages)",
	long_description = "I'm here on guard defending against all those whom I see as enemies.",
	inventory_image  = "default_paper.png^memorandum_letters.png", --TODO: sword/bow/shield
	jobfunc = function(self)
		local guard_mode = self:get_job_data("mode") or "stationary"

		if guard_mode == "stationary" or self.pause then
			local guard_pos = self:get_job_data("guard_target")
			if guard_pos == nil then
				guard_pos = self.object:get_pos()
				self:set_job_data("guard_target",guard_pos)
			end
			self:go_to(guard_pos)
		elseif guard_mode == "escort" then
			local escort_target = self:get_job_data("guard_target")

			if escort_target == nil then
				escort_target = self.owner_name
			end

			escort_target = minetest.get_player_by_name(escort_target)

			if escort_target == nil then
				--perhaps only wait until the target returns
				return co_command.pause, "escort target not on server" 
			end

			local target_position = escort_target:get_pos()
			local distance = vector.subtract(target_position, self.object:get_pos())

			local velocity = self.object:getvelocity()
			if vector.length(distance) < 3 then
				if velocity.x~=0 or velocity.y~=0 then
					self:set_animation(working_villages.animation_frames.STAND)
					self.object:setvelocity{x = 0, y = velocity.y, z = 0}
				end
			else
				if velocity.x==0 and velocity.y==0 then
					self:set_animation(working_villages.animation_frames.WALK)
				end
				--FIXME: don't run too fast, perhaps go_to
				self.object:setvelocity{x = distance.x, y = velocity.y, z = distance.z}
				self:set_yaw_by_direction(distance)

				--if villager is stoped by obstacle, the villager must jump.
				self:handle_obstacles(true)
			end
		elseif guard_mode == "patrol" then
			log.verbose("%s is patroling", self.inventory_name)
			--TODO: find nearest building, go there, remember the building
			--      next building, until no further buildings can be found, then restart
		elseif guard_mode == "wandering" then
			log.verbose("%s is wandering", self.inventory_name)
			--TODO: walk randomly
		end

		local enemy = self:get_nearest_enemy(20)
		if enemy then
			self:atack(enemy)
		end

		coroutine.yield()
	end,
})
