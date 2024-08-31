extends Node


@export var host = "127.0.0.1"
@export var port = 65432

var client = StreamPeerTCP.new()
var init_state = 0
var connect_timeout = false
var line_data = "hello"
var client_name = "Nu"

func _ready():
	#client.set_no_delay(true)
	client.connect_to_host(host, port)
	var err = await connect_to_host()
	if err == "fail":
		print("connection fail")
	else:
		client_name = JSON.parse_string(err)['client']
		#print("client ", client_name)
		$Label.text += client_name
		
		
	print("setup finish")
	init_state = 1
	
func _connection_fail():
	#print("failed")
	connect_timeout = true
	
func connect_to_host():
	var timer = Timer.new()
	add_child(timer)
	timer.set_wait_time(3.0)  # Set the timer to 3 seconds
	timer.set_one_shot(true)  # Make sure the timer only runs once
	timer.connect("timeout", _connection_fail)
	# Start the timer
	timer.start()
	while client.get_status() != client.STATUS_CONNECTED:
		client.poll()
		if connect_timeout:
			return "fail"
		await get_tree().create_timer(0.2).timeout

	return client.get_utf8_string(client.get_available_bytes())


func _process(_delta: float) -> void:
	if init_state == 0: return
	var reply = fetch()
	if reply != "fail":
		reply = JSON.parse_string(reply)
		if reply.has("type"):
			if reply["type"] == "update":
				$Label3.text = str(reply)
			else:
				$Label2.text = str(reply)
		
func _on_button_pressed() -> void:
	var data = {"type": line_data, "client": client_name}
	if line_data == "init":
		data["ships"] = [1, 2,3,4, 10,12,13,14]
	elif line_data == "game":
		data["pos"] = [20]
	else:
		data["type"] = "game"
		data["pos"] = [line_data]

	send(data)

	
func fetch():
	
	if client.get_available_bytes() > 0:
		client.poll()
		#var reply = client.get_utf8_string(client.get_available_bytes())
		return client.get_utf8_string(client.get_available_bytes())
	return "fail"
	
func send(data):
	if client.get_status() == client.STATUS_CONNECTED:
		#client.put_data(line_data.to_ascii_buffer())
		client.put_utf8_string(JSON.stringify(data))


func _on_line_edit_text_changed(new_text: String) -> void:
	line_data = new_text
