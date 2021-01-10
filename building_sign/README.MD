# minetest mod building sign
yet another area protection and shematic handling mod
this aims to be more realistic than preventing useres from digging
it will protect an area just by remembering who did what to a building
also it remembers the blueprint of house using shematics

## features
* building shematics are remembered by the building sign
  * schematics can be chosen with the building sign
* doesn't keep building data in blockmeta (removal safety)

## planned features
* allow mods and users to add schematics
* difference in blocks to the schematic can be shown
  * block list with positions can be shown
  * differences can be overwritten
  * can save shematics
* shematic versioning and upgrade support
  * save shematics as <name>_lvl<upgrade level>_v<version number>.we
* custom schematics can be saved to the world folder
  * can be reused in that world
* supports shematic rotation (see worldedit, remember to change the param2)
* area around the house is remembered by the building sign
* area around the house can be marked+saved with 4 fence nodes in the edges
* marking areas
  1. asks for the height of the building sign above the ground
  2. looks and asks for the fence pieces in the edges
  3. asks for the height and depth of the area
* tracks what payers or entities do in the area as events
  * place, dig, rightclick, chest contents, entering/leaving the area
* notifies the owner if he s nearby if changes happened that were not by the owner
* shows event list in the forms
  * owners events can be filtered out
* command to show previous existing houses of an owner
* if sign is placed in the area of a previous house it can restore the data
* support multiple building markers for one area (new marker links up with others if placed in an area)
* (dismissed) allow mods to specify schemlist for a sign

## license
* working_villages by theFox6 is avalible under the MIT License

Exceptions to the above:
* the sign textures are from the default mod in minetest_game and from Gambit: CC BY-SA 3.0
