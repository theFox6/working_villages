function working_villages.villager:goto(pos)
	self.destination = pos
	self:set_state("goto_dest")
	coroutine.yield()
end

function working_villages.villager:dig(pos)
	self.target = pos
	self:set_state("dig_target")
	coroutine.yield()
end