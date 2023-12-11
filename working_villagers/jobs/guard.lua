local log = working_villages.require("log")
local co_command = working_villages.require("job_coroutines").commands

--modes: stationary,escort,patrol,wandering

local guard_tools = {
	["default:sword_mese"] = 1,
	["default:sword_wood"] = 1,
	["default:sword_steel"] = 1,
	["default:sword_stone"] = 1,
	["default:sword_bronze"] = 1,
	["default:sword_diamond"] = 1,
	-- TODO armor, other weapons
}
working_villages.register_job("working_villages:job_guard", {
	description      = "guard (working_villages)",
	long_description = "I'm here on guard defending against all those whom I see as enemies.",
	inventory_image  = "default_paper.png^memorandum_letters.png", --TODO: sword/bow/shield
	trivia = {
                "We've got big plans!",
	},
	workflow = {
		"Equip my tool",
		"Go to work",
		--"Periodically look away thoughtfully",
	},
	-- TODO guard should wield a sword (and shield if appropriate mod is loaded)
	jobfunc = function(self)
		local stack  = self:get_wield_item_stack()
		if stack:is_empty() then
		self:move_main_to_wield(function(name)
  			return guard_tools[name] ~= nil
		end)
		end
		-- how to change the mode ?
		--local guard_mode = self:get_job_data("mode") or "stationary"
		local guard_mode = self:get_job_data("mode") or "wandering"

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

			local velocity = self.object:get_velocity()
			if vector.length(distance) < 3 then
				if velocity.x~=0 or velocity.y~=0 then
					self:set_animation(working_villages.animation_frames.STAND)
					self.object:set_velocity{x = 0, y = velocity.y, z = 0}
				end
			else
				if velocity.x==0 and velocity.y==0 then
					self:set_animation(working_villages.animation_frames.WALK)
				end
				--FIXME: don't run too fast, perhaps go_to
				self.object:set_velocity{x = distance.x, y = velocity.y, z = distance.z}
				self:set_yaw_by_direction(distance)

				--if villager is stoped by obstacle, the villager must jump.
				self:handle_obstacles(true)
			end
		elseif guard_mode == "patrol" then
			log.verbose("%s is patroling", self.inventory_name)
			--TODO: find nearest building, go there, remember the building
			--      next building, until no further buildings can be found, then restart
			-- once we get the global village table operational, we can probably just iterate the buildings
			-- then build on that logic for the "burglar" who will play a vital role in transporting goods between the bots
		elseif guard_mode == "wandering" then
			-- TODO need a mode to search for culprit when alarm is sounded
			-- TODO need a function to check every nook and cranny while patrolling... as opposed to:
			-- TODO jailer-patrol where he doesn't go in doors/offices
			-- TODO need a function to monitor an area (ie guard post or guard tower)
			-- TODO need combat logic
			log.verbose("%s is wandering", self.inventory_name)
			--TODO: walk randomly
			self:count_timer("guard:change_dir")
			if self:timer_exceeded("guard:change_dir",50) then
				self:handle_obstacles(true)
				self:change_direction_randomly()
			end
		end

		local enemy = self:get_nearest_enemy(20)
		if enemy then
			self:atack(enemy)
		end

		coroutine.yield()
	end,
})
