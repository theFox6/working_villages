working_villages.forms.register_menu_page("working_villages:talking_menu", "hello")

working_villages.forms.register_text_page("working_villages:job_desc",
	function(villager)
	  local job = villager:get_job()
	  if not job then
	   return "I don't have a job."
	  end 
		return job.long_description or "something..."
	end)

working_villages.forms.put_link("working_villages:talking_menu", "working_villages:job_desc",
	"What do you do in your job?")