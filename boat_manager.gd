extends Node3D

@export var small_boat: PackedScene 

func build_boat(boat_position: Vector3) -> Node3D:
	var new_small_boat = small_boat.instantiate()
	add_child(new_small_boat)
	new_small_boat.global_position = boat_position
	return new_small_boat

func delete_boat(boat_position: Vector3):
	for child in get_children():
		if child.global_position == boat_position:
			child.queue_free()
