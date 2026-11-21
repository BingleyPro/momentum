extends Control

@onready var level_1 = $VBoxContainer/Level1
@onready var level_2 = $VBoxContainer/Level2

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_level_1_pressed():
	get_tree().change_scene_to_file("res://levels/level01.tscn")

func _on_level_2_pressed():
	get_tree().change_scene_to_file("res://levels/level_02.tscn")
