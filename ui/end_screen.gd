extends Control

@export var label: Label
@onready var player_score: Label = %PlayerScore
@onready var opp_name_label: Label = %OppNameLabel
@onready var opp_score: Label = %OppScore

func update_label(player_win) -> void:
	opp_name_label.text = Network.names[Network.opponent_id] + "'s score:"
	if player_win:
		label.text = "You win!"
	else:
		label.text = "You lost!"

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _on_play_button_pressed() -> void:
	get_tree().reload_current_scene()
