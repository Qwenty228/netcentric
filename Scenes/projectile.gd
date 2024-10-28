extends Area3D

var direction:= Vector3.FORWARD

@export var speed:= 30.0

func _physics_process(delta: float) -> void:
	position += direction * speed *delta
