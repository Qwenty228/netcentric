extends Node3D
@onready var menu_screen: Control = $MenuScreen
@onready var grid_map: GridMap = $GridMap

func _ready() -> void:
	menu_screen.visible = false
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("menu"):
		menu_screen.visible = !menu_screen.visible
