extends Node3D
var animation_player = null

@export var units: int = 4
@export var boat_rotation: float
@export var legal := true
@export var projectile: PackedScene

var tiles_position: Array[Vector3]
var hits:= 0

func _ready() -> void:
	if has_node("AnimationPlayer"):
		animation_player = %AnimationPlayer

	if animation_player != null:
		animation_player.play("idle")
		
func _process(_delta: float) -> void:
	if hits == 4 and animation_player != null:
		animation_player.play("sink")
	
func print_info() -> void:
	print("Boat 4 positions:")
	for tile in tiles_position:
		print("-" + str(tile))
	print("current hits:" + str(hits))
	
