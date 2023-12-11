local forms = working_villages.require("forms")

forms.register_menu_page("working_villages:talking_menu", "hello")

forms.register_text_page("working_villages:job_desc",
	function(villager)
		local job = villager:get_job()
		if not job then
			return "I don't have a job."
		end
		return job.long_description or "something..."
end)

forms.put_link("working_villages:talking_menu", "working_villages:job_desc",
	"What do you do in your job?")

forms.register_text_page("working_villages:state",
  function(villager)
    return villager.state_info
end)

forms.put_link("working_villages:talking_menu", "working_villages:state",
  "What do you doing at the moment?")


forms.register_text_page("working_villages:trivia",
  function(villager)
    assert(villager ~= nil)

    local trivia = villager.trivia
    if trivia == nil then
      return "That's all, my friend."
    end

    if type(trivia) == "string" then
      return trivia
    end

    assert(type(trivia) == "table")
    if #trivia == 0 then
      return "That's it for now."
    end

    local i = math.random(#trivia)
    return trivia[i]
end)

forms.put_link("working_villages:talking_menu", "working_villages:trivia",
	"What else?")


forms.register_text_page("working_villages:workflow",
  function(villager)
    assert(villager ~= nil)

    local workflow = villager.workflow
    if workflow == nil then
      return "I just do it."
    end

    if type(workflow) == "string" then
      return workflow
    end

    assert(type(workflow) == "table")
    if #workflow == 0 then
      return "It's hard to describe."
    end

    local msg = 'Steps:'
    for _, step in ipairs(workflow) do
      msg = msg..'\n\t- '..step
    end
    msg = msg..'\n'
    return msg
end)

forms.put_link("working_villages:talking_menu", "working_villages:workflow",
	"How do you do your job?")

-- TODO where do you live/work
-- TODO Who's your daddy and what does he do
-- TODO what do you need to do your job
-- TODO where is...

