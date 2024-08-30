extends Node3D

@export var small_boat: PackedScene 

func build_boat(boat_position: Vector3) -> void:
	var new_small_boat = small_boat.instantiate()
	add_child(new_small_boat)
	new_small_boat.global_position = boat_position
