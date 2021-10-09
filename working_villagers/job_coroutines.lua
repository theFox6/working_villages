local job_coroutines = {}

local commands = {
  ---command to suspend villagers job
  -- expected values after this:
  -- * reason #string
  --   * the reason for suspending to show in infotext
  pause = "pause the villagers job",
}
job_coroutines.commands = commands

local log = working_villages.require("log")

function job_coroutines.resume(self,dtime)
  local job = self:get_job()
  if not job then return end
  if not self.job_thread then
    if job.on_step then
      job.on_start(self)
      self.job_thread = coroutine.create(job.on_step)
    elseif job.jobfunc then
      self.job_thread = coroutine.create(job.jobfunc)
    else
      log.error("villager %s is running an invalid job",self.inventory_name)
    end
  end
  if coroutine.status(self.job_thread) == "dead" then
    if job.jobfunc then
      self.job_thread = coroutine.create(job.jobfunc)
    else
      self.job_thread = coroutine.create(job.on_step)
    end
  end
  if coroutine.status(self.job_thread) == "suspended" then
    local ret = {coroutine.resume(self.job_thread, self, dtime)}
    if ret[1] then
      if ret[2] == commands.pause then
       self:set_pause(true)
       self:set_displayed_action(ret[3])
      end
    else
      error("error in job_thread " .. ret[2]..": "..debug.traceback(self.job_thread))
    end
  end
end

return job_coroutines
