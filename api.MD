I started using the maidroid api, but by now it's a lot different.
for specific documentation look for the comments in the (api.lua)

To register a new job you use:
```

working_villages.register_job("[itemstring for the job item]", {
	description      = "[description for the job item]",
	inventory_image  = "[texture for the job item]",
	jobfunc = "[coroutine that is called every step]",
})
```

for examples look at the testing jobs