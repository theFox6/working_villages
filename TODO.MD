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




nomads
- jumpdrive
- flying ships
- on move node aware nodes => throne for mayor => mods can use the API or players can use the node

some appliances don't set a facedir, requiring specific facings for the huts

appliance-handling bots' find_node() methods should find all nodes and distinguish between active/inactive nodes
so e.g., composter, wafflemaker, etc., can juggle multiple appliances



night shift





* realism
  * villagers experience hunger, stamina and other effects
  * villagers use tools, integrated with tool ranks
  * drop inv, bones on death
* more realism
  * integration with getname
  * mobs_redo-like offspring and lineage-tracking
  * => randomly generated stories
  * generation of histories & other heirlooms
  * => randomly generated villages with high rank items with cool backstories
* more jobs
  * blacksmith: repairs tools
  * craftsmen:  higher level crafts needed for builder, salesmen and military
    * build on a single craftsman AI, but limited to certain recipes for simplying automation
      => mineables go to the mason
      => choppables go to the carpenter
      this will help regulate how much of each material goes to each recipe,
      which make it easier to build a pipeline from raw resources to an overpriced retail front
      combined with toolranks and tool repair, we might be able to make products worth buying
* clothing, armor, upgrades
  * I think the mods add inv lists to the player for these, so likewise can be done to the villagers
* starfleet
  * need some way for flyingships-like mods to notify villagers that all their location data just got teleported

* expose job functions to create meta-jobs that switch between jobs, eg
  * for a pioneer AI that finds a good spot, inits the area, and switches to mayor tasks)
  * for a manager-type that can jump in to help team members
* maybe make a recipe to convert other mod's building signs to ours and vice-versa
* egg-registering integration


## implemented Features
no crafting recipes yet (you will have to use creative)
features:
* building markers
  * for building houses and saving the houses details
  * save the position of the door and the bed
  * some jobs will let the villagers return home at night
  * at home the villagers will go to bed



catching-throwing game
chooglee
