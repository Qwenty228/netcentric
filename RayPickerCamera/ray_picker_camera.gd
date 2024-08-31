extends Camera3D

@export var grid_map: GridMap
@export var boat_manager: Node3D

@onready var ray_cast_3d: RayCast3D = $RayCast3D

var build_mode: bool
var previous_cell: Vector3i
var previous_boat: Node3D

func _on_ready(delta:float) -> void:
	build_mode = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("build"):
		build_mode = !build_mode
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	ray_cast_3d.target_position = project_local_ray_normal(mouse_position) * 500
	ray_cast_3d.force_raycast_update()
	if ray_cast_3d.is_colliding():
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		var collider = ray_cast_3d.get_collider()
		if collider is GridMap:
			if build_mode:
				var collision_point = ray_cast_3d.get_collision_point()
				var cell = grid_map.local_to_map(collision_point) 
				var tile_position = grid_map.map_to_local(cell)
				
				#fix boat in place or delete
				if Input.is_action_just_pressed("click"):
					if grid_map.get_cell_item(cell) != 2:
						grid_map.set_cell_item(cell, 2)
						previous_boat = null
					elif grid_map.get_cell_item(cell) == 2:
						grid_map.set_cell_item(cell, 0)
						boat_manager.delete_boat(tile_position)
					
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
				
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
