function building:load_build_pos(meta)
	local pos = minetest.string_to_pos(meta:get_string("build_pos"))
	if pos then
		self.build_pos = pos
		return pos
	end
end
