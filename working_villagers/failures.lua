local failures = {
	no_path = "path couldn't be found",
	too_far = "villager is too far away",
	not_in_inventory = "villagers inventory doesn't contain item",
	blocked = "a node blocks the position",
	dig_fail = "dig_node returned false (eg. due to protected location)",
}

working_villages.failures = failures

return failures
