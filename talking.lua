working_villages.forms.register_menu_page("working_villages:talking_menu", "hello")

working_villages.forms.register_text_page("working_villages:job_desc",
	function(villager)
		return villager:get_job().long_description or "something..."
	end)

working_villages.forms.put_link("working_villages:talking_menu", "working_villages:job_desc",
	"What do you do in your job?")