extends GridMap

@export var is_player: bool
@export var explosion: PackedScene
@export var water_sprout: PackedScene
@export var debris: PackedScene
@export var burn:PackedScene
@export var opp = false

var taken_coord = []
var smokes = {}

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
		
		if not opp:
			var smoke = burn.instantiate()
			add_child(smoke)
			smoke.global_position = Vector3(pos.x, pos.y + 4, pos.z)
			smokes[pos] = smoke
			
			
		taken_coord.append(pos)
		AudioPlayer.play_sfx("explode")
		return true	
	return false
	
func miss(pos:Vector3) -> bool:
	if !(pos in taken_coord):
		var water = water_sprout.instantiate()
		add_child(water)
		water.global_position = pos
		water.explode()
		taken_coord.append(pos)
		AudioPlayer.play_sfx("water")
		return true
	return false
