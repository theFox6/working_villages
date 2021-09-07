working_villages.require("jobs/plant_collector")

local herb_names = {}
for name,_ in pairs(working_villages.herbs.names) do
    herb_names[#herb_names + 1] = name
end
for name,_ in pairs(working_villages.herbs.groups) do
    herb_names[#herb_names + 1] = "group:"..name
end

local function spawn(pos, node, active_object_count, active_object_count_wider)
    minetest.log("action", "Active objects "..active_object_count_wider)
    if active_object_count_wider > 2 then return end
        local pos1 = {x=pos.x-4,y=pos.y-8,z=pos.z-4}
        local pos2 = {x=pos.x+4,y=pos.y+1,z=pos.z+4}
    local spawn_pos
    minetest.log("action", "Search from "..minetest.pos_to_string(pos1,0).." to "..minetest.pos_to_string(pos2,0))
    for _,pos in ipairs(minetest.find_nodes_in_area_under_air(
            pos1,pos2,"group:soil")) do
        minetest.log("action", "Considering "..minetest.pos_to_string(pos,0))
        local above = minetest.get_node({x=pos.x,y=pos.y+2,z=pos.z})
        local above_def = minetest.registered_nodes[above.name] 
        if above_def and not above_def.groups.walkable then
            local gender = {
                "working_villages:villager_male",
                "working_villages:villager_female",
            }
            local self = minetest.add_entity(
                {x=pos.x,y=pos.y+1,z=pos.z},gender[math.random(2)], ""
            )
            local inv = self:get_inventory()
            minetest.log("action", "Making "..dump(self).." with inventory "..dump(inv))
            if not inv then return end
            local job = working_villages.job_inv:remove_item(
                "main","working_villages:job_herbcollector"
            ) 
            inv:set_stack("job", 1, job)
            minetest.log("action", "working_villages spawned at "..minetest.pos_to_string(pos,0))
            return
        end
    end
end

minetest.register_abm({
    label = "Spawn herb collector",
    nodenames = herb_names,
    neighbors = "air",
    interval = 18,
    chance = 100,
    catch_up = false,
    action = spawn,
})
