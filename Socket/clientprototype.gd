extends Node
signal new_round
var client_name 
var turn # if turn == 1, it is this client turn. if turn is 0 then it other client
var boat # global variable this client boat placement
var current_player_name

func start_connection(player_boat_pos):
	client_name = Network.player_name
	boat = player_boat_pos
	# establish connection
	Network.ready()
	Network.update_game.connect(update_game_info)
	Network.game_start.connect(start)
	Network.process_attack.connect(show_state)
	print("connection establised")
	
	# waiting for server to response with client id
	await(get_tree().create_timer(0.5).timeout)  # Wait 0.5 seconds
	while Network.client_id == null:
		print("Waiting for client ID...")
		await(get_tree().create_timer(0.5).timeout)  # Wait another 0.5 seconds before checking again
	print("Client ID set:", Network.client_id)
	
	# after got client id, this client send to server about boat placement and client names
	Network.send({"header": "init", "body": player_boat_pos, "client": client_name})
	print("sent boat")
	$Button.disabled = true
		
	
func _ready() -> void:
	## simulate name and boat placement, for testing this file alone
	var rng = RandomNumberGenerator.new()
	Network.player_name = "test" + str(rng.randi())
	await(get_tree().create_timer(rng.randf_range(0, 2)).timeout)
	start_connection(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16"])
	#print(boat)
	print_ships(boat, [])
	print_my_attack([])
	
func start():
	# indicate that both player has connected and will proceed to the game loop
	print("start")
	await get_tree().create_timer(1).timeout
	print("process finished")
	# telling server that this client is ready to play
	Network.send({"header": "game", "body": "round"})
	
	
	# the game loop:
	# both client ask for round number
	# server send round number to both client
	# client figure out whose turn it is (id A plays on odd round, id B plays on even round)
	# one client send attack data
	# server send back attack data to both clients. Attacker will know if hit or miss (1, -1), attacked will know if their boat is hitted or missed
	# clients update their boat and attack state
	# repeat back at both client ask for round number
	
func update_game_info(client_id, game_round):
	# Server sending round number
	$Label.text = "Round: " + str(game_round)
	print("Round: " + str(game_round))
	# figuring out whose turn is it
	if (client_id == "A" and game_round % 2 == 1) or (client_id == "B" and game_round % 2 == 0):
		current_player_name = client_name
		$Label.text += "my turn\n" + client_name
		print(client_name + " turn")
		$Button.disabled = false
		turn = 1
	else:
		current_player_name = Network.names[Network.opponent_id]
		print(client_name + " waiting for " + Network.names[Network.opponent_id])
		$Label.text += "waiting for "+ Network.names[Network.opponent_id]
		$Button.disabled = true
		turn = 0
	new_round.emit()

func print_ships(ships: Array, attacked: Array) -> void:
	# displaying ships
	var label = $Label3
	# 0 means no attack, 1 means boat being hit, -1 means miss
	# this is the attack mapping
	var letter = {"0": " ", "-1": "M", "1": "X"}
	var board = []
	
	if not attacked.is_empty():
		# being attacked
		# Populate the board with the appropriate characters based on 'attacked'
		for i in attacked:
			board.append(letter.get(str(i), "  "))  # Default to space if not found
	else:
		# if no attack (attack = [])
		for i in range(64):
			board.append("  ")

	# Place the ships on the board
	for ship in ships:
		# loop up ship index
		var index = int(ship)
		# from the board above, if being hit it would already show x, so we skip this iteration
		if board[index] == "X":
			continue
		# otherwise at that position we draw 0, indicating that boat this position is alive
		board[index] = "0"
	
	# Create the board string and set it to the label
	var board_string = "_______________________________\n"
	for i in range(0, 64, 8):
		# draw each row
		board_string += "| " + " | ".join(board.slice(i, i + 8)) + " |\n"
	board_string += "------------------------------------------"
	
	label.text = "Your Boat:\n" + board_string  # Set the label's text


func print_my_attack(attack: Array) -> void:
	# display client attacks
	# attack should come in rendering screen format
	# cumulative of attack positions
	# ex: attack at 10 26, and 63. miss at 26
	#["0", "0", "0", "0", "0", "0", "0", "0", 
	# "0", "0", "1", "0", "0", "0", "0", "0", 
	# "0", "0", "0", "0", "0", "0", "0", "0", 
	# "0", "0", "-1", "0", "0", "0", "0", "0", 
	# "0", "0", "0", "0", "0", "0", "0", "0", 
	# "0", "0", "0", "0", "0", "0", "0", "0", 
	# "0", "0", "0", "0", "0", "0", "0", "0", 
	# "0", "0", "0", "0", "0", "0", "0", "1"]
	
	
	if attack.is_empty():
		# if attack is empty, then all is 0
		for i in range(64):
			attack.append("0")  # Default to all "0" if no attacks

	
	# Create the attack board string and set it to the label
	var board_string = "_______________________________\n"
	for i in range(0, 64, 8):
		board_string += "| " + " | ".join(attack.slice(i, i + 8)) + " |\n"
	board_string += "------------------------------------------"

	$Label2.text = "Your attack:\n" + board_string  # Set the label's text

func show_state(rendering_screen):
	# receiving attack from server
	if turn:
		# if it is this client turns, 
		# this client is attacking
		# draw the 0, 1, -1 indicating where hit, where miss
		
		#print(client_name + " turn")
		print_my_attack(rendering_screen)
		print(rendering_screen)
	else:
		# if it is not this client turns (being attacked)
		# show clients being attacked
		# draw 0, X, M. 0 indicating there is a boat, X means hit, M means miss.
		
		#print(Network.names[Network.opponent_id] + " turn")
		print_ships(boat, rendering_screen)		
		print(rendering_screen)
		
func _on_button_pressed() -> void:
	# pew pew
	var text = $LineEdit.text
	if str(text).is_valid_int():
		Network.send({"header":"game", "body": [text]})

func _on_ray_picker_camera_attacked(coord) -> void:
	Network.send({"header":"game", "body": [coord]})
