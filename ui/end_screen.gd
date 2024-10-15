extends Control

@export var label: Label

func update_label(player_win) -> void:
	if player_win:
		label.text = "You win!"
	else:
		label.text = "You lost!"

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _on_play_button_pressed() -> void:
	get_tree().reload_current_scene()
