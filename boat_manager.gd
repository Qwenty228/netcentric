extends Node3D

@export var boat_1: PackedScene 
@export var boat_4: PackedScene

@onready var current_boat_type:PackedScene = boat_1:
	set(boat_type):
		current_boat_type = boat_type

var rotation_angle:float = 0.0
var current_boat: Node3D
	
func _process(delta:float) -> void:
	if Input.is_action_just_pressed("boat1"):
		current_boat_type = boat_1
		
	if Input.is_action_just_pressed("boat4"):
		current_boat_type = boat_4

func build_boat(boat_position: Vector3) -> Node3D:
	if current_boat_type != null:
		var new_boat = current_boat_type.instantiate()
		add_child(new_boat)
		new_boat.global_position = boat_position
		new_boat.global_rotation.y = rotation_angle
		current_boat = new_boat
		return new_boat
	return null

func delete_boat(boat_position: Vector3) -> void:
	for child in get_children():
		if child.global_position == boat_position:
			child.queue_free()
			
func rotate_boat(boat_position: Vector3) -> Node3D:
	rotation_angle -= PI/2
	var current_boat_position = current_boat.global_position
	current_boat.queue_free()
	return build_boat(current_boat_position)
