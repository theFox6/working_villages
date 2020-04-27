local u = working_villages.require("util")

minetest.register_tool("working_villages:neighbor_test_tool", {
  description = "neighbor test tool\nplaces wood in euclidean distance",
  inventory_image = "working_villages_commanding_sceptre.png",
  on_use = function(itemstack, user, pointed_thing)
    local pos = vector.round(pointed_thing.above)
    pos.y = pos.y + 5
    for _,n in pairs(u.get_eneigbor_offsets(3)) do
      minetest.place_node(vector.add(pos,n),{name = "default:wood"})
    end
  end,
})
