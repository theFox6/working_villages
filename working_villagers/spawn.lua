local func = working_villages.require("jobs/util")
local log = working_villages.require("log")

local function spawner(initial_job)
    return function(pos, _, _, active_object_count_wider)
               --  (pos, node, active_object_count, active_object_count_wider)
        if active_object_count_wider > 1 then return end
        if func.is_protected_owner("working_villages:self_employed",pos) then
            return
        end

        local pos1 = {x=pos.x-4,y=pos.y-8,z=pos.z-4}
        local pos2 = {x=pos.x+4,y=pos.y+1,z=pos.z+4}
        for _,p in ipairs(minetest.find_nodes_in_area_under_air(
                pos1,pos2,"group:soil")) do
            local above = minetest.get_node({x=p.x,y=p.y+2,z=p.z})
            local above_def = minetest.registered_nodes[above.name]
            if above_def and not above_def.groups.walkable then
                log.action("Spawning a %s at %s", initial_job, minetest.pos_to_string(p,0))
                local gender = {
                    "working_villages:villager_male",
                    "working_villages:villager_female",
                }
                local new_villager = minetest.add_entity(
                    {x=p.x,y=p.y+1,z=p.z},gender[math.random(2)], ""
                )
                local entity = new_villager:get_luaentity()
                entity.new_job = initial_job
                entity.owner_name = "working_villages:self_employed"
                entity:update_infotext()
                return
            end
        end
    end
end

working_villages.require("jobs/plant_collector")

local herb_names = {}
for name,_ in pairs(working_villages.herbs.names) do
    herb_names[#herb_names + 1] = name
end
for name,_ in pairs(working_villages.herbs.groups) do
    herb_names[#herb_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn herb collector",
    nodenames = herb_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_herbcollector"),
})

minetest.register_abm({
    label = "Spawn woodcutter",
    nodenames = "group:tree",
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_woodcutter"),
})


working_villages.require("jobs/brush_collector")

local shrub_names = {}
for name,_ in pairs(working_villages.shrubs.names) do
    shrub_names[#shrub_names + 1] = name
end
for name,_ in pairs(working_villages.shrubs.groups) do
    shrub_names[#shrub_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn brush collector",
    nodenames = shrub_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_brushcollector"),
})

working_villages.require("jobs/bug_collector")

local bug_names = {}
for name,_ in pairs(working_villages.bugs.names) do
    bug_names[#bug_names + 1] = name
end
for name,_ in pairs(working_villages.bugs.groups) do
    bug_names[#bug_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn bug collector",
    nodenames = bug_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_bugcollector"),
})

working_villages.require("jobs/bone_collector")

local bone_names = {}
for name,_ in pairs(working_villages.bones.names) do
    bone_names[#bone_names + 1] = name
end
for name,_ in pairs(working_villages.bones.groups) do
    bone_names[#bone_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn bone collector",
    nodenames = bone_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_bonecollector"),
})

working_villages.require("jobs/landscaper")

local dirt_names = {}
for name,_ in pairs(working_villages.dirts.names) do
    dirt_names[#dirt_names + 1] = name
end
for name,_ in pairs(working_villages.dirts.groups) do
    dirt_names[#dirt_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn landscaper",
    nodenames = dirt_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_landscaper"),
})

working_villages.require("jobs/watercarrier")

local liquid_names = {}
for name,_ in pairs(working_villages.liquids.names) do
    liquid_names[#liquid_names + 1] = name
end
for name,_ in pairs(working_villages.liquids.groups) do
    liquid_names[#liquid_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn water carrier",
    nodenames = liquid_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_watercarrier"),
})

working_villages.require("jobs/miner")

local stone_names = {}
for name,_ in pairs(working_villages.stones.names) do
    stone_names[#stone_names + 1] = name
end
for name,_ in pairs(working_villages.stones.groups) do
    stone_names[#stone_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn miner",
    nodenames = stone_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_miner"),
})

working_villages.require("jobs/gem_miner")

local gem_names = {}
for name,_ in pairs(working_villages.gems.names) do
    gem_names[#gem_names + 1] = name
end
for name,_ in pairs(working_villages.gems.groups) do
    gem_names[#gem_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn gem miner",
    nodenames = gem_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_gem_miner"),
})

working_villages.require("jobs/mayor")

-- don't be rowdy
--local throne_names = {}
--for name,_ in pairs(working_villages.thrones.names) do
--    throne_names[#throne_names + 1] = name
--end
--for name,_ in pairs(working_villages.thrones.groups) do
--    throne_names[#throne_names + 1] = "group:"..name
--end
--
--minetest.register_abm({
--    label = "Spawn mayor",
--    nodenames = throne_names,
--    neighbors = "air",
--    interval = 60,
--    chance = 2048,
--    catch_up = false,
--    action = spawner("working_villages:job_mayor"),
--})

working_villages.require("jobs/baker")

local furnace_names = {}
for name,_ in pairs(working_villages.furnaces.names) do
    furnace_names[#furnace_names + 1] = name
end
for name,_ in pairs(working_villages.furnaces.groups) do
    furnace_names[#furnace_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn baker",
    nodenames = furnace_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_baker"),
})

if minetest.get_modpath("mcg_lockworkshop") then
    working_villages.require("jobs/locksmith")
    
    local lockworkshop_names = {}
    for name,_ in pairs(working_villages.lockworkshops.names) do
        lockworkshop_names[#lockworkshop_names + 1] = name
    end
    for name,_ in pairs(working_villages.lockworkshops.groups) do
        lockworkshop_names[#lockworkshop_names + 1] = "group:"..name
    end
    
    minetest.register_abm({
        label = "Spawn locksmith",
        nodenames = lockworkshop_names,
        neighbors = "air",
        interval = 60,
        chance = 2048,
        catch_up = false,
        action = spawner("working_villages:job_locksmith"),
    })
end

if minetest.get_modpath("fakery") then
    working_villages.require("jobs/counterfeiter")

    local fakerytable_names = {}
    for name,_ in pairs(working_villages.fakerytables.names) do
        fakerytable_names[#fakerytable_names + 1] = name
    end
    for name,_ in pairs(working_villages.fakerytables.groups) do
        fakerytable_names[#fakerytable_names + 1] = "group:"..name
    end
    
    minetest.register_abm({
        label = "Spawn counterfeiter",
        nodenames = fakerytable_names,
        neighbors = "air",
        interval = 60,
        chance = 2048,
        catch_up = false,
        action = spawner("working_villages:job_counterfeiter"),
    })
end

if minetest.get_modpath("mcg_dyemixer") then
    working_villages.require("jobs/dyemixer")

    local dyemixer_names = {}
    for name,_ in pairs(working_villages.dyemixers.names) do
        dyemixer_names[#dyemixer_names + 1] = name
    end
    for name,_ in pairs(working_villages.dyemixers.groups) do
        dyemixer_names[#dyemixer_names + 1] = "group:"..name
    end
    
    minetest.register_abm({
        label = "Spawn dyemixer",
        nodenames = dyemixer_names,
        neighbors = "air",
        interval = 60,
        chance = 2048,
        catch_up = false,
        action = spawner("working_villages:job_dyemixer"),
    })
end

if minetest.get_modpath("claycrafter") then
    working_villages.require("jobs/claycrafter")

    local claycrafter_names = {}
    for name,_ in pairs(working_villages.claycrafters.names) do
        claycrafter_names[#claycrafter_names + 1] = name
    end
    for name,_ in pairs(working_villages.claycrafters.groups) do
        claycrafter_names[#claycrafter_names + 1] = "group:"..name
    end
    
    minetest.register_abm({
        label = "Spawn claycrafter",
        nodenames = claycrafter_names,
        neighbors = "air",
        interval = 60,
        chance = 2048,
        catch_up = false,
        action = spawner("working_villages:job_claycrafter"),
    })
end

if minetest.get_modpath("decraft") then
    working_villages.require("jobs/recycler")

    local recycler_names = {}
    for name,_ in pairs(working_villages.recyclers.names) do
        recycler_names[#recycler_names + 1] = name
    end
    for name,_ in pairs(working_villages.recyclers.groups) do
        recycler_names[#recycler_names + 1] = "group:"..name
    end
    
    minetest.register_abm({
        label = "Spawn recycler",
        nodenames = recycler_names,
        neighbors = "air",
        interval = 60,
        chance = 2048,
        catch_up = false,
        action = spawner("working_villages:job_recycler"),
    })
end

if minetest.get_modpath("crafting_bench")
or minetest.get_modpath("craft_table") then
    working_villages.require("jobs/craftsman")

    local craft_table_names = {}
    for name,_ in pairs(working_villages.craft_tables.names) do
        craft_table_names[#craft_table_names + 1] = name
    end
    for name,_ in pairs(working_villages.craft_tables.groups) do
        craft_table_names[#craft_table_names + 1] = "group:"..name
    end
    
    minetest.register_abm({
        label = "Spawn craftsman",
        nodenames = craft_table_names,
        neighbors = "air",
        interval = 60,
        chance = 2048,
        catch_up = false,
        action = spawner("working_villages:job_craftsman"),
    })
end

if minetest.get_modpath("iadiscordia") then
    working_villages.require("jobs/wizard")

    local book_names = {}
    for name,_ in pairs(working_villages.books.names) do
        book_names[#book_names + 1] = name
    end
    for name,_ in pairs(working_villages.books.groups) do
        book_names[#book_names + 1] = "group:"..name
    end
    
    minetest.register_abm({
        label = "Spawn wizard",
        nodenames = book_names,
        neighbors = "air",
        interval = 60,
        chance = 2048,
        catch_up = false,
        action = spawner("working_villages:job_wizard"),
    })
end

working_villages.require("jobs/gardener")

local garden_names = {}
for name,_ in pairs(working_villages.gardening_nodes.names) do
    garden_names[#garden_names + 1] = name
end
for name,_ in pairs(working_villages.gardening_nodes.groups) do
    garden_names[#garden_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn gardener",
    nodenames = garden_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_gardener"),
})

if minetest.get_modpath("biofuel") then
working_villages.require("jobs/biofuel")

local refinery_names = {}
for name,_ in pairs(working_villages.refineries.names) do
    refinery_names[#refinery_names + 1] = name
end
for name,_ in pairs(working_villages.refineries.groups) do
    refinery_names[#refinery_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn biofuel",
    nodenames = refinery_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_biofuel"),
})

if minetest.get_modpath("composting") then
working_villages.require("jobs/composter")

local composter_names = {}
for name,_ in pairs(working_villages.composter_nodes.names) do
    composter_names[#composter_names + 1] = name
end
for name,_ in pairs(working_villages.composter_nodes.groups) do
    composter_names[#composter_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn composter",
    nodenames = composter_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_composter"),
})

if minetest.get_modpath("snowcone") then
working_villages.require("jobs/snowcone")

local fruteria_names = {}
for name,_ in pairs(working_villages.fruteria_nodes.names) do
    fruteria_names[#fruteria_names + 1] = name
end
for name,_ in pairs(working_villages.fruteria_nodes.groups) do
    fruteria_names[#fruteria_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn fruteria",
    nodenames = fruteria_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_snowcone"),
})

if minetest.get_modpath("waffles") then
working_villages.require("jobs/waffle")

local wafflehaus_names = {}
for name,_ in pairs(working_villages.wafflehaus_nodes.names) do
    wafflehaus_names[#wafflehaus_names + 1] = name
end
for name,_ in pairs(working_villages.wafflehaus_nodes.groups) do
    wafflehaus_names[#wafflehaus_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn breakfast",
    nodenames = wafflehaus_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_waffle"),
})

if minetest.get_modpath("church_candles") then
working_villages.require("jobs/beekeeper")

local beehive_names = {}
for name,_ in pairs(working_villages.beehive_nodes.names) do
    beehive_names[#beehive_names + 1] = name
end
for name,_ in pairs(working_villages.beehive_nodes.groups) do
    beehive_names[#beehive_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn beekeeper",
    nodenames = beehive_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_beekeeper"),
})

if minetest.get_modpath("hopper") then
working_villages.require("jobs/trasher")

local hopper_names = {}
for name,_ in pairs(working_villages.hopper_nodes.names) do
    hopper_names[#hopper_names + 1] = name
end
for name,_ in pairs(working_villages.hopper_nodes.groups) do
    hopper_names[#hopper_names + 1] = "group:"..name
end

minetest.register_abm({
    label = "Spawn trasher",
    nodenames = hopper_names,
    neighbors = "air",
    interval = 60,
    chance = 2048,
    catch_up = false,
    action = spawner("working_villages:job_trasher"),
})
