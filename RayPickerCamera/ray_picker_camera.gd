extends Camera3D

@export var grid_map: GridMap
@export var boat_manager: Node3D

@onready var ray_cast_3d: RayCast3D = $RayCast3D

var build_mode: bool
var previous_cell: Vector3i
var previous_boat: Node3D

func _ready() -> void:
	build_mode = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("build"):
		build_mode = !build_mode
		#get rid of temporary boats if out of build mode
		if !build_mode:
			if grid_map.get_cell_item(previous_cell) != 2:
				if previous_boat!= null:
					previous_boat.queue_free()
					grid_map.set_cell_item(previous_cell, 0)
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	ray_cast_3d.target_position = project_local_ray_normal(mouse_position) * 500
	ray_cast_3d.force_raycast_update()
	if ray_cast_3d.is_colliding():
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		var collider = ray_cast_3d.get_collider()
		
		#if clicking on a fixed boat 
		if collider.is_in_group("boat"):
			if Input.is_action_just_pressed("click"):
				var temp_cell = grid_map.local_to_map(collider.get_child(0).global_position) 
				var boat_rotation = collider.get_parent().global_rotation
				print(boat_rotation)
				for i in range(collider.get_parent().units):
					grid_map.set_cell_item(temp_cell, 0)
					temp_cell.z += 1
				previous_boat = null
				collider.queue_free()
				
		elif collider is GridMap:
			if build_mode:
				var collision_point = ray_cast_3d.get_collision_point()
				var cell = grid_map.local_to_map(collision_point) 
				var tile_position = grid_map.map_to_local(cell)
				
				#fix boat in place or delete
				if Input.is_action_just_pressed("click"):
					if grid_map.get_cell_item(cell) != 2:
						grid_map.set_cell_item(cell, 2)
						var temp_cell = cell
						previous_boat.get_child(0).use_collision = true
						for i in range(previous_boat.units-1):
							temp_cell.z += 1
							grid_map.set_cell_item(temp_cell, 2)
						previous_boat = null
					elif grid_map.get_cell_item(cell) == 2:
						grid_map.set_cell_item(cell, 0)
						boat_manager.delete_boat(tile_position)
					
				#remove highlighted cell when hovering over fixed cells
				if grid_map.get_cell_item(cell) == 2:
					if grid_map.get_cell_item(previous_cell) == 1:
						if previous_boat!= null:
							previous_boat.queue_free()
							grid_map.set_cell_item(previous_cell, 0)
				
				#delete unfixed boat
				if grid_map.get_cell_item(cell) != 2:
					if grid_map.map_to_local(cell) != grid_map.map_to_local(previous_cell):
						if previous_boat!= null:
							previous_boat.queue_free()
							grid_map.set_cell_item(previous_cell, 0)
					
				#create new boat
				if grid_map.get_cell_item(cell) == 0:
					grid_map.set_cell_item(cell, 1)
					previous_cell = cell
					previous_boat = boat_manager.build_boat(tile_position)
				
				#boat rotation
				if Input.is_action_just_pressed("rotate"):
					previous_boat = boat_manager.rotate_boat(tile_position)		
				
				#boat type
				if Input.is_action_just_pressed("boat1") || Input.is_action_just_pressed("boat4"):	
					boat_manager.delete_boat(tile_position)
					previous_boat = boat_manager.build_boat(tile_position)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
