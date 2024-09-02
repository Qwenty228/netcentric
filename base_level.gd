extends Node3D
@onready var menu_screen: Control = $MenuScreen
@onready var player_map: GridMap = $PlayerBoard/GridMap
@onready var opponent_grid_map: GridMap = $OppBoard/OppMap
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ray_picker_camera: Camera3D = $RayPickerCamera
@onready var mode_label: Label = $MenuScreen/ModeLabel

var player_board := true

func _ready() -> void:
	menu_screen.get_child(0).visible = false
	ray_picker_camera.grid_map = player_map
	
func _process(delta: float) -> void:
	#switch modes
	if !ray_picker_camera.build_mode and !ray_picker_camera.attack_mode:
		mode_label.text = "View mode"
		
	if Input.is_action_just_pressed("build"):
		ray_picker_camera.build_mode = !ray_picker_camera.build_mode
		ray_picker_camera.toggle_build()
		mode_label.text = "Build mode"
		
	if Input.is_action_just_pressed("attack"):
		if !ray_picker_camera.grid_map.is_player:
			ray_picker_camera.attack_mode = !ray_picker_camera.attack_mode
			ray_picker_camera.build_mode = false
			ray_picker_camera.toggle_build()
			mode_label.text = "Attack mode"
		
	if Input.is_action_just_pressed("menu"):
		menu_screen.get_child(0).visible = !menu_screen.get_child(0).visible
		
	if Input.is_action_just_pressed("switch_board"):
		if player_board:
			animation_player.play("opp_board")
			ray_picker_camera.build_mode = false
			ray_picker_camera.toggle_build()
			player_board = !player_board
			ray_picker_camera.grid_map = opponent_grid_map
			
		else:
			animation_player.play("player_board")
			ray_picker_camera.build_mode = false
			ray_picker_camera.attack_mode = true
			ray_picker_camera.toggle_build()
			player_board = !player_board
			ray_picker_camera.grid_map = player_map
			
			
