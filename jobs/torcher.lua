local function is_dark(pos)
	local light_level = minetest.get_node_light(pos)
	return light_level <= 5
end

actions={}
actions.PLACE={self_condition=function(self)
				local front = self:get_front() -- if it is dark, set touch.
				local wield_stack = self:get_wield_item_stack()

				if is_dark(front)
				and (wield_stack:get_name() == "default:torch"
				or self:move_main_to_wield(function (itemname) return itemname == "default:torch" end)) then
					return true
				end
				return false

			end,
		func=function(self)
			if self.time_counter >= 5 then
				self.time_counter = -1
	
				local owner = minetest.get_player_by_name(self.owner_name)
				local wield_stack = self:get_wield_item_stack()
				local front = self:get_front()
	
				local pointed_thing = {
					type = "node",
					under = vector.add(front, {x = 0, y = -1, z = 0}),
					above = front,
				}
	
				if wield_stack:get_name() == "default:torch" then
					local res_stack, success = minetest.item_place_node(wield_stack, owner, pointed_thing)
					if success then
						res_stack:take_item(1)
						self:set_wield_item_stack(res_stack)
					end
				end
				if self.torcher_accompany then
					self.state=actions.ACCOMPANY
					self:set_animation(maidroid.animation_frames.WALK)
				else
					self.state = working_villages.registered_jobs["working_villages:job_torcher"].states.SEARCH
					self:set_animation(maidroid.animation_frames.STAND)
				end
			else
				self.time_counter = self.time_counter + 1
			end
		end,
		to_state=function(self)
				self.time_counter = 0
				self:set_animation(maidroid.animation_frames.MINE)
				self.torcher_accompany=false
			end}
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
				if is_dark(position) then
					local front = self:get_front() -- if it is dark, set touch.
					local wield_stack = self:get_wield_item_stack()
					if is_dark(front)
					and (wield_stack:get_name() == "default:torch"
					or self:move_main_to_wield(function (itemname) return itemname == "default:torch" end)) then
						self.time_counter = 0
						self.state = actions.PLACE
						self:set_animation(maidroid.animation_frames.WALK_MINE)
						self.torcher_accompany=true
						return
					end
				end
				local player_position = player:getpos()
				local direction = vector.subtract(player_position, position)
				if vector.length(direction) < 3 then
					self.state = working_villages.registered_jobs["working_villages:job_torcher"].states.SEARCH
					working_villages.registered_jobs["working_villages:job_torcher"].states.SEARCH.to_state(self)
					return
				end
				local velocity = self.object:getvelocity()
				self.object:setvelocity{x = direction.x, y = velocity.y, z = direction.z}
				self:set_yaw_by_direction(direction)

				--if villager is stoped by obstacle, the villager must jump.
				working_villages.func.handle_obstacles(self,true,false)
			end,
			to_state = function(self)
				self:set_animation(working_villages.animation_frames.WALK)
			end,
			}
local torcher_prop = {
	night_Active = true,
	search_idle = true
}
working_villages.func.villager_state_machine_job("job_torcher","torcher",actions,torcher_prop)