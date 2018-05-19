function working_villages.villager:go_to(pos)
	self.destination = pos
	self:set_state("goto_dest")
	coroutine.yield()
end

function working_villages.villager:dig(pos)
	self.target = pos
	self:set_state("dig_target")
	coroutine.yield()
end

function working_villages.villager:place(itemname,pos)
	local wield_stack = self:get_wield_item_stack()
	if (wield_stack:get_name() == itemname or self:move_main_to_wield(function (name) return name == itemname end)) then
		self.target = pos
		self:set_state("place_wield")
		coroutine.yield()
	else
		minetest.chat_send_player(self.owner_name,"villager couldn't place ".. itemname)
	end
end