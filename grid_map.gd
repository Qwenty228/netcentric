extends GridMap

func is_hit(attack_position:Vector3) -> bool:
	var pos = local_to_map(attack_position)
	if get_cell_item(attack_position) == 2:
		return true
	return false
