extends Node3D

@export var boat_1: PackedScene 
@export var boat_4: PackedScene

@onready var current_boat_type:PackedScene = boat_1:
	set(boat_type):
		print("set boat type to ", boat_type)
		current_boat_type = boat_type
	
func _process(delta:float) -> void:
	if Input.is_action_just_pressed("boat1"):
		current_boat_type = boat_1
		print(current_boat_type)
		
	if Input.is_action_just_pressed("boat4"):
		current_boat_type = boat_4
		print(current_boat_type)

func build_boat(boat_position: Vector3) -> Node3D:
	if current_boat_type != null:
		var new_boat = current_boat_type.instantiate()
		add_child(new_boat)
		new_boat.global_position = boat_position
		return new_boat
	return null

func delete_boat(boat_position: Vector3):
	for child in get_children():
		if child.global_position == boat_position:
			child.queue_free()
			
			
