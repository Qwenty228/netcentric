extends GPUParticles3D
var has_exploded:= false
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func explode() -> void:
	animation_player.play("explosion")
	await animation_player.animation_finished
	queue_free()
