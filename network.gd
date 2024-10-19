extends Node

signal update_game(player, round)
signal game_start
signal process_attack(array)
signal game_over(winner)

func read_env():
	var path = "res://Socket/server/.env"
	if  FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if line.find('=') != -1:
				var parts = line.split('=')
				var key = parts[0].strip_edges()
				var value = parts[1].strip_edges()
				match key:
					"IP":
						host = value
					"PORT":
						port = int(value)
		file.close()
		
var host = "127.0.0.1"
var port = 10000
var game_round = 0
var client = StreamPeerTCP.new()
var client_id = null
var opponent_id = null
var player_name: String:
	set(new_name):
		player_name = new_name
var connection_open = false
var names: Dictionary = {}

func ready():
	read_env() # if env file exists, replace host and port.
	print("Connecting to %s:%d" % [host, port])
	if client.connect_to_host(host, port) != OK:
		print("error connecting to host.")
	connection_open = true

func _process(_delta: float) -> void:
	if !connection_open:
		return
	var reply = fetch()
	if not reply.is_empty():
		#print(reply)
		if reply["header"] == "connection":
			if client_id == null:
				client_id = reply["client"]
				if client_id == "A":
					opponent_id = "B"
				else:
					opponent_id = "A"
				
			if reply["body"] == true:
				print("both players connected")
				# once both players join, game can start
				game_start.emit()
		elif reply["header"] == "game":
			if typeof(reply["body"]) == 3: # is keyword does not work for some reason, data type is not int but float?
				game_round = int(reply["body"])
				names = reply["names"]
				update_game.emit(client_id, game_round)
			else:
				var radar = "radar"
				if (client_id == "A" and game_round % 2 == 1) or (client_id == "B" and game_round % 2 == 0):
					radar += client_id
				else:
					radar += opponent_id
				process_attack.emit(reply["body"][radar])
				# after our attack or enemy attack update 
				Network.send({"header": "game", "body": "round"})
		elif reply["header"] == "game_over":
			game_over.emit(reply['body'])
	
	
func fetch() -> Dictionary:
	if client.get_status() != client.STATUS_NONE:
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
		
#!!!!!!!
func gridToCoord(position: int) -> Vector3i:
	# int 0 - 63
	# return (14, 0, 14) - (-14, 0, -14)
	var x = 14 - 4 * (int(position) % 8)
	var z = 14 - 4 * (int(position) / 8)
	return Vector3i(x, 0, z)
	
func coordToGrid(x:int, z: int):
	# Reverse the calculations from gridToCoord
	var p = int((14 - x) / 4) + 8 * int((14 - z) / 4) #warning-ignore:integer_division
	return p
	
func oppCoordToGrid(x:int, z: int):
	# int 0 - 63
	# return (3, 0, 3) - (-4, 0, -4)
	var p = (3 - x) + 8* (3 - z)
	return p
