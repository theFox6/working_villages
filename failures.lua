working_villages.failures = {
	no_path = "path couldn't be found",
	too_far = "villager is too far away",
	not_in_inventory = "villagers inventory doesn't contain item",
	blocked = "a node blocks the position",
}

--for later support of more detailed failures
function working_villages.failures.eq(a, b)
  return a == b
end
