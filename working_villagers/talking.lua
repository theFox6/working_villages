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

    local job = villager:get_job()
    if not job then return "I don't know." end

    local trivia = job.trivia
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

    -- return a random factoid
    local i = math.random(#trivia)
    return trivia[i]
end)

forms.put_link("working_villages:talking_menu", "working_villages:trivia",
	"What else?")


forms.register_text_page("working_villages:workflow",
  function(villager)
    assert(villager ~= nil)

    local job = villager:get_job()
    if not job then return "I don't know." end

    local workflow = job.workflow
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

    -- return all the steps
    local msg = 'Steps:'
    for _, step in ipairs(workflow) do
      msg = msg..'\n\t- '..step
    end
    msg = msg..'\n'
    return msg
end)

forms.put_link("working_villages:talking_menu", "working_villages:workflow",
	"How do you do your job?")

forms.register_text_page("working_villages:age",
  function(villager)
    assert(villager ~= nil)

    local dc0 = villager.day_count
    if dc0 == nil then
      return "I don't know."
    end
    local dcf = minetest.get_day_count()
    local ddc = dcf - dc0
    -- TODO weeks/months/years
    return "I am "..ddc.." days old."
end)

forms.put_link("working_villages:talking_menu", "working_villages:age",
	"How old are you?")

forms.register_text_page("working_villages:current_time",
  function(villager)
    assert(villager ~= nil)

    local midnight = 0.00
    local midmorn  = 0.25
    local midday   = 0.50
    local mideve   = 0.75
    local diff     = 0.25 / 2

    local tod = minetest.get_timeofday()
    if     midnight  - diff <= tod and tod <= midnight  + diff then
	return "It's the middle of the night."
    elseif midmorn - diff <= tod and tod <= midmorn + diff then
	return "It's morning."
    elseif midday  - diff <= tod and tod <= midday  + diff then
	return "It's midday."
    elseif mideve - diff  <= tod and tod <= mideve + diff then
	return "It's evening."
    end
end)

forms.put_link("working_villages:talking_menu", "working_villages:current_time",
	"What time is it?")

forms.register_text_page("working_villages:fave_color",
  function(villager)
    assert(villager ~= nil)
    local color = villager.fave_color
    if color == nil then
      return "I don't have a preference."
    end
    return "My favorite color is "..color
end)

forms.put_link("working_villages:talking_menu", "working_villages:fave_color",
	"What's your favorite color?")
forms.register_text_page("working_villages:biome",
  function(villager)
    assert(villager ~= nil)
    local pos            = villager:get_pos()
    local biome_data     = minetest.get_biome_data(pos)
    local biome_name     = minetest.get_biome_name(biome_data.biome)
    local biome_temp     = biome_data.heat
    local biome_humidity = biome_data.humidity

    return "This area is in the biome: " .. biome_name .. "\n" ..
           "The temperature here is: " .. biome_temp .. "\n" ..
           "The humidity here is: " .. biome_humidity .. "\n"
end)
forms.put_link("working_villages:talking_menu", "working_villages:biome",
	"Tell me about the area.")
-- TODO which mod provides get_weather() ?
--forms.register_text_page("working_villages:weather",
--  function(villager)
--    assert(villager ~= nil)
--    local weather_type, weather_intensity = minetest.get_weather()
--
--    local message = ""
--    if weather_type == 0 then
--      message = "The weather is clear"
--    elseif weather_type == 1 then
--      message = "It is raining"
--    elseif weather_type == 2 then
--      message = "It is snowing"
--    end
--
--    message = message .. "\n" ..
--              "The weather intensity is: " .. weather_intensity
--    return message
--end)
--forms.put_link("working_villages:talking_menu", "working_villages:weather",
--	"How's the weather?")

-- TODO where do you live/work -- how to get there -- but in human directions
-- TODO Who's your daddy and what does he do
-- TODO what do you need to do your job -- ie in general & rn specifically
-- TODO where is... (generalization of "where do you live/work")
-- TODO info about mod & server
-- TODO procedurally generated garbage 
-- TODO history of village/villager
-- TODO lineage support via a separate mod
-- TODO if the villager passes by a node with infotext or description or reads a book, etc., then we can add some trivia/facts. "I just read..", "did you know.."
-- TODO I might copy the multi-page handling from books since none of us seem to know how to do scrollbars
