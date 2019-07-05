local forms = {}
local schems = building_sign.registered_schematics
--TODO: replace outside prompt by outer door detection
--TODO: replace bed position promt by detection
--TODO: translations

function forms.build_form(meta)
	local title = meta:get_string("schematic"):gsub("%.we","")
	local button_build
	if meta:get_string("state") == "planned" then
		button_build = "button_exit[5.0,1.0;3.0,0.5;build_start;Begin Build]"
	elseif meta:get_string("state") == "paused" then
		button_build = "button_exit[5.0,2.0;3.0,0.5;build_resume;Resume Build]"
	elseif meta:get_string("state") == "begun" then
		button_build = "button_exit[5.0,2.0;3.0,0.5;build_pause;Pause Build]"
	else
		button_build = "button_exit[5.0,2.0;3.0,0.5;build_update;Update Build]"
	end
	local index = meta:get_int("index")
	local buildpos = working_villages.buildings.get_build_pos(meta)
	local building = working_villages.buildings.get(buildpos)
	local nodelist = building.nodedata
	if not nodelist then nodelist = {} end
	local formspec = "size[8,10]"
		.."label[3.0,0.0;Project: "..title.."]"
		.."label[3.0,1.0;"..math.ceil(((index-1)/#nodelist)*100).."% finished]"
		.."textlist[0.0,2.0;4.0,3.5;inv_sel;"..working_villages.buildings.get_materials(nodelist)..";"..index..";]"
		..button_build
		.."button_exit[5.0,3.0;3.0,0.5;build_cancel;Cancel Build]"
	return formspec
end

function forms.make_formspec(meta)
	local state = meta:get_string("state")
	if state == "unplanned" then
		local schemslist = {}
		for _,el in pairs(schems) do
			table.insert(schemslist,minetest.formspec_escape(el))
		end
		local schemlist = table.concat(schemslist, ",") or ""
		local formspec = "size[6,5]"
			.."textlist[0.0,0.0;5.0,4.0;schemlist;"..schemlist..";;]"
			.."button_exit[5.0,4.5;1.0,0.5;exit;exit]"
		return formspec
	elseif state == "built" then
		local formspec = "size[5,5]"..
			"field[0.5,1;4,1;name;house label;${house_label}]"..
			"field[0.5,2;4,1;bed_pos;bed position;${bed}]"..
			"field[0.5,3;4,1;door_pos;position outside the house;${door}]"..
			"button_exit[1,4;2,1;assign_home;Write]"
		return formspec
	elseif state == "planned" or state == "paused" or state == "begun" then
		return forms.build_form(meta)
	end
end

function forms.on_receive_fields(pos, _, fields, sender)
	local meta = minetest.get_meta(pos)
	local sender_name = sender:get_player_name()
	if minetest.is_protected(pos, sender_name) then
		minetest.record_protection_violation(pos, sender_name)
		return
	end
	if meta:get_string("owner") ~= sender_name then
		return
	end
	if fields.schemlist then
		local id = tonumber(string.match(fields.schemlist, "%d+"))
		if id then
			if schems[id] then
				meta:set_string("schematic",schems[id])
				if schems[id] == "[custom house]" then
				  --TODO: ask for area
					meta:set_string("state","built")
					meta:set_string("house_label", "house " .. minetest.pos_to_string(pos))
				else
					local bpos = { --TODO: mounted to the house
						x=math.ceil(pos.x) + 2,
						y=math.floor(pos.y),
						z=math.ceil(pos.z) + 2
					}
					meta:set_string("build_pos",minetest.pos_to_string(bpos))
					working_villages.buildings.load_schematic(meta:get_string("schematic"),pos)
					meta:set_int("index",0)
					meta:set_string("state","planned")
				end
			end
		end
	elseif fields.build_cancel then
		--reset_build()
		working_villages.buildings.get(working_villages.buildings.get_build_pos(meta)).nodedata = nil
		meta:set_string("schematic","")
		meta:set_int("index",0)
		meta:set_string("valid","false")
		meta:set_string("state","unplanned")
	elseif fields.build_start then
		local nodelist = working_villages.buildings.get(working_villages.buildings.get_build_pos(meta)).nodedata
		for _,v in ipairs(nodelist) do
			minetest.remove_node(v.pos)
			--FIXME: the villager ought to do this
		end
		meta:set_int("index",1)
		meta:set_string("state","paused")
	elseif fields.build_resume then
		meta:set_string("state","begun")
	elseif fields.build_pause then
		meta:set_string("state","paused")
	elseif fields.build_update then
		minetest.log("warning","The state of the building sign at "..minetest.pos_to_string(pos) .. " is unknown." )
		local paused = meta:get_string("paused")
		if paused == "true" then
			meta:set_string("state","paused")
		elseif paused == "false" then
			meta:set_string("state","begun")
		end
	elseif fields.assign_home then
		local house_label = fields.name
		if house_label == "" then
			house_label = "house " .. minetest.pos_to_string(pos)
		end
		meta:set_string("house_label", house_label)
		meta:set_string("infotext", house_label)
		meta:set_string("valid", "true")
		local coords = minetest.string_to_pos(fields.bed_pos)
		if coords == nil then
			-- fail on illegal input of coordinates
			minetest.chat_send_player(sender_name, 'You failed to provide correct coordinates for the bed position. '..
				'Please enter the X, Y, and Z coordinates of the desired destination in a comma seperated list. '..
				'Example: The input "10,20,30" means the destination at the coordinates X=10, Y=20 and Z=30.')
			meta:set_string("valid", "false")
		elseif building_sign.out_of_limit(coords) then
			minetest.chat_send_player(sender_name, 'The coordinates of your bed position '..
				'do not exist in our coordinate system. Correct coordinates range from -30912 to 30927 in all axes.')
			meta:set_string("valid", "false")
		end
		meta:set_string("bed", fields.bed_pos)
		coords = minetest.string_to_pos(fields.door_pos)
		if coords == nil then
			-- fail on illegal input of coordinates
			minetest.chat_send_player(sender_name, 'You failed to provide correct coordinates for the door position. '..
				'Please enter the X, Y, and Z coordinates of the desired destination in a comma seperated list. '..
				'Example: The input "10,20,30" means the destination at the coordinates X=10, Y=20 and Z=30.')
			meta:set_string("valid", "false")
		elseif building_sign.out_of_limit(coords) then
			minetest.chat_send_player(sender_name, 'The coordinates of your bed position '..
				'do not exist in our coordinate system. Correct coordinates range from -30912 to 30927 in all axes.')
			meta:set_string("valid", "false")
		end
		meta:set_string("door", fields.door_pos)
		for _,home in pairs(working_villages.homes) do
			if vector.equals(home.marker, pos) then
				for k, v in pairs(working_villages.home.update) do
					home.update[k] = v
				end
			end
		end
	end
	meta:set_string("formspec",forms.make_formspec(meta))
end

building_sign.forms = forms
return forms
