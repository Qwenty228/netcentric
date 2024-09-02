extends GridMap
signal player_hit
signal opp_hit
signal sunk(is_player)

@export var is_player: bool

func attack(attack_position:Vector3i) -> void:
	var pos = local_to_map(attack_position)
	if get_cell_item(attack_position) == 2:
		set_cell_item(attack_position, 3)
		if is_player:
			player_hit.emit()
		else:
			opp_hit.emit()


func _on_ship_sunk() -> void:
	sunk.emit(is_player)
