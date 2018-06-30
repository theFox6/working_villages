working_villages.log = {}

function working_villages.log.make_logger(level)
	return function(inv_name, text, ...)
		if inv_name then
			minetest.log(level, "[working_villages] villager "..inv_name.." "..text:format(...))
		else
			minetest.log(level, "[working_villages] "..text:format(...))
		end
	end
end

working_villages.log.warning = working_villages.log.make_logger("warning")
working_villages.log.action = working_villages.log.make_logger("action")
working_villages.log.info = working_villages.make_logger("info")

function working_villages.check_modname_prefix(name)
	if name:sub(1,1) == ":" then
		-- If the name starts with a colon, we can skip the modname prefix
		-- mechanism.
		return name:sub(2)
	else
		-- Enforce that the name starts with the correct mod name.
		local modname = minetest.get_current_modname()
		if modname == nil then
			working_villages.log.warning("current_modname is nil")
			modname=name:split(":")[1]
		end
		local expected_prefix = modname .. ":"
		if name:sub(1, #expected_prefix) ~= expected_prefix then
			error("Name " .. name .. " does not follow naming conventions: " ..
				"\"" .. expected_prefix .. "\" or \":\" prefix required")
		end

		-- Enforce that the name only contains letters, numbers and underscores.
		local subname = name:sub(#expected_prefix+1)
		if subname:find("[^%w_]") then
			error("Name " .. name .. " does not follow naming conventions: " ..
				"contains unallowed characters")
		end

		return name
	end
end