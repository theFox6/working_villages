minetest.register_tool("working_villages:commanding_sceptre", {
	description = "villager commanding sceptre",
	inventory_image = "working_villages_commanding_sceptre.png",
	on_use = function(itemstack, user, pointed_thing)
		if (pointed_thing.type == "object") then
			local obj = pointed_thing.ref
			local luaentity = obj:get_luaentity()
			if not working_villages.is_villager(luaentity.name) then
				if luaentity.name == "__builtin:item" then
					luaentity:on_punch(user)
				end
				return
			end

			local job = luaentity:get_job()
			if job ~= nil then
				if luaentity.pause == "active" or luaentity.pause == "sleeping" then
					luaentity.pause = "resting"
					job.on_pause(luaentity)
					luaentity:update_infotext()
				elseif luaentity.pause == "resting" then
					luaentity.pause = "active"
					job.on_resume(luaentity)
					luaentity:update_infotext()
				else
					minetest.log("warning","unknown pause state: "..self.pause)
				end
			end

			return itemstack
		end
	end
})
