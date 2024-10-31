extends Node3D

@onready var opp_board: Node3D = $OppBoard
@onready var player_map: GridMap = $PlayerBoard/GridMap
@onready var opponent_grid_map: GridMap = $OppBoard/OppMap
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var ray_picker_camera: Camera3D = $RayPickerCamera
@onready var start_button: Button = %StartButton
@onready var player_boat_manager = %BoatManager
@onready var opp_boat_manager = %OppBoatManager
@onready var client_connection: Node = $ClientConnection
@onready var client_UI = client_connection.get_children()

#everything UI
@onready var ui = $UI
@onready var welcome_label: Label = %WelcomeLabel
@onready var turn_label: Label = %TurnLabel
@onready var tabs: CenterContainer = $UI/Tabs
@onready var round_label = %RoundLabel
@onready var timer = $Timer
@onready var end_screen: Control = $EndScreen
@onready var time_remaining: Label = %TimeRemaining
@onready var player_ships_label: Label = %PlayerShipsLabel
@onready var opp_ships_label: Label = %OppShipsLabel

@export var build_mode := true:
	set(mode):
		build_mode = mode
		ray_picker_camera.build_mode = mode
		ray_picker_camera.toggle_build()
@export var attack_mode := false:
	set(mode):
		attack_mode = mode
		ray_picker_camera.attack_mode = mode
		ray_picker_camera.toggle_build()
			
var client_name 
var turn = 2 # if turn == 1, it is this client turn. if turn is 0 then it other client
var boat # global variable this client boat placement
var current_player_name
var is_player_board := true
var player_score := 0
var opp_score := 0

func _ready() -> void:
	welcome_label.text = "Welcome, " + Network.player_name
	round_label.visible = false
	end_screen.visible = false
	ray_picker_camera.grid_map = player_map
	build_mode = true
	player_score = 0
	opp_score = 0
	AudioPlayer.play_bg()

func _process(_delta: float) -> void:
	var format_string = "Time remaining: %d"
	if turn < 2:
		time_remaining.visible = true
		time_remaining.text = str(format_string % timer.time_left) + "s"
	#switch modes 	
	if client_connection.turn == 1:
		attack_mode = true
	elif client_connection.turn == 0:
		attack_mode = false

	if Input.is_action_just_pressed("menu"):
		if tabs.visible:
			tabs.visible = false
			if build_mode:
				ray_picker_camera.build_mode = true
		else:
			tabs.visible = true
			if build_mode:
				ray_picker_camera.build_mode = false
				ray_picker_camera.toggle_build()
			
			
		
	if Input.is_action_just_pressed("switch_board"):
		if is_player_board:
			switch_to_opp()
		else:
			switch_to_player()	
			
	if Input.is_action_just_pressed("client_ui"):
		for child in client_UI:
			child.visible = true
	
	player_ships_label.text = str(player_score)
	opp_ships_label.text = str(opp_score)

func switch_to_opp() -> void:
	animation_player.play("opp_board")
	ray_picker_camera.toggle_build()
	is_player_board = false
	ray_picker_camera.grid_map = opponent_grid_map

func switch_to_player() -> void:
	animation_player.play("player_board")
	ray_picker_camera.toggle_build()
	is_player_board = true
	ray_picker_camera.grid_map = player_map

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_start_button_pressed() -> void:
	turn_label.text = "Waiting for player 2..."
	build_mode = false
	start_button.queue_free()
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

# update values in building UI

func sink_player_ship(pos:Vector3i) -> void:
	var cell = player_map.local_to_map(pos) 
	player_map.set_cell_item(cell, 2)

func sink_enemy_ship(pos:Vector3i) -> void:
	var cell = opponent_grid_map.local_to_map(pos)
	opponent_grid_map.set_cell_item(cell,2)
	
func update_game_info(client_id, game_round):
	# Server sending round number
	round_label.text = "Round: " + str(game_round)
	# figuring out whose turn is it
	if (client_id == "A" and game_round % 2 == 1) or (client_id == "B" and game_round % 2 == 0):
		await(get_tree().create_timer(3).timeout)
		turn_label.text = "Your turn"
		switch_to_opp()
		turn = 1
		attack_mode = true
		timer.start()
	else:
		timer.stop()
		current_player_name = Network.names[Network.opponent_id]
		if !is_player_board:
			await(get_tree().create_timer(3).timeout)
			switch_to_player()
		turn = 0
		attack_mode = false
		turn = 0
		turn_label.text = str(Network.names[Network.opponent_id]) + "'s turn"
	
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
			var coord = Network.gridToCoord(pos)
			cell = opponent_grid_map.local_to_map(coord)
			if attacked[pos] == '1':
				var is_not_repeat = opponent_grid_map.hit(coord)
				if is_not_repeat:
					opponent_grid_map.set_cell_item(cell, 4)
					player_score += 1
					#player_boat_manager.fire(coord)
			elif attacked[pos] == '-1':
				var is_not_repeat = opponent_grid_map.miss(coord)
				if is_not_repeat:
					opponent_grid_map.set_cell_item(cell, 5)
					opponent_grid_map.miss(coord)
					#player_boat_manager.fire(coord)
			
	else:
		# if it is not this client turns (being attacked)
		# show clients being attacked
		# draw 0, X, M. 0 indicating there is a boat, X means hit, M means miss.
		for pos in range(len(attacked)):
			var coord = Network.gridToCoord(pos)
			cell = player_map.local_to_map(coord)
			if attacked[pos] == '1':
				var is_not_repeat = player_map.hit(coord)
				if is_not_repeat:
					player_map.set_cell_item(cell, 4)
					var afflicted_boat = player_boat_manager.find_boat(coord)
					afflicted_boat.hits += 1
					opp_score += 1
					#opp_boat_manager.fire(coord)
			elif attacked[pos] == '-1':
				var is_not_repeat = player_map.miss(coord)
				if is_not_repeat:
					player_map.set_cell_item(cell, 5)
					player_map.miss(coord)
					#opp_boat_manager.fire(coord)
				
			


func _on_timer_timeout():
	#to be changed
	if turn:
		Network.send({"header":"game", "body": ['-1']})
	

func end_game(winner):
	print(winner)
	#if player wins
	if player_score > opp_score:
		player_score += 1
		end_screen.update_label(true)
	else: 
		end_screen.update_label(false)
		opp_score += 1
	end_screen.player_score.text = str(opp_score)
	end_screen.opp_score.text = str(player_score)
	ui.get_child(1).visible = false
	end_screen.visible = true
	


func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://main_menu_bg.tscn")


func _on_check_button_toggled(toggled_on):
	if toggled_on:
		AudioPlayer.stop_bg()
	else:
		AudioPlayer.play_bg()


func _on_sf_xcheck_toggled(toggled_on):
	AudioPlayer.sfx_on = toggled_on
