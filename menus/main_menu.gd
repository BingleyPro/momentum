extends Control

@onready var level_1 = $VBoxContainer/Level1
@onready var level_2 = $VBoxContainer/Level2
@onready var level_3 = $VBoxContainer/Level3

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var file = ConfigFile.new()
	file.load("user://best_times.cfg")
	label_button(level_1, "Level 1", "res://levels/level01.tscn", file)
	label_button(level_2, "Level 2", "res://levels/level02.tscn", file)
	label_button(level_3, "Level 3", "res://levels/level03.tscn", file)
	
func label_button(button: Button, title, path, file):
	var best = file.get_value("times", path, INF)
	if best == INF:
		button.text = title
	else:
		var minutes = int(best) / 60
		button.text = "%s   %d:%05.2f" % [title, minutes, fmod(best, 60.0)]

func _on_level_1_pressed():
	get_tree().change_scene_to_file("res://levels/level01.tscn")

func _on_level_2_pressed():
	get_tree().change_scene_to_file("res://levels/level02.tscn")

func _on_level_3_pressed():
	get_tree().change_scene_to_file("res://levels/level03.tscn")

func _on_reset_pressed():
	DirAccess.remove_absolute("user://best_times.cfg")
	_ready()
