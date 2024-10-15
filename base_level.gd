extends Node3D

@onready var menu_screen: Control = $MenuScreen
@onready var player_board: Node3D = $PlayerBoard
@onready var opp_board: Node3D = $OppBoard
@onready var player_map: GridMap = $PlayerBoard/GridMap
@onready var opponent_grid_map: GridMap = $OppBoard/OppMap
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ray_picker_camera: Camera3D = $RayPickerCamera
@onready var mode_label: Label = $MenuScreen/ModeLabel
@onready var win_label: Label = %WinLabel
@onready var start_button: Button = %StartButton

@onready var boats_label: Label = $MenuScreen/BoatsLabel
@onready var boat_1_label: Label = %Boat1Label
@onready var boat_4_label: Label = %Boat4Label
@onready var player_boat_manager = player_board.get_child(-1)
@onready var opp_boat_manager = opp_board.get_child(-1)
@onready var build_ui_container: MarginContainer = $MenuScreen/BuildUIContainer
@onready var current_player_label: Label = %CurrentPlayerLabel
@onready var client_connection: Node = $ClientConnection
@onready var client_UI = client_connection.get_children()

@onready var end_screen: Control = $EndScreen


var player_name = Network.player_name
var is_player_board := true
var player_ships := 0:
	set(ships):
			player_ships += ships
			if player_ships == 0:
				end_screen.update_label(false)
var opp_ships := 4:
	set(ships):
			opp_ships -= ships
			if opp_ships == 0:
				end_screen.update_label(true)
@export var build_mode := true:
	set(mode):
		build_mode = mode
		ray_picker_camera.build_mode = !ray_picker_camera.build_mode
		ray_picker_camera.toggle_build()
		mode_label.text = "Build mode"
@export var attack_mode := false:
	set(mode):
		attack_mode = mode
		ray_picker_camera.attack_mode = !ray_picker_camera.attack_mode
		ray_picker_camera.build_mode = false
		if attack_mode:
			mode_label.text = "Attack mode"

func _ready() -> void:
	menu_screen.get_child(0).visible = false
	end_screen.visible = false
	ray_picker_camera.grid_map = player_map
	build_mode = true
	boats_label.text = "Boats: 0"
	current_player_label.text = player_name + "'s turn"	
	
func _process(delta: float) -> void:
	#switch modes 	
	if client_connection.turn == 1:
		attack_mode = true
	elif client_connection.turn == 0:
		attack_mode = false
		
	if Input.is_action_just_pressed("build"):
		build_mode = !build_mode
		
	if Input.is_action_just_pressed("attack"):
		attack_mode = !attack_mode
		
	if Input.is_action_just_pressed("menu"):
		menu_screen.get_child(0).visible = !menu_screen.get_child(0).visible
		
	if Input.is_action_just_pressed("switch_board"):
		if is_player_board:
			switch_to_opp()
		else:
			switch_to_player()
			
	if Input.is_action_just_pressed("client_ui"):
		for child in client_UI:
			child.visible = true

func switch_to_opp() -> void:
	animation_player.play("opp_board")
	build_mode = false
	ray_picker_camera.toggle_build()
	is_player_board = !is_player_board
	ray_picker_camera.grid_map = opponent_grid_map

func switch_to_player() -> void:
	animation_player.play("player_board")
	build_mode = false
	attack_mode = true
	ray_picker_camera.toggle_build()
	is_player_board = !is_player_board
	ray_picker_camera.grid_map = player_map

func _on_opp_hit() -> void:
	opp_ships = -1

func _on_player_hit() -> void:
	player_ships = -1
	
func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_ship_sunk(is_player) -> void:
	if is_player:
		player_ships = -1
		boats_label.text = "Boats: " + str(player_ships)
	else:
		opp_ships = -1

func _on_start_button_pressed() -> void:
	build_mode = false
	switch_to_opp()
	attack_mode = true
	start_button.queue_free()
	build_ui_container.visible = false
	var player_boats = player_boat_manager.get_children()
	var player_boats_pos = []
	for boat in player_boats:
		for tile in boat.tiles_position:
			player_boats_pos.append(str(Network.coordToGrid(tile.x,tile.z)))
	
	client_connection.start_connection(player_boats_pos)

func _on_boat_manager_new_boat() -> void:
	player_ships = 1
	boats_label.text = "Boats: " + str(player_ships) 


func _on_boat_1_btn_pressed() -> void:
	player_boat_manager.set_boat_1()


func _on_boat_4_btn_pressed() -> void:
	player_boat_manager.set_boat_4()

# update values in building UI
func _on_boat_manager_new_boat_1(value: int) -> void:
	boat_1_label.text = "Boat 1 remaining: " + str(value)

func _on_boat_manager_new_boat_4(value: int) -> void:
	boat_4_label.text = "Boat 4 remaining: " + str(value)

func sink_player_ship(pos:Vector3i) -> void:
	var cell = player_map.local_to_map(pos) 
	player_map.set_cell_item(cell, 2)

func sink_enemy_ship(pos:Vector3i) -> void:
	var cell = opponent_grid_map.local_to_map(pos)
	opponent_grid_map.set_cell_item(cell,2)

func _on_client_connection_new_round() -> void:
	current_player_label = client_connection.current_player_name
