extends Node3D

@export var units: int = 4
@export var boat_rotation: float
@export var legal := true
var tiles_position: Array[Vector3]
var hits: Array[bool]
