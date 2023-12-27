# my personal TODO notes

-----

- weather
- factory
- useful_contraptions
- journal

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

librarian       -- copy books, etc.
vendor          -- configure vending machines to acquire goods needed by the village
landlord        -- configure rentals to acquire goods needed by the village

- trasher:
  - needs to drop the item now
  - TODO hopper seems to work differently than I remember. I really wanna drop items down a hole
- librarian:
  - need to decide where to keep:
    - unwritten books
    - copies
    - originals
  - otherwise, copying meta is trivial
- landlord
  - needs to properly handle buying/selling
- vendor

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
  - could be used for bonemeal




nomads
- jumpdrive
- flying ships
- on move node aware nodes => throne for mayor => mods can use the API or players can use the node

some appliances don't set a facedir, requiring specific facings for the huts

appliance-handling bots' find_node() methods should find all nodes and distinguish between active/inactive nodes
so e.g., composter, wafflemaker, etc., can juggle multiple appliances



night shift (maybe 1st, 2nd & 3rd shift)
=> butterfly collector & firefly collector
=> day & night guards

digilines in schematics don\'t paste well together. maybe create a job that looks for inconsistent connections in the digilines and replaces the nodes (villagers should already emulate the player\'s placing well enough that this fixes the broken connections)


villagers should check meta when using locked chests/doors/armor stands, etc

some villagers' need to be highly configurable (e.g. the craftsman, the landlord, the vendor, etc.)
or they should otherwise allow their job function to be narrowed down (e.g., the smelter / chef)





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




librarian transcribes meta
