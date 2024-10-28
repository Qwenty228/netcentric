extends GridMap
signal player_hit
signal opp_hit

@export var is_player: bool
@export var explosion: PackedScene
@export var water_sprout: PackedScene
@export var debris: PackedScene
var FX = []

func attack(attack_position:Vector3i) -> void:
	print("Attack!")
	if get_cell_item(attack_position) == 2:
		#set to attacked but not hit!
		set_cell_item(attack_position, 3)
		if is_player:
			player_hit.emit()
		else:
			opp_hit.emit()

func hit(pos:Vector3) -> bool:
	for fx in FX:
		if fx.global_position == pos:
			return false
	var ex = explosion.instantiate()
	var deb = debris.instantiate()
	add_child(ex)
	ex.global_position = pos
	add_child(deb)
	deb.global_position = pos
	ex.explode()
	FX.append(ex)
	return true
	
func miss(pos:Vector3) -> bool:
	var already_hit = false
	for fx in FX:
		if fx.global_position == pos:
			already_hit = true
	if !already_hit:
		var water = explosion.instantiate()
		add_child(water)
		water.global_position = pos
		water.explode()
		FX.append(water)
		return true
	return false
