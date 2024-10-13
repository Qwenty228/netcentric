extends Node3D

@export var units: int = 1
@export var boat_rotation: float
@export var legal := true
var tiles_position: Array[Vector3]
var hits: Array[bool]
