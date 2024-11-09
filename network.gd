extends Node

signal update_game(player, round)
signal game_start
signal process_attack(array)
signal game_over(winner)
signal game_restart


var host = "netcentric.ase.cx"
var port = 1001
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
	print("Connecting to %s:%d" % [host, port])
	if client.get_status() == client.STATUS_NONE:
		if client.connect_to_host(host, port) != OK:
			print("error connecting to host.")
	else:
		print("restart game")
	print("Connection successful")
	connection_open = true

func _process(_delta: float) -> void:
	if !connection_open:
		return
	var reply = fetch()
	
	if not reply.is_empty():
		#print(player_name + " receive " + str(reply))
		if reply["header"] == "init":
			#print(reply)	
			var order = reply["body"]
			client_id = order[player_name]
			if client_id == "A":
				opponent_id = "B"
			else:
				opponent_id = "A"
			
			game_start.emit()
			
		elif reply["header"] == "round":
			#if typeof(reply["body"]) == 3: # is keyword does not work for some reason, data type is not int but float?
			game_round = int(reply["body"])
			names = reply["names"]
			update_game.emit(client_id, game_round)
		elif reply["header"] == "game":
			process_attack.emit(reply["body"])
			# after our attack or enemy attack update 
			Network.send({"header": "round", "author": player_name})
				
		elif reply["header"] == "game_over":
			#print("client: " + name + str(reply))
			game_over.emit(reply['body'])
			
		elif reply["header"] == "reset":
			game_restart.emit()
			reset()
			#print("receive restart signal")
			#print(reply)
			

func parse_concatenated_json(data: String) -> String:
	if "}{" not in data:
		return data
	
	# Split the data into separate potential JSON parts by looking for '}{'
	var json_parts := data.split("}{")
	
	# Try parsing the last JSON part, as it's the one we need
	return "{" + json_parts[-1]


func fetch() -> Dictionary:
	if client.get_status() != client.STATUS_NONE:
		if client.get_available_bytes() > 0:
			client.poll()
			var result_string = client.get_utf8_string(client.get_available_bytes()).strip_edges()
			print(player_name + " receive " + str(result_string))
			var result = JSON.parse_string(parse_concatenated_json(result_string))
			if result != null:
				return result
	return {}
	
func send(data):
	#print(client.get_status())
	if client.get_status() == client.STATUS_CONNECTED:
		client.put_utf8_string(JSON.stringify(data))
		print(player_name + " send " + str(data))
		
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

func oppGridToCoord(position:int):
	# int 0 - 63
	# return (3, 0, 3) - (-4, 0, -4)
	var x = 3 - int(position % 8)
	var z = 3 - int(position / 8)
	return Vector3i(x, 0, z)

func reset():
	if client.get_status() == client.STATUS_CONNECTED:
		client.disconnect_from_host()
	#get_tree().reload_current_scene()
