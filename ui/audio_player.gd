extends Node
@onready var music_player: AudioStreamPlayer = $MusicPlayer

var explode = preload("res://Assets/SFX/explode.wav")
var click = preload("res://Assets/SFX/click.wav")
var blast = preload("res://Assets/SFX/pewpew.wav")

@export var click1:AudioStream

func play_bg():
	music_player.play()

func play_sfx(sfx_name: String) -> void:
	var stream = null
	if sfx_name == "explode":
		stream = explode
	elif sfx_name == "click":
		stream = click
	elif sfx_name == "blast":
		stream = blast
	else:
		print("Not found!")
		return
		
	var asp = AudioStreamPlayer.new()
	asp.stream = stream
	asp.name = "SFX"
	add_child(asp)
	asp.play()
	await asp.finished
	asp.queue_free()
