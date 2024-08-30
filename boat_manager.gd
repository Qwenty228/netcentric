extends Node3D

@export var small_boat: PackedScene 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var new_small_boat = small_boat.instantiate()
	add_child(new_small_boat)
