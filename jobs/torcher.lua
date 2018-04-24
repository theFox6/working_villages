local function is_dark(pos)
	local light_level = minetest.get_node_light(pos)
	return light_level <= 5
end

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
					working_villages.func.get_back_to_searching(self)
					return
				end
				local position = self.object:getpos()
				if is_dark(position) then
					local front = self:get_front() -- if it is dark, set torch.
					local wield_stack = self:get_wield_item_stack()
					if is_dark(front)
					and (wield_stack:get_name() == "default:torch"
					or self:move_main_to_wield(function (itemname) return itemname == "default:torch" end)) then
						self.target = front
						--FIXME: somehow the placement is wrong
						self:set_state("place_wield")
						self.torcher_accompany=true
						return
					end
				end
				local player_position = player:getpos()
				local direction = vector.subtract(player_position, position)
				if vector.length(direction) < 3 then
					working_villages.func.get_back_to_searching(self)
					return
				end
				local velocity = self.object:getvelocity()
				self.object:setvelocity{x = direction.x, y = velocity.y, z = direction.z}
				self:set_yaw_by_direction(direction)

				--if villager is stoped by obstacle, the villager must jump.
				self:handle_obstacles(true,false)
			end,
			to_state = function(self)
				self:set_animation(working_villages.animation_frames.WALK)
			end,
			}
local torcher_prop = {
	night_active = true,
	search_idle = true
}
working_villages.func.villager_state_machine_job("job_torcher","torcher",actions,torcher_prop)