extends Node
@onready var music_player: AudioStreamPlayer = $MusicPlayer

var explode = preload("res://Assets/SFX/explode.wav")
var click = preload("res://Assets/SFX/click.wav")
var blast = preload("res://Assets/SFX/pewpew.wav")
var water = preload("res://Assets/SFX/water_impact.wav")

@export var click1:AudioStream
var sfx_on:= true

func play_bg():
	music_player.play()

func stop_bg():
	music_player.stop()
	
func play_sfx(sfx_name: String) -> void:
	if sfx_on:
		var stream = null
		if sfx_name == "explode":
			stream = explode
		elif sfx_name == "click":
			stream = click
		elif sfx_name == "blast":
			stream = blast
		elif sfx_name == "water":
			stream = water
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
