function working_villages.villager:goto(pos)
	self.destination = pos
	self:set_state("goto_dest")
	coroutine.yield()
end