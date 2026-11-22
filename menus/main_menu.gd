extends Control

@onready var level_1 = $VBoxContainer/Level1
@onready var level_2 = $VBoxContainer/Level2
@onready var level_3 = $VBoxContainer/Level3

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_level_1_pressed():
	get_tree().change_scene_to_file("res://levels/level01.tscn")

func _on_level_2_pressed():
	get_tree().change_scene_to_file("res://levels/level02.tscn")

func _on_level_3_pressed():
	get_tree().change_scene_to_file("res://levels/level03.tscn")
