extends Node3D
@onready var animation_player = %AnimationPlayer

@export var units: int = 4
@export var boat_rotation: float
@export var legal := true
var tiles_position: Array[Vector3]
var hits:= 0

func _ready() -> void:
	if animation_player != null:
		animation_player.play("idle")
		
func _process(delta: float) -> void:
	if hits == 4:
		animation_player.play("sink")
	
func print_info() -> void:
	print("Boat 4 positions:")
	for tile in tiles_position:
		print("-" + str(tile))
	print("current hits:" + str(hits))
	
