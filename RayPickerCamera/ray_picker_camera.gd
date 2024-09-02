extends Camera3D

@export var grid_map: GridMap
@export var boat_manager: Node3D

@onready var ray_cast_3d: RayCast3D = $RayCast3D

var build_mode: bool
var previous_cell: Vector3i
var previous_boat: Node3D
var previous_pos: Vector3

func _ready() -> void:
	build_mode = false
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("build"):
		build_mode = !build_mode
		toggle_build()
	
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
				
				#boat rotation
				if Input.is_action_just_pressed("rotate"):
					if previous_boat != null:
						previous_boat.queue_free()
						previous_boat = boat_manager.build_boat(tile_position)
					
					#check if illegal
					if previous_boat!=null:
						var boat_rotation = previous_boat.boat_rotation
						var temp_cell = cell
						var broken = false
						for i in range(previous_boat.units):
							if grid_map.get_cell_item(temp_cell) != 0 && i >0:
								broken = true
								break
							if abs(boat_rotation) == 0: 
								temp_cell.z += 1
							elif round(abs(boat_rotation)) == 3:
								temp_cell.z -= 1
							elif abs(boat_rotation) == PI/2:
								temp_cell.x -= 1
							elif abs(boat_rotation) == 3*PI/2:
								temp_cell.x += 1 
						if broken:
							previous_boat.queue_free()
							previous_boat = null
							grid_map.set_cell_item(cell, 0)
						
					
				#boat type
				if Input.is_action_just_pressed("boat1") || Input.is_action_just_pressed("boat4"):	
					if previous_boat != null:
						previous_boat.queue_free()
						previous_boat = boat_manager.build_boat(tile_position)
				
				#fix boat in place or delete
				if Input.is_action_just_pressed("click"):
					if grid_map.get_cell_item(cell) != 2:
						grid_map.set_cell_item(cell, 2)
						var temp_cell = cell
						var boat_rotation = previous_boat.boat_rotation
						for i in range(previous_boat.units):
							grid_map.set_cell_item(temp_cell, 2)
							previous_boat.tiles_position.append(grid_map.map_to_local(temp_cell))
							if abs(boat_rotation) == 0: 
								temp_cell.z += 1
							elif round(abs(boat_rotation)) == 3:
								temp_cell.z -= 1
							elif abs(boat_rotation) == PI/2:
								temp_cell.x -= 1
							elif abs(boat_rotation) == 3*PI/2:
								temp_cell.x += 1
						previous_boat = null
					elif grid_map.get_cell_item(cell) == 2:
						var boat = boat_manager.find_boat(grid_map.map_to_local(cell))
						for position in boat.tiles_position:
							grid_map.set_cell_item(grid_map.local_to_map(position), 0)
						if boat != null:
							boat.queue_free()
					
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
					
				#create new temporary boat
				if grid_map.get_cell_item(cell) == 0:
					previous_cell = cell
					previous_boat = boat_manager.build_boat(tile_position)
					
					#check if illegal position
					var boat_rotation = previous_boat.boat_rotation
					var temp_cell = cell
					var broken = false
					for i in range(previous_boat.units):
						if grid_map.get_cell_item(temp_cell) != 0 && i >0:
							broken = true
							break
						if abs(boat_rotation) == 0: 
							temp_cell.z += 1
						elif round(abs(boat_rotation)) == 3:
							temp_cell.z -= 1
						elif abs(boat_rotation) == PI/2:
							temp_cell.x -= 1
						elif abs(boat_rotation) == 3*PI/2:
							temp_cell.x += 1 
					if broken:
						previous_boat.queue_free()
						previous_boat = null
					else:
						grid_map.set_cell_item(cell, 1)
						
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func toggle_build() -> void:
	if !build_mode:
		
		if grid_map.get_cell_item(previous_cell) != 2:
			if previous_boat!= null:
				previous_boat.queue_free()
				grid_map.set_cell_item(previous_cell, 0)