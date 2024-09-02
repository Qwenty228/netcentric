extends Node3D
@onready var menu_screen: Control = $MenuScreen
@onready var player_map: GridMap = $PlayerBoard/GridMap
@onready var opponent_grid_map: GridMap = $OppBoard/OpponentGridMap
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ray_picker_camera: Camera3D = $RayPickerCamera

var player_board := true

func _ready() -> void:
	menu_screen.visible = false
	ray_picker_camera.grid_map = player_map
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		menu_screen.visible = !menu_screen.visible
		
	if Input.is_action_just_pressed("switch_board"):
		if player_board:
			animation_player.play("opp_board")
			ray_picker_camera.grid_map = opponent_grid_map
			if ray_picker_camera.build_mode:
				ray_picker_camera.toggle_build()
			player_board = !player_board
		else:
			animation_player.play("player_board")
			ray_picker_camera.grid_map = player_map
			ray_picker_camera.toggle_build()
			player_board = !player_board
			
