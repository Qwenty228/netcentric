extends Node

var turn
var boat = ["0","1","2","3","8","16","24","32","33","34","35","36","63","62","61","60"]

func _ready():
	Network.update_game.connect(update_game_info)
	Network.game_start.connect(start)
	Network.process_attack.connect(show_state)
	
	# assume player set boat at lightspeed: 1 seconds
	await get_tree().create_timer(1).timeout
	# player set boats
	Network.send({"header": "init", "body": boat, "client": Network.player_name})
	print_ships(boat, [])
	print_my_attack([])
	
func start():
	print("start")
	await get_tree().create_timer(1).timeout
	print("process finished")
	
	Network.send({"header": "game", "body": "round"})
	
func update_game_info(client_id, game_round):
	#print("round: ", game_round)
	$Label.text = "Round: " + str(game_round)
	if (client_id == "A" and game_round % 2 == 1) or (client_id == "B" and game_round % 2 == 0):
		$Label.text += "my turn"
		$Button.disabled = false
		turn = 1
	else:
		$Label.text += "waiting for opponent"
		$Button.disabled = true
		turn = 0

func print_ships(ships: Array, attacked: Array) -> void:
	
	var label = $Label3
	var letter = {"0": " ", "-1": "M", "1": "X"}
	var board = []
	
	if not attacked.is_empty():
		# Populate the board with the appropriate characters based on 'attacked'
		print(attacked)
		for i in attacked:
			board.append(letter.get(str(i), "  "))  # Default to space if not found
	else:
		for i in range(64):
			board.append("  ")
	# Place the ships on the board
	for ship in ships:
		var index = int(ship)
		if board[index] == "X":
			continue
		board[index] = "0"
	
	# Create the board string and set it to the label
	var board_string = "_______________________________\n"
	for i in range(0, 64, 8):
		board_string += "| " + " | ".join(board.slice(i, i + 8)) + " |\n"
	board_string += "------------------------------------------"
	
	label.text = "Your Boat:\n" + board_string  # Set the label's text

func print_my_attack(attack: Array) -> void:
	if attack.is_empty():
		for i in range(64):
			attack.append("0")  # Default to all "0" if no attacks

	
	# Create the attack board string and set it to the label
	var board_string = "_______________________________\n"
	for i in range(0, 64, 8):
		board_string += "| " + " | ".join(attack.slice(i, i + 8)) + " |\n"
	board_string += "------------------------------------------"

	$Label2.text = "Your attack:\n" + board_string  # Set the label's text

func show_state(rendering_screen):
	if turn:
		print("my turn")
		print_my_attack(rendering_screen)
	else:
		print("opponent turn")
		print_ships(boat, rendering_screen)		
		
func _on_button_pressed() -> void:
	var text = $LineEdit.text
	if str(text).is_valid_int():
		Network.send({"header":"game", "body": [text]})
		
	
