extends Control
@onready var warning_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/WarningLabel
var is_name_set = false

func _on_line_edit_text_changed(new_text: String) -> void:
	Network.player_name = new_text
	if new_text != "":
		is_name_set = true


func _on_play_button_pressed() -> void:
	if is_name_set:
		get_tree().change_scene_to_file("res://base_level.tscn")
	else:
		warning_label.visible = true
