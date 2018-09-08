I started using the maidroid api, but by now it's a lot different.
for specific documentation look for the comments in the (api.lua)

## jobs

To register a new job use:
```lua

working_villages.register_job("[itemstring for the job item]", {
	description      = "[description for the job item]",
	inventory_image  = "[texture for the job item]",
	jobfunc = "[coroutine that is called every step]",
})
```

examples: see testing jobs

## villagers

To register a new villager use:
```lua

working_villages.register_villager([entity name for the villager], {
	hp_max     = [maximum hp],
	weight     = [falling speed of the villager],
	mesh       = [3D mesh of the villager],
	textures   = [texture of the villager],
	egg_image  = [texture of the spawnegg],
})
```

examples: [register.lua](register.lua)