working_villages.forms = {}
working_villages.registered_forms = {}

function working_villages.forms.register_page(name, def)
	if working_villages.registered_forms[name]~=nil then
		minetest.log("warning", "overwriting formspec page "..name)
	end
	assert(type(def.constructor)=="function")
	if def.receiver then assert(type(def.receiver)=="function") end
	working_villages.registered_forms[name] = def
end

function working_villages.forms.show_formspec(self, formname, playername)
	local home_pos = {x = 0, y = 0, z = 0}
	if self:has_home() then
		home_pos = self:get_home():get_marker()
	end
	home_pos = minetest.pos_to_string(home_pos)
	local page = working_villages.registered_forms[formname]
	if page == nil then
		minetest.log("warning", "page not registered")
		page = working_villages.registered_forms["working_villages:talking_menu"]
	end
	minetest.show_formspec(playername, formname.."_"..self.inventory_name, page.constructor(self, playername))
end

--receive fields when villager was rightclicked

minetest.register_on_player_receive_fields(
	function(player, formname, fields)
		for n,p in pairs(working_villages.registered_forms) do
			if string.find(formname, n.."_")==1 then
				if p.receiver then
					local inv_name = string.sub(formname, string.len(n.."_")+1)
					p.receiver(inv_name,player,fields)
				end
			end
		end
	end
)

working_villages.forms.register_page("working_villages:talking_menu", {
	constructor = function(self, playername)
		local jobname = self:get_job()
		if jobname then
			jobname = jobname.description
		else
			jobname = "no job"
		end
		return "size[8,9]"
			.. default.gui_bg
			.. default.gui_bg_img
			.. default.gui_slots
			.. "label[0,0;"..jobname.."]"
			.. "label[3.5,2;hello]" --TODO: menu here (buttons like in doc)
			.. "button_exit[3.5,8;1,1;exit;bye]"
	end,
	receiver = function(inv_name, sender, fields)
		local sender_name = sender:get_player_name()
		minetest.log("info",inv_name)
		minetest.log("info",sender_name)
		--TODO: event handling for menu
	end,
})

working_villages.forms.register_page("working_villages:inv_gui", {
	constructor = function(self, playername)
		local home_pos = {x = 0, y = 0, z = 0}
		if self:has_home() then
			home_pos = self:get_home():get_marker()
		end
		home_pos = minetest.pos_to_string(home_pos)
		return "size[8,9]"
			.. default.gui_bg
			.. default.gui_bg_img
			.. default.gui_slots
			.. "list[detached:"..self.inventory_name..";main;0,0;4,4;]"
			.. "label[4.5,1;job]"
			.. "list[detached:"..self.inventory_name..";job;4.5,1.5;1,1;]"
			.. "list[current_player;main;0,5;8,1;]"
			.. "list[current_player;main;0,6.2;8,3;8]"
			.. "label[5.5,1;wield]"
			.. "list[detached:"..self.inventory_name..";wield_item;5.5,1.5;1,1;]"
			.. "field[4.5,3;2.5,1;home_pos;home position;" .. home_pos .. "]"
			.. "button_exit[7,3;1,1;ok;set]"
	end,
	receiver = function(inv_name, sender, fields)
		local sender_name = sender:get_player_name()
		if fields.home_pos == nil then
			return
		end
		local coords = minetest.string_to_pos(fields.home_pos)
		if not (coords.x and coords.y and coords.z) then
			-- fail on illegal input of coordinates
			minetest.chat_send_player(sender_name, 'You failed to provide correct coordinates for the home position. '..
				'Please enter the X, Y, and Z coordinates of the desired destination in a comma seperated list. '..
				'Example: The input "10,20,30" means the destination at the coordinates X=10, Y=20 and Z=30.')
			return
		end
		if(coords.x>30927 or coords.x<-30912 or coords.y>30927 or coords.y<-30912 or coords.z>30927 or coords.z<-30912) then
			minetest.chat_send_player(sender_name, "The coordinates of your home position "..
				"do not exist in our coordinate system. Correct coordinates range from -30912 to 30927 in all axes.")
			return
		end
		if minetest.get_node(coords).name ~= "working_villages:home_marker" then
			minetest.chat_send_player(sender_name, 'No home marker could be found at the entered position.')
			return
		end

		working_villages.set_home(inv_name,coords)
		minetest.chat_send_player(sender_name, 'Home set!')
		if not minetest.get_meta(coords):get_string("bed") then
			minetest.chat_send_player(sender_name, 'Home marker not configured, '..
				'please right-click the home marker to configure it.')
		end
	end,
})