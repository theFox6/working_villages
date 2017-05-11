local actions={}
actions.ACCOMPANY={self_condition=function(self)
				local player = self:get_nearest_player(10)
				if player == nil then
					return false
				end
				if vector.length(vector.subtract(player:getpos(), self.object:getpos())) < 3 then
					return false
				end
				return true
			end,
			func = function(self)
				local player = self:get_nearest_player(10)
				if player == nil then
					self.state = working_villages.registered_jobs[self.get_job_name(self)].states.SEARCH
					working_villages.registered_jobs[self.get_job_name(self)].states.SEARCH.to_state(self)
					return
				end
				local position = self.object:getpos()
				local player_position = player:getpos()
				local direction = vector.subtract(player_position, position)
				if vector.length(direction) < 3 then
					self.state = working_villages.registered_jobs[self.get_job_name(self)].states.SEARCH
					working_villages.registered_jobs[self.get_job_name(self)].states.SEARCH.to_state(self)
					return
				end
				local velocity = self.object:getvelocity()
				self.object:setvelocity{x = direction.x, y = velocity.y, z = direction.z}
				self:set_yaw_by_direction(direction)

				--if villager is stoped by obstacle, the villager must jump.
				if velocity.y == 0 then
					local front_node = self:get_front_node()
					if front_node.name ~= "air" and minetest.registered_nodes[front_node.name] ~= nil
					and minetest.registered_nodes[front_node.name].walkable then
						self.object:setvelocity{x = direction.x, y = 5, z = direction.z}
					end
				end
			end,
			to_state = function(self)
				self:set_animation(working_villages.animation_frames.WALK)
			end,
			}
local follower_prop = {
	night_Active = true,
	search_idle = true
}
working_villages.func.villager_state_machine_job("job_folow_player","follower",actions,follower_prop)