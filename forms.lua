working_villages.forms = {}

-- create_inv_formspec_string returns a string that represents a formspec definition.
function working_villages.forms.create_inv_formspec_string(self)
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
end

-- create_talking_formspec_string returns a string that represents a formspec definition.
function working_villages.forms.create_talking_formspec_string(self)
	return "size[8,9]"
		.. default.gui_bg
		.. default.gui_bg_img
		.. default.gui_slots
		.. "label[0,0;".. self:get_job().description.."]"
		.. "label[3.5,2;hello]"
		.. "button_exit[3.5,8;1,1;exit;bye]"
end