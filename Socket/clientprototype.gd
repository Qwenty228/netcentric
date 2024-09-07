extends Node


func _ready():
	Network.update_game.connect(update_game_info)
	Network.game_start.connect(start)
	
func start():
	print("start")
	await get_tree().create_timer(2).timeout
	print("process finished")
	
	Network.send({"header": "game", "body": "round"})
	
	
func update_game_info(client_id, game_round):
	#print("round: ", game_round)
	$Label.text = "Round: " + str(game_round)
	if (client_id == "A" and game_round % 2 == 1) or (client_id == "B" and game_round % 2 == 0):
		$Label.text += "my turn"
		$Button.disabled = false
	else:
		$Label.text += "waiting for opponent"
		$Button.disabled = true
		

func _on_button_pressed() -> void:
	var text = $LineEdit.text
	if str(text).is_valid_int():
		Network.send({"header":"game", "body": [text]})
		
	
