extends GPUParticles3D
var has_exploded
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	has_exploded = false
	print(has_exploded)
	
func explode() -> void:
	if !has_exploded:
		has_exploded = true
		animation_player.play("explosion")
