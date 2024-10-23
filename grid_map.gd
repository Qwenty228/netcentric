extends GridMap

@export var is_player: bool
@export var explosion: PackedScene
@export var water_sprout: PackedScene
@export var debris: PackedScene
var taken_coord = []

func attack(attack_position:Vector3i) -> void:
	var pos = local_to_map(attack_position)
	if get_cell_item(attack_position) == 2:
		set_cell_item(attack_position, 3)

func hit(pos:Vector3) -> bool:
	if !(pos in taken_coord):
		var ex = explosion.instantiate()
		var deb = debris.instantiate()
		add_child(ex)
		ex.global_position = pos
		ex.explode()
		add_child(deb)
		deb.global_position = pos
		taken_coord.append(pos)
		return true	
	return false
	
func miss(pos:Vector3) -> bool:
	if !(pos in taken_coord):
		var water = explosion.instantiate()
		add_child(water)
		water.global_position = pos
		water.explode()
		taken_coord.append(pos)
		return true
	return false
