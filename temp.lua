minetest.register_on_player_receive_fields(
	function(player, formname, fields)
		if string.find(formname,"villager:gui") then
			local sender_name = player:get_player_name();
			if fields.home_pos == nil then
				return
			end
			local coords = {}
			coords.x, coords.y, coords.z = string.match(fields.bed_pos, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
			coords.x=tonumber(coords.x)
			coords.y=tonumber(coords.y)
			coords.z=tonumber(coords.z)
			if not (coords.x and coords.y and coords.z) then
				-- fail on illegal input of coordinates
				minetest.chat_send_player(sender_name, 'You failed to provide correct coordinates for the bed position. Please enter the X, Y, and Z coordinates of the desired destination in a comma seperated list. Example: The input "10,20,30" means the destination at the coordinates X=10, Y=20 and Z=30.')
				return
			end
			if(coords.x>30927 or coords.x<-30912 or coords.y>30927 or coords.y<-30912 or coords.z>30927 or coords.z<-30912) then
				minetest.chat_send_player(sender_name, 'The coordinates of your bed position do not exist in our coordinate system. Correct coordinates range from -30912 to 30927 in all axes.')
				return
			end
			if minetest.get_node(coords).name ~= "working_villages:home_marker"
				minetest.chat_send_player(sender_name, 'No home marker could be found at the entered position.')
				return
			end
			if not minetest.get_meta(coords):get_string("bed") then
				minetest.chat_send_player(sender_name, 'Home marker not configured, please right-click the home marker to configure it.')
				return
			end
			self.home_pos=coords
		end
	end
)