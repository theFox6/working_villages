working_villages.forms = {}
working_villages.registered_forms = {}

working_villages.forms.villagers = {}
function working_villages.forms.get_villager(inv_name)
	return working_villages.forms.villagers[inv_name]
end

function working_villages.forms.register_page(name, def)
	if working_villages.registered_forms[name]~=nil then
		working_villages.log.warning(false, "overwriting formspec page %s",name)
	end
	assert(type(def.constructor)=="function")
	if def.receiver then assert(type(def.receiver)=="function") end
	working_villages.registered_forms[name] = def
end

function working_villages.forms.show_formspec(self, formname, playername)
	local page = working_villages.registered_forms[formname]
	if page == nil then
		working_villages.log.warning(false, "page %s not registered", formname)
		page = working_villages.registered_forms["working_villages:talking_menu"]
	end
	minetest.show_formspec(playername, formname.."_"..self.inventory_name, page.constructor(self, playername))
	working_villages.forms.villagers[self.inventory_name] = self
end

--receive fields when villager was rightclicked

minetest.register_on_player_receive_fields(
	function(player, formname, fields)
		for n,p in pairs(working_villages.registered_forms) do
			if string.find(formname, n.."_")==1 then
				if p.receiver then
					local inv_name = string.sub(formname, string.len(n.."_")+1)
					p.receiver(working_villages.forms.get_villager(inv_name),player,fields)
				end
			end
		end
	end
)

working_villages.forms.register_page("working_villages:talking_menu", {
	constructor = function(self) --self, playername
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
	receiver = function(self, sender, fields)
		local sender_name = sender:get_player_name()
		minetest.log("info",self.inventory_name)
		minetest.log("info",sender_name)
		minetest.log("info",dump(fields))
		--TODO: event handling for menu
	end,
})

working_villages.forms.register_page("working_villages:job_change",{
	constructor = function(self) --self, playername
		local cp = { x = 3.5, y = 0 }
		return "size[8,6]"
			.. default.gui_bg
			.. default.gui_bg_img
			.. default.gui_slots
			.. "label[".. cp.x - 0.25 ..",".. cp.y ..";current job]"
			.. "list[detached:".. self.inventory_name ..";job;".. cp.x ..",".. cp.y + 0.5 ..";1,1;]"
			.. "list[detached:working_villages:job_inv;main;0,2;8,4;]"
			.. "listring[]"
			.. "button[6,".. cp.y + 0.5 ..";1,1;back;back]"
	end,
	receiver = function(self, sender, fields)
		local sender_name = sender:get_player_name()
		if fields.back then
			working_villages.forms.show_formspec(self, "working_villages:inv_gui", sender_name)
			return
		end
	end
})

working_villages.forms.register_page("working_villages:inv_gui", {
	constructor = function(self) --self, playername
		local home_pos = {x = 0, y = 0, z = 0}
		if self:has_home() then
			home_pos = self:get_home():get_marker()
		end
		home_pos = minetest.pos_to_string(home_pos)
		local jobname = self:get_job()
		if jobname then
			jobname = jobname.description
		else
			jobname = "no job"
		end
		local wp = { x = 4.25, y = 0}
		local hp = { x = 4.3, y = 3}
		return "size[8,9]"
			.. default.gui_bg
			.. default.gui_bg_img
			.. default.gui_slots
			.. "list[detached:"..self.inventory_name..";main;0,0;4,4;]"
			.. "list[current_player;main;0,5;8,1;]"
			.. "list[current_player;main;0,6.2;8,3;8]"
			.. "listring[detached:"..self.inventory_name..";main]"
			.. "listring[current_player;main]"
			.. "label[" .. wp.x + 0.1 .."," .. wp.y .. ";wield]"
			.. "list[detached:"..self.inventory_name..";wield_item;" .. wp.x .. "," .. wp.y + 0.5 ..";1,1;]"
			.. "button[5.5,0.7;2,1;job;change job]"
			.. "label[4,1.5;current job:\n"..jobname.."]"
			.. "field[" .. hp.x .. "," .. hp.y + 0.4 ..";2.5,1;home_pos;home position;" .. home_pos .. "]"
			.. "button_exit[" .. hp.x + 2 .. "," .. hp.y + 0.09 .. ";1,1;ok;set]"
	end,
	receiver = function(self, sender, fields)
		local sender_name = sender:get_player_name()
		if fields.job then
			working_villages.forms.show_formspec(self, "working_villages:job_change", sender_name)
			return
		end
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
		if minetest.get_node(coords).name ~= "working_villages:building_marker" then
			minetest.chat_send_player(sender_name, 'No home marker could be found at the entered position.')
			return
		end

		working_villages.set_home(self.inventory_name,coords)
		minetest.chat_send_player(sender_name, 'Home set!')
		if minetest.get_meta(coords):get_string("valid") == "false" then
			minetest.chat_send_player(sender_name, 'Home marker not configured, '..
				'please right-click the home marker to configure it.')
		end
	end,
})