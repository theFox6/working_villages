local function find_snow(p) return minetest.get_node(p).name == "default:snow" end

local actions={}
actions.CLEAR = {to_state=function(self) self:set_state("dig_target") end,}
actions.WALK_TO_CLEAR = {to_state=function(self, destination,target)
				--print("found place to clear at: " .. minetest.pos_to_string(destination))
				self.destination = destination
				self.target = target
				self:set_state("goto_dest")
			end,
			search_condition = find_snow,
			next_state = actions.CLEAR
}
working_villages.func.villager_state_machine_job("job_snowclearer","snowclearer",actions, {})