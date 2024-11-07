extends Node3D
signal ship_sunk
signal all_sunk
signal new_boat
signal new_boat_1(value)
signal new_boat_4(value)

@export var boat_1: PackedScene
@export var boat_4: PackedScene
@export var boat_4_illegal: PackedScene
@export var max_b1 = 4
@export var max_b4 = 4
@export var projectile: PackedScene

@onready var current_boat_type:PackedScene = boat_4:
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
		boats += boat
		if boat > 0:
			new_boat.emit()
		if boats == 0:
			all_sunk.emit()
		else:
			ship_sunk.emit()

func _process(_delta:float) -> void:
	if Input.is_action_just_pressed("boat1"):
		current_boat_type = boat_1
		
	if Input.is_action_just_pressed("boat4"):
		current_boat_type = boat_4
		
	if Input.is_action_just_pressed("rotate"):
		rotation_angle = PI/2

func set_boat_1() -> void:
	current_boat_type = boat_1
	
func set_boat_4() -> void:
	current_boat_type = boat_4

func build_boat(boat_position: Vector3, is_legal) -> Node3D:
	if current_boat_type != null:
		if is_available():
			var new_boat_ins
			if is_legal:
				new_boat_ins = current_boat_type.instantiate()
			else:
				if current_boat_type == boat_4:
					new_boat_ins = boat_4_illegal.instantiate()
			add_child(new_boat_ins)
			new_boat_ins.set_global_position(boat_position)
			new_boat_ins.global_rotation.y = rotation_angle
			current_boat = new_boat_ins
			new_boat_ins.boat_rotation = rotation_angle
			return new_boat_ins
	return null

func is_available() -> bool:
	if current_boat_type == boat_4:
		return max_b4 != 0
	if current_boat_type == boat_1:
		return max_b1 != 0
	return false

func fix_boat(boat: Node3D) -> void:
	if boat.units == 4:
		max_b4 -= 1
		boats = 1
		new_boat_4.emit(max_b4)
	if boat.units == 1:
		max_b1 -= 1
		boats = 1
		new_boat_1.emit(max_b1)

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
		boats = -1
		
func fire(direction: Vector3) -> void:
	#get random child
	var all_boats = get_children()
	var shot = projectile.instantiate()
	shot.direction = direction
	if all_boats.size() > 0:
		var rng = RandomNumberGenerator.new()
		var n = rng.randi_range(0, all_boats.size()-1)
		shot.global_position = all_boats[n].global_position
		all_boats[n].add_child(shot)
	else:
		shot.global_position.z += 5
	await(get_tree().create_timer(2).timeout)
	shot.queue_free()
