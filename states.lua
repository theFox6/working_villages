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