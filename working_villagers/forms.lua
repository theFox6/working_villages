local forms = {}
local registered_forms = {}
local log = working_villages.require("log")

forms.villagers = {}
function forms.get_villager(inv_name)
	return forms.villagers[inv_name]
end

forms.last_pages = {}

function forms.go_back(villager,player_name)
	local last_page = forms.last_pages[villager.inventory_name].last
	forms.show_formspec(villager, last_page, player_name)
end

function forms.register_page(name, def)
	if registered_forms[name]~=nil then
		log.warning("overwriting formspec page %s",name)
	end
	assert(type(def.constructor)=="function")
	if def.receiver then assert(type(def.receiver)=="function") end
	if def.link_to then
		assert(type(def.link_to)=="table")
	else
		def.link_to = {}
	end
	if def.variables == nil then
		def.variables = {}
	end
	assert(type(def.variables)=="table")
	registered_forms[name] = def
end

function forms.put_link(source_page, target_page, description)
	assert(type(source_page)=="string")
	assert(type(target_page)=="string")
	assert(type(description)=="string")

	registered_forms[source_page].link_to[description] = target_page
end

function forms.show_formspec(villager, formname, playername)
	local page = registered_forms[formname]
	if page == nil then
		log.warning("page %s not registered", formname)
		page = registered_forms["working_villages:talking_menu"]
	end
	minetest.show_formspec(playername, formname.."_"..villager.inventory_name, page:constructor(villager, playername))
	forms.villagers[villager.inventory_name] = villager

	if forms.last_pages[villager.inventory_name] == nil then
		forms.last_pages[villager.inventory_name] = {}
	end
	local last_page_store = forms.last_pages[villager.inventory_name]
	if last_page_store.current == nil then
		last_page_store.last = formname
	else
		last_page_store.last = last_page_store.current
	end
	last_page_store.current = formname
end

--receive fields when villager was rightclicked

minetest.register_on_player_receive_fields(
	function(player, formname, fields)
		for n,p in pairs(registered_forms) do
			if string.find(formname, n.."_")==1 then
				if p.receiver then
					local inv_name = string.sub(formname, string.len(n.."_")+1)
					p:receiver(forms.get_villager(inv_name),player,fields)
				end
			end
		end
	end
)

function forms.form_base(width,height,villager)
	local jobname

	if villager then
		jobname = villager:get_job()
	end --perhaps only add jobname label if villager is given
	if jobname then
		jobname = jobname.description
	else
		jobname = "no job"
	end
	local villager_name = ""
	if villager.nametag and villager.nametag~="" then
		villager_name = villager.nametag.." - "
	end

	return "size["..width..","..height.."]"
		.. default.gui_bg
		.. default.gui_bg_img
		.. default.gui_slots
		.. "label[0,0;"..villager_name..jobname.."]"
end

function forms.register_menu_page(pageid, title)
	--TODO: conditional disabling buttons
	forms.register_page(pageid, {
		variables = {
			form_bottom = 9,
			title = title,
		},
		constructor = function(self,villager) --self, villager, playername
			local formbottom = self.variables.form_bottom
			local form = forms.form_base(8,formbottom,villager)
			local text = self.variables.title
			--TODO: random text from list
			form = form .. "label["..(4-(#text/10))..",1;"..text.."]"
			local y = 1
			for description, page_to in pairs(self.link_to) do
				y = y + 1
				form = form .. "button[0.5,"..y..";7,1;to_page-"..page_to..";"..minetest.formspec_escape(description).."]"
				if y >= formbottom-1 then
					log.warning("too many linked pages")
					--TODO: scroll down button
					break
				end
			end
			form = form .. "button_exit[3.5,"..(formbottom-1)..";1,1;exit;bye]"
			return form
		end,
		receiver = function(_, villager, sender, fields) --self, villager, sender, fields
			local sender_name = sender:get_player_name()
			local button = next(fields)
			if button:find("to_page-")==1 then
				local page_to = button:sub(9)
				forms.show_formspec(villager, page_to, sender_name)
			end
		end,
	})
end

-- Maximum characters per line in the text widget
local TEXT_LINELENGTH = 80

-- Inserts automatic line breaks into an entire text and preserves existing newlines
local linebreaker = function(text, linelength)
	local out = ""
	for s in string.gmatch(text, "([^\n]*)") do
		local l = minetest.wrap_text(s, linelength)
		out = out .. l
		if(string.len(l) == 0) then
			out = out .. "\n"
		end
	end
	-- Remove last newline
	if string.len(out) >= 1 then
		out = string.sub(out, 1, string.len(out) - 1)
	end
	return out
end

-- Inserts text suitable for a textlist (including automatic word-wrap)
local text_for_textlist = function(text, linelength)
	if text == nil then return "" end
	text = linebreaker(text, linelength)
	text = minetest.formspec_escape(text)
	text = string.gsub(text, "\n", ",")
	return text
end

forms.text_widget = function(x, y, width, height, widget_id, data)
	local baselength = TEXT_LINELENGTH
	local widget_basewidth = 10
	local linelength = math.max(20, math.floor(baselength * (width / widget_basewidth)))

	-- TODO: Wait for Minetest to provide a native widget for scrollable read-only text with automatic line breaks.
	-- Currently, all of this had to be hacked into this script manually by using/abusing the table widget
	local formstring = "tablecolumns[text]"..
	"tableoptions[color=#ffffffff;background=#00000000;border=false;highlight=#00000000;highlight_text=#ffffffff]"..
	"table["..tostring(x)..","..tostring(y)..";"..tostring(width)..","..tostring(height)..
		";"..widget_id..";"..text_for_textlist(data, linelength).."]"
	return formstring
end

function forms.register_text_page(pageid,text_constructor)
	forms.register_page(pageid, {
		constructor = function(_, villager, playername)
			local form = forms.form_base(6,8,villager)

			local out_text = type(text_constructor)
			if out_text=="string" then
				out_text = text_constructor
			elseif out_text=="function" then
				out_text = text_constructor(villager, playername)
			else
				out_text = "invalid text_constructor type: " .. out_text
				log.error(out_text)
				out_text = "(error) " .. out_text
			end
			form = form .. forms.text_widget(0,1,6,6,"out_text",out_text)
			form = form .. "button[2.5,7;1,1;back;ok]"
			return form
		end,
		receiver = function(_,villager,sender,fields)
			if fields.back then
				local sender_name = sender:get_player_name()
				forms.go_back(villager,sender_name)
			end
		end,
	})
end

forms.register_page("working_villages:job_change",{
	constructor = function(_, villager) --self, villager, playername
		local cp = { x = 3.5, y = 0 }
		local villager_name = ""
		if villager.nametag and villager.nametag~="" then
			villager_name = "label[0,0;"..villager.nametag.."]"
		end
		--return "size[8,6]"
		return "size[8,10]"
			.. default.gui_bg
			.. default.gui_bg_img
			.. default.gui_slots
			.. villager_name
			.. "label[".. cp.x - 0.25 ..",".. cp.y ..";current job]"
			.. "list[detached:".. villager.inventory_name ..";job;".. cp.x ..",".. cp.y + 0.5 ..";1,1;]"
			--.. "list[detached:working_villages:job_inv;main;0,2;8,4;]"
			.. "list[detached:working_villages:job_inv;main;0,2;8,8;]"
			.. "listring[]"
			.. "button[6,".. cp.y + 0.5 ..";1,1;back;back]"
	end,
	receiver = function(_, villager, sender, fields)
		local sender_name = sender:get_player_name()
		if fields.back then
			forms.show_formspec(villager, "working_villages:inv_gui", sender_name)
			return
		end
	end
})

local function floor_pos(pos)
	pos.x = math.floor(pos.x)
	pos.y = math.floor(pos.y)
	pos.z = math.floor(pos.z)
	return pos
end
local function load_pos(pos, villager, nodes)
	if (pos=="near") then
		pos = minetest.find_node_near(villager.object:get_pos(), 5, nodes, true) or nil
	elseif (pos~="") then
		pos = minetest.string_to_pos(pos)
		if pos then
			pos = minetest.find_node_near(pos, 0.2, nodes, true) or nil
		end
	else
		pos = nil
	end
	return pos
end
local function soft_table_update(table_old, table_new)
	for k,v in pairs(table_new) do
		if type(v)=="table" then
			if table_old[k] then
				soft_table_update(table_old[k], table_new[k])
			else
				table_old[k] = v
			end
		else
			table_old[k] = v
		end
	end
	for k,_ in pairs(table_old) do
		if not table_new[k] then
			table_old[k] = nil
		end
	end
end

local function set_villager_home(sender_name, villager, marker_pos)
	if not (marker_pos.x and marker_pos.y and marker_pos.z) then
		-- fail on illegal input of coordinates
		minetest.chat_send_player(sender_name, 'You failed to provide correct coordinates for the home position. '..
			'Please enter the X, Y, and Z coordinates of the desired destination in a comma seperated list. '..
			'Example: The input "10,20,30" means the destination at the coordinates X=10, Y=20 and Z=30.')
		return
	end
	if(marker_pos.x>30927 or marker_pos.x<-30912 or marker_pos.y>30927 or marker_pos.y<-30912 or marker_pos.z>30927 or marker_pos.z<-30912) then
		minetest.chat_send_player(sender_name, "The coordinates of your home position "..
			"do not exist in our coordinate system. Correct coordinates range from -30912 to 30927 in all axes.")
		return
	end
	if minetest.get_node(marker_pos).name ~= "working_villages:building_marker" then
		minetest.chat_send_player(sender_name, 'No home marker could be found at the entered position.')
		return
	end

	villager:set_home(marker_pos)
	minetest.chat_send_player(sender_name, 'Home marker set!')
	if minetest.get_meta(marker_pos):get_string("valid") == "false" then
		minetest.chat_send_player(sender_name, 'Home marker not configured, '..
			'please right-click the home marker to configure it.')
	end
end

local change_index = 0

forms.register_page("working_villages:data_change",{
	constructor = function(_, villager, player_name) --self, villager, playername
		-- villager data
		local data = villager.pos_data
		-- references
		local villager_pos = minetest.pos_to_string(floor_pos(villager.object:get_pos()))
		local player = minetest.get_player_by_name(player_name)
		local player_pos = villager_pos
		if player then
			player_pos = minetest.pos_to_string(floor_pos(player:get_pos()))
		end
		-- type set
		local marker_pos = ""
		if villager:has_home() then
			local home = villager:get_home()
			marker_pos = minetest.pos_to_string(floor_pos(home:get_marker()))
		end
		local villager_name = ""
		local villager_name_label = ""
		if villager.nametag and villager.nametag~="" then
			villager_name = villager.nametag
			villager_name_label = "label[0,0;"..villager.nametag.."]"
		end
		local village_name = ""
		if villager.village_name then
			village_name = villager.village_name
		end
		-- villager positions
		local home_pos = ""
		if (data.home_pos~=nil) then
			home_pos = minetest.pos_to_string(data.home_pos)
		end
		local bed_pos = ""
		if (data.bed_pos~=nil) then
			bed_pos = minetest.pos_to_string(data.bed_pos)
		end
		local chest_pos = ""
		if (data.chest_pos~=nil) then
			chest_pos = minetest.pos_to_string(data.chest_pos)
		end
		-- village positions
		local food_pos = ""
		if (data.food_pos~=nil) then
			food_pos = minetest.pos_to_string(data.food_pos)
		end
		local tools_pos = ""
		if (data.tools_pos~=nil) then
			tools_pos = minetest.pos_to_string(data.tools_pos)
		end
		local storage_pos = ""
		if (data.storage_pos~=nil) then
			storage_pos = minetest.pos_to_string(data.storage_pos)
		end
		-- job positon
		local job_pos = ""
		if (data.job_pos~=nil) then
			job_pos = minetest.pos_to_string(data.job_pos)
		end

		local cp = { x = 3.5, y = 0 }
		local hp = { x = 0.5, y = 2.5 }
		local wp = { x = 0.5, y = 3.5 }
		local jp = { x = 0.5, y = 4.5 }
		local bp = { x = 3.5, y = 6 }
		change_index = change_index + 1
		return "size[8,7]"
			.. default.gui_bg
			.. default.gui_bg_img
			.. default.gui_slots
			.. villager_name_label
			.. "label[".. cp.x - 0.5 ..",".. cp.y-0.1 ..";current villager data]"
			.. "label[-1,-1;"..change_index.."]"
			.. "field[" .. cp.x-3 .. "," .. cp.y + 0.9 ..";2.5,1;villager_pos;villager position;" .. player_pos .. "]"
			.. "field[" .. cp.x+2 .. "," .. cp.y + 0.9 ..";2.5,1;player_pos;player position;" .. villager_pos .. "]"
			.. "field[" .. cp.x-3 .. "," .. cp.y + 1.9 ..";2.5,1;marker_pos;building marker pos;" .. marker_pos .. "]"
			.. "field[" .. cp.x-0.5 .. "," .. cp.y + 1.9 ..";2.5,1;villager_name;villager name;" .. villager_name .. "]"
			.. "field[" .. cp.x+2 .. "," .. cp.y + 1.9 ..";2.5,1;village_name;village name;" .. village_name .. "]"
			.. "field[" .. hp.x .. "," .. hp.y + 0.4 ..";2.5,1;home_pos;house door position;" .. home_pos .. "]"
      .. "tooltip[home_pos;Use \"near\" to find nearest door (from villager up to 5 nodes).]"
			.. "field[" .. hp.x+2.5 .. "," .. hp.y + 0.4 ..";2.5,1;bed_pos;bed position;" .. bed_pos .. "]"
      .. "tooltip[bed_pos;Use \"near\" to find nearest bed (from villager up to 5 nodes).]"
			.. "field[" .. hp.x+5 .. "," .. hp.y + 0.4 ..";2.5,1;chest_pos;chest position;" .. chest_pos .. "]"
      .. "tooltip[chest_pos;Use \"near\" to find nearest chest (from villager up to 5 nodes).]"
			.. "field[" .. wp.x .. "," .. wp.y + 0.4 ..";2.5,1;food_pos;food position;" .. food_pos .. "]"
      .. "tooltip[food_pos;Use \"near\" to find nearest chest (from villager up to 5 nodes).]"
			.. "field[" .. wp.x+2.5 .. "," .. wp.y + 0.4 ..";2.5,1;tools_pos;tools position;" .. tools_pos .. "]"
      .. "tooltip[tools_pos;Use \"near\" to find nearest chest (from villager up to 5 nodes).]"
			.. "field[" .. wp.x+5 .. "," .. wp.y + 0.4 ..";2.5,1;storage_pos;storage position;" .. storage_pos .. "]"
      .. "tooltip[storage_pos;Use \"near\" to find nearest chest (from villager up to 5 nodes).]"
			.. "field[" .. jp.x .. "," .. jp.y + 0.4 ..";2.5,1;job_pos;job position;" .. job_pos .. "]"
			.. "button[3,".. bp.y + 0.5 ..";1,1;set_data;set]"
			.. "button[6,".. bp.y + 0.5 ..";1,1;back;back]"
	end,
	--receiver = function(page, villager, sender, fields)
	receiver = function(_, villager, sender, fields)
		local sender_name = sender:get_player_name()
		if fields.set_data then
			local data = {}
			local marker_pos = load_pos(fields.marker_pos, villager, "working_villages:building_marker")
			--data.home_pos = load_pos(fields.home_pos, villager, "group:door")
			data.home_pos = load_pos(fields.home_pos, villager, "group:villager_door")
			data.bed_pos = load_pos(fields.bed_pos, villager, "group:villager_bed_bottom")
			data.chest_pos = load_pos(fields.chest_pos, villager, "group:villager_chest")
			data.food_pos = load_pos(fields.food_pos, villager, "group:villager_chest")
			data.tools_pos = load_pos(fields.tools_pos, villager, "group:villager_chest")
			data.storage_pos = load_pos(fields.storage_pos, villager, "group:villager_chest")
			if fields.job_pos then
				data.job_pos = minetest.string_to_pos(fields.job_pos)
			end

			-- soft update have to be done here, do not break pointers
			soft_table_update(villager.pos_data, data)
			-- marked pos update
			if marker_pos then
				local home = villager:get_home()
				if (not home) or (not vector.equals(home:get_marker(), marker_pos)) then
					set_villager_home(sender_name, villager, marker_pos)
				end
			else
				if villager:has_home() then
					villager:remove_home()
				end
			end
			-- villager name update
			if fields.villager_name ~= villager.nametag then
				villager.nametag = fields.villager_name
				villager.object:set_nametag_attributes({
						text = villager.nametag
					})
			end
			-- village connect update
			if fields.village_name ~= villager.village_name then
				villager.village_name = fields.village_name
				-- TODO: Add some connection data update function here?
			end
			forms.show_formspec(villager, "working_villages:data_change", sender_name)
		end
		if fields.back then
			forms.show_formspec(villager, "working_villages:inv_gui", sender_name)
			return
		end
	end
})

forms.register_page("working_villages:inv_gui", {
	constructor = function(_, villager) --self, villager, playername
		-- job name
		local jobname = villager:get_job()
		if jobname then
			jobname = jobname.description
		else
			jobname = "no job"
		end
		local wp = { x = 4.25, y = 0.5}
		local hp = { x = 4.0, y = 3.5}
		local villager_name = ""
		if villager.nametag and villager.nametag~="" then
			villager_name = "label[0,0;"..villager.nametag.."]"
		end
		return "size[8,9]"
			.. default.gui_bg
			.. default.gui_bg_img
			.. default.gui_slots
			.. villager_name
			.. "list[detached:"..villager.inventory_name..";main;0,0.5;4,4;]"
			.. "list[current_player;main;0,5;8,1;]"
			.. "list[current_player;main;0,6.2;8,3;8]"
			.. "listring[detached:"..villager.inventory_name..";main]"
			.. "listring[current_player;main]"
			.. "label[" .. wp.x + 0.1 .."," .. wp.y .. ";wield]"
			.. "list[detached:"..villager.inventory_name..";wield_item;" .. wp.x .. "," .. wp.y + 0.5 ..";1,1;]"
			.. "button[5.5,1.2;2,1;job;change job]"
			.. "label[4,2;current job:\n"..jobname.."]"
			.. "button[5.5,2.8;2,1;data;change data]"
			--.. "field[" .. jp.x .. "," .. jp.y + 0.4 ..";2.5,1;job_pos;job position;" .. job_pos .. "]"
			--.. "field[" .. hp.x .. "," .. hp.y + 0.4 ..";2.5,1;home_pos;home position;" .. home_pos .. "]"
			.. "button_exit[" .. hp.x + 2 .. "," .. hp.y + 0.09 .. ";1,1;ok;close]"
	end,
	receiver = function(_, villager, sender, fields)
		local sender_name = sender:get_player_name()
		if fields.job then
			forms.show_formspec(villager, "working_villages:job_change", sender_name)
			return
		end
		if fields.data then
			forms.show_formspec(villager, "working_villages:data_change", sender_name)
			return
		end
	end,
})

--TODO: see if working_villages.registered_forms should really be public
working_villages.regisered_forms = registered_forms

return forms
