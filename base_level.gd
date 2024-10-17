extends Node3D

@onready var menu_screen: Control = $MenuScreen
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
@onready var player_boat_manager = %BoatManager
@onready var opp_boat_manager = opp_board.get_child(-1)
@onready var build_ui_container: MarginContainer = $MenuScreen/BuildUIContainer
@onready var current_player_label: Label = %CurrentPlayerLabel
@onready var client_connection: Node = $ClientConnection
@onready var client_UI = client_connection.get_children()
@onready var end_screen: Control = $EndScreen
@onready var round_label = %RoundLabel
@onready var welcome_label = %WelcomeLabel
@onready var timer = $Timer
@export var build_mode := true:
	set(mode):
		build_mode = mode
		ray_picker_camera.build_mode = mode
		ray_picker_camera.toggle_build()
		if build_mode:
			mode_label.text = "Build mode"
@export var attack_mode := false:
	set(mode):
		attack_mode = mode
		ray_picker_camera.attack_mode = mode
		ray_picker_camera.toggle_build()
		if attack_mode:
			mode_label.text = "Attack mode"
			
var client_name 
var turn # if turn == 1, it is this client turn. if turn is 0 then it other client
var boat # global variable this client boat placement
var current_player_name
var is_player_board := true
var player_ships := 0:
	set(ships):
			player_ships += ships
			if player_ships == 0:
				end_screen.update_label(false)
var opp_ships := 4:
	set(ships):
			opp_ships += ships
			if opp_ships == 0:
				end_screen.update_label(true)

func _ready() -> void:
	welcome_label.text = "Welcome, " + Network.player_name
	menu_screen.get_child(0).visible = false
	end_screen.visible = false
	ray_picker_camera.grid_map = player_map
	build_mode = true
	boats_label.text = "Boats: 0"
	current_player_label.text = ""

func _process(delta: float) -> void:
	var format_string = "Time remaining: %d"
	welcome_label.text = format_string % timer.time_left
	#switch modes 	
	if client_connection.turn == 1:
		attack_mode = true
	elif client_connection.turn == 0:
		attack_mode = false

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
	ray_picker_camera.toggle_build()
	is_player_board = !is_player_board
	ray_picker_camera.grid_map = opponent_grid_map

func switch_to_player() -> void:
	animation_player.play("player_board")
	ray_picker_camera.toggle_build()
	is_player_board = !is_player_board
	ray_picker_camera.grid_map = player_map

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_ship_sunk(is_player) -> void:
	if is_player:
		player_ships = -1
		boats_label.text = "Boats: " + str(player_ships)
	else:
		opp_ships = -1

func _on_start_button_pressed() -> void:
	welcome_label.text = "Time remaining: " + str(timer.time_left)
	build_mode = false
	start_button.queue_free()
	build_ui_container.visible = false
	var player_boats = player_boat_manager.get_children()
	var player_boats_pos = []
	for boat in player_boats:
		for tile in boat.tiles_position:
			player_boats_pos.append(str(Network.coordToGrid(tile.x,tile.z)))
	client_name = Network.player_name
	# establish connection
	Network.ready()
	Network.update_game.connect(update_game_info)
	Network.game_start.connect(start)
	Network.process_attack.connect(show_state)
	Network.game_over.connect(end_game)
	print("connection establised")
	
	# waiting for server to response with client id
	await(get_tree().create_timer(0.5).timeout)  # Wait 0.5 seconds
	while Network.client_id == null:
		print("Waiting for client ID...")
		await(get_tree().create_timer(0.5).timeout)  # Wait another 0.5 seconds before checking again
	print("Client ID set:", Network.client_id)
	
	# after got client id, this client send to server about boat placement and client names
	Network.send({"header": "init", "body": player_boats_pos, "client": client_name})
	print("sent boat")

func start():
	# indicate that both player has connected and will proceed to the game loop
	print("start")
	await get_tree().create_timer(1).timeout
	print("process finished")
	# telling server that this client is ready to play
	Network.send({"header": "game", "body": "round"})

func _on_boat_manager_new_boat() -> void:
	player_ships = 1
	boats_label.text = "Boats: " + str(player_ships) 

# update values in building UI

func _on_boat_manager_new_boat_4(value: int) -> void:
	boat_4_label.text = "Boat 4 remaining: " + str(value)

func sink_player_ship(pos:Vector3i) -> void:
	var cell = player_map.local_to_map(pos) 
	player_map.set_cell_item(cell, 2)

func sink_enemy_ship(pos:Vector3i) -> void:
	var cell = opponent_grid_map.local_to_map(pos)
	opponent_grid_map.set_cell_item(cell,2)
	
func update_game_info(client_id, game_round):
	# Server sending round number
	round_label.text = "Round: " + str(game_round)
	print("Round: " + str(game_round))
	# figuring out whose turn is it
	if (client_id == "A" and game_round % 2 == 1) or (client_id == "B" and game_round % 2 == 0):
		current_player_name = client_name
		switch_to_opp()
		attack_mode = true
		turn = 1
		timer.start()
	else:
		timer.stop()
		current_player_name = Network.names[Network.opponent_id]
		switch_to_player()
		attack_mode = false
		turn = 0
	current_player_label.text = current_player_name
	
# update state of boards
func show_state(attacked: Array):
	# receiving attack from server
	var cell
	if turn:
		# if it is this client turns, 
		# this client is attacking
		# draw the 0, 1, -1 indicating where hit, where miss
		#print(client_name + " turn")
		for pos in range(len(attacked)):
			cell = opponent_grid_map.local_to_map(Network.gridToCoord(pos))
			if attacked[pos] == '1':
				opponent_grid_map.set_cell_item(cell, 4)
			elif attacked[pos] == '-1':
				opponent_grid_map.set_cell_item(cell, 5)
	else:
		# if it is not this client turns (being attacked)
		# show clients being attacked
		# draw 0, X, M. 0 indicating there is a boat, X means hit, M means miss.
		for pos in range(len(attacked)):
			cell = player_map.local_to_map(Network.gridToCoord(pos))
			if attacked[pos] == '1':
				player_map.set_cell_item(cell, 4)
			elif attacked[pos] == '-1':
				player_map.set_cell_item(cell, 5)


func _on_timer_timeout():
	#to be changed
	if turn:
		Network.send({"header":"game", "body": ['0']})
	

func end_game(winner: String):
	#if player wins
	end_screen.update_label(true)
	end_screen.player_score = 4 - opp_ships
	end_screen.opp_score = 4 - player_ships
	end_screen.visible = true
	
