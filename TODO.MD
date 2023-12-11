# my personal TODO notes

-----

burglar/courier -- move stuff between villagers' chests
trash collector -- simple item pickup
blacksmith      -- toolrepair
  => village can produce high level items
excavator       -- digs out a block of the specified size and places walls, floor, ceiling
city planner    -- places building signs for builder

craftsman       -- does preset recipes. combined with the burglar, we should have a functioning pipeline from raw materials to products

logistics,
supply chain,
distribution    -- knows, in general, which supplies and how much are needed by each villager

merchant        -- sets prices based on supply and demand of the village
                   sells goods and services to player

handle deaths
- drop items
- spawn bones with meta

pooping villagers
- villagers eat, set timer, handle_toilet()
- toilets will need to be integrated with a pipe mod
- deliver poop to fuel maker
- make use of bucket mod if no toilet available

skills
- NPCs have skills which can increase in level
=> can pay high level NPCs to do basic tasks


hide & seek  -- for child AIs

hit & run    -- for glass cannon melee
hide & shoot -- based on hider AI, seek cover and shoot player
flanker      -- attacks from opposite direction as another AI
trapper      -- builds obstacles & traps
rangers      -- long range, short range & homing
tank         -- high HP, low damage
healer       -- annoying support role
resurrector  -- respawns dead entities based on bones meta (works with bone collector)
pathmaker    -- makes a path for the gank-squad
demolition   -- explosives expert
captain      -- operates jumpdrive + space cannon TODO build a death star TODO reasonable handling of very large explosions



villager lineage => create a separate mod to track this



schematics
- barracks
- apartments
- guard tower
- traps
- doors, devices & other contraptions
- workshops
- farms & factories
- graveyard (bone collector => (burglar =>) graveyard => resurrector
