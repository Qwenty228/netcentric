#extends Node
#
#
#@export var host = "127.0.0.1"
#@export var port = 55555
#@export var state = []
#
#
#
#var client = StreamPeerTCP.new()
#var init_state = 0
#var connect_timeout = false
#var client_name = "alice"
#
#
#
#func _ready():
	##client.set_no_delay(true)
	#client.connect_to_host(host, port)
	#await connect_to_host()
	#print("setup finish")
	#init_state = 1
	#
#func _connection_fail():
	##print("failed")
	#connect_timeout = true
	#
#func connect_to_host():
	#var timer = Timer.new()
	#add_child(timer)
	#timer.set_wait_time(3.0)  # Set the timer to 3 seconds
	#timer.set_one_shot(true)  # Make sure the timer only runs once
	#timer.connect("timeout", _connection_fail)
	## Start the timer
	#timer.start()
	#while client.get_status() != client.STATUS_CONNECTED:
		#print(fetch())
		#if connect_timeout:
			#return "fail"
		#await get_tree().create_timer(0.2).timeout
	#
	#send({"header": "init", "body": ["0","1","2","3","8","16","24","32","33","34","35","36","63","62","61","60"], "client": client_name})
#
#func _process(_delta: float) -> void:
	#if init_state == 0: 
		#return
	#var reply = fetch()
	#if not reply.is_empty():
		#print(reply["header"])
	#
#func fetch() -> Dictionary:
	#if client.get_available_bytes() > 0:
		#client.poll()
		#var result_string = client.get_utf8_string(client.get_available_bytes()).strip_edges()
		##print("res", result_string)
		#var result = JSON.parse_string(result_string)
		#if result != null:
			#return result
	#return {}
	#
#func send(data):
	#if client.get_status() == client.STATUS_CONNECTED:
		##client.put_data(line_data.to_ascii_buffer())
		#client.put_utf8_string(JSON.stringify(data))
