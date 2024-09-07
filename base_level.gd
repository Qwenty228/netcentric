extends Node3D
@onready var menu_screen: Control = $MenuScreen
@onready var player_map: GridMap = $PlayerBoard/GridMap
@onready var opponent_grid_map: GridMap = $OppBoard/OppMap
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ray_picker_camera: Camera3D = $RayPickerCamera
@onready var mode_label: Label = $MenuScreen/ModeLabel
@onready var win_label: Label = %WinLabel
@onready var end_screen: CenterContainer = $MenuScreen/EndScreen
@onready var start_button: Button = $MenuScreen/StartButton


var player_board := true
var player_ships := 4:
	set(ships):
			player_ships -= ships
			if player_ships == 0:
				end_game(false)
var opp_ships := 4:
	set(ships):
			opp_ships -= ships
			if opp_ships == 0:
				end_game(true)
				
var build_mode := true:
	set(mode):
		build_mode = mode
		ray_picker_camera.build_mode = !ray_picker_camera.build_mode
		ray_picker_camera.toggle_build()
		mode_label.text = "Build mode"

var attack_mode := false:
	set(mode):
		if !ray_picker_camera.grid_map.is_player:
			attack_mode = mode
			ray_picker_camera.attack_mode = !ray_picker_camera.attack_mode
			ray_picker_camera.build_mode = false
			ray_picker_camera.toggle_build()
			mode_label.text = "Attack mode"

func _ready() -> void:
	menu_screen.get_child(0).visible = false
	end_screen.visible = false
	ray_picker_camera.grid_map = player_map
	build_mode = true
	attack_mode = false
	
func _process(delta: float) -> void:
	#switch modes 	
	if Input.is_action_just_pressed("build"):
		build_mode = !build_mode
		
	if Input.is_action_just_pressed("attack"):
		attack_mode = !attack_mode
		
	if Input.is_action_just_pressed("menu"):
		menu_screen.get_child(0).visible = !menu_screen.get_child(0).visible
		
	if Input.is_action_just_pressed("switch_board"):
		if player_board:
			switch_to_opp()
		else:
			switch_to_player()

func switch_to_opp() -> void:
	animation_player.play("opp_board")
	build_mode = false
	ray_picker_camera.toggle_build()
	player_board = !player_board
	ray_picker_camera.grid_map = opponent_grid_map

func switch_to_player() -> void:
	animation_player.play("player_board")
	build_mode = false
	attack_mode = true
	ray_picker_camera.toggle_build()
	player_board = !player_board
	ray_picker_camera.grid_map = player_map

func end_game(player_win:bool) -> void:
	end_screen.visible = true
	if player_win:
		win_label.text = "You win!"
	else:
		win_label.text = "git gud"

func _on_opp_hit() -> void:
	opp_ships = 1

func _on_player_hit() -> void:
	player_ships = 1
	
func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_ship_sunk(is_player) -> void:
	if is_player:
		player_ships = 1
	else:
		opp_ships = 1

func _on_start_button_pressed() -> void:
	build_mode = false
	switch_to_opp()
	start_button.queue_free()
