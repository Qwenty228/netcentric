extends Node

signal update_game(player, round)
signal game_start
signal process_attack(array)

@export var host = "127.0.0.1"
@export var port = 55555
var game_round = 0
var client = StreamPeerTCP.new()
var client_id = null
var player_name: String



func _ready():
	client.connect_to_host(host, port)
	print("setup finish")

func _process(_delta: float) -> void:
	var reply = fetch()
	if not reply.is_empty():
		if reply["header"] == "connection":
			if client_id == null:
				client_id = reply["client"]
				# simulate player boat setup
				
			if reply["body"] == true:
				print("both players connected")
				# once both players join, game can start
				game_start.emit()
		elif reply["header"] == "game":
			if typeof(reply["body"]) == 3: # is keyword does not work for some reason, data type is not int but float?
				game_round = int(reply["body"])
				update_game.emit(client_id, game_round)
			else:
				process_attack.emit(reply["body"])
				# after our attack or enemy attack update 
				Network.send({"header": "game", "body": "round"})
				
			
		#print(reply)
	
func fetch() -> Dictionary:
	if client.get_available_bytes() > 0:
		client.poll()
		var result_string = client.get_utf8_string(client.get_available_bytes()).strip_edges()
		var result = JSON.parse_string(result_string)
		if result != null:
			return result
	return {}
	
func send(data):
	if client.get_status() == client.STATUS_CONNECTED:
		client.put_utf8_string(JSON.stringify(data))
		
func gridToCoord(position):
	# int 0 - 63
	# return (14, 0, 14) - (-14, 0, -14)
	var x = 14 - 4 * (position % 8)
	var z = 14 - 4 * int(position / 8)
	return [x, 0, z]
	
func coordToGrid(x:int, z: int):
	# Reverse the calculations from gridToCoord
	var p = int((14 - x) / 4) + 8 * int((14 - z) / 4) #warning-ignore:integer_division
	return p
