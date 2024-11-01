extends Control

@export var label: Label
@onready var player_score: Label = %PlayerScore
@onready var opp_name_label: Label = %OppNameLabel
@onready var opp_score: Label = %OppScore

func update_label(label_text: String) -> void:
	opp_name_label.text = Network.names[Network.opponent_id] + "'s score:"
	label.text = label_text

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _on_play_button_pressed() -> void:
	get_tree().reload_current_scene()
