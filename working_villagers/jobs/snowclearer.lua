local func = working_villages.require("jobs/util")
local function find_snow(p) return minetest.get_node(p).name == "default:snow" end
local searching_range = {x = 10, y = 3, z = 10}

working_villages.register_job("working_villages:job_snowclearer", {
	description      = "snowclearer (working_villages)",
	long_description = "I clear away snow you know.\
My job is for testing not for harvesting.\
I must confess this job seems useless.\
I'm doing anyway, clearing the snow away.",
	inventory_image  = "default_paper.png^memorandum_letters.png",
	jobfunc = function(self)
		self:handle_night()

		self:count_timer("snowclearer:search")
		self:count_timer("snowclearer:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("snowclearer:search",20) then
			local target = func.search_surrounding(self.object:get_pos(), find_snow, searching_range)
			if target ~= nil then
				local destination = func.find_adjacent_clear(target)
				if destination==false then
					print("failure: no adjacent walkable found")
					destination = target
				end
				self:set_displayed_action("clearing snow away")
				self:go_to(destination)
				self:dig(target,true)
			end
			self:set_displayed_action("looking for work")
		elseif self:timer_exceeded("snowclearer:change_dir",50) then
			self:count_timer("snowclearer:search")
			self:change_direction_randomly()
		end
	end,
})
