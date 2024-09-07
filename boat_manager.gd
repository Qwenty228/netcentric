extends Node3D
signal ship_sunk
signal all_sunk

@export var boat_1: PackedScene 
@export var boat_4: PackedScene
@export var max_b1 = 4
@export var max_b4 = 4

@onready var current_boat_type:PackedScene = boat_1:
	set(boat_type):
		current_boat_type = boat_type

var rotation_angle:= 0.0:
	set(angle):
		rotation_angle -= angle
		if rotation_angle == -2*PI:
			rotation_angle = 0
		

var current_boat: Node3D

var boats:= 0:
	set(boat):
		boats -= boat
		if boats == 0:
			all_sunk.emit()
		else:
			ship_sunk.emit()

func _process(delta:float) -> void:
	if Input.is_action_just_pressed("boat1"):
		current_boat_type = boat_1
		
	if Input.is_action_just_pressed("boat4"):
		current_boat_type = boat_4
		
	if Input.is_action_just_pressed("rotate"):
		rotation_angle = PI/2

func build_boat(boat_position: Vector3) -> Node3D:
	if current_boat_type != null:
		if is_available(current_boat_type):
			var new_boat = current_boat_type.instantiate()
			add_child(new_boat)
			new_boat.set_global_position(boat_position)
			new_boat.global_rotation.y = rotation_angle
			for i in new_boat.units:
				new_boat.hits.append(false) 
			current_boat = new_boat
			new_boat.boat_rotation = rotation_angle
			return new_boat
	return null

func is_available(type: PackedScene) -> bool:
	if current_boat_type == boat_4:
		return max_b4 != 0
	if current_boat_type == boat_1:
		return max_b1 != 0
	return false

func fix_boat(boat: Node3D) -> void:
	if boat.units == 4:
		max_b4 -= 1
	if boat.units == 1:
		max_b1 -= 1

func delete_boat(boat_position: Vector3) -> void:
	for child in get_children():
		for tile_position in child.tiles_position:
			if tile_position == boat_position:
				child.queue_free()
	
func find_boat(boat_position: Vector3) -> Node3D:
	for child in get_children():
		for tile_position in child.tiles_position:
			if tile_position == boat_position:
				return child
	return null

func hit(boat_position: Vector3) -> void:
	var boat = find_boat(boat_position)
	#tag hit
	for i in range(boat.tiles_position):
		if boat.tile_position[i] == boat_position:
			boat.hit[i] = true
	#check if sunk
	if boat.hit.all():
		boat.queue_free()
		boats = 1
