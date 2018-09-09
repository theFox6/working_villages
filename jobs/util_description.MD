working_villages.func is a table with several functions:

`function working_villages.func.validate_pos(pos)`
returns the position rounded, if it is a slab/stair the position on top is given
for getting the position of the villager for pathfinding

`function working_villages.func.search_surrounding(pos, pred, searching_range)`
calls `pred(pos)` for every node within searching_range of pos
if `searching_range.h` is given the searching range will start h above pos
if `pred(pos)` returns true it will return the position
if `pred(pos)` doesn't return true at all nil will be returned

`function working_villages.func.find_adjacent_pos(pos,pred)`
calls `pred(pos)` for every node next to pos and for pos itself
if `pred(pos)` returns true it will return the position
if `pred(pos)` doesn't return true at all false will be returned
