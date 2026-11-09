extends Node3D

signal state_update(state: bool)

@export var is_open: bool = false

@onready var animation_player = $AnimationPlayer

func set_open(value: bool) -> void:
	if is_open == value:
		return
		
	is_open = value
		
	if is_open:
		animation_player.play("open")
	else:
		animation_player.play_backwards("open")
		
	state_update.emit(is_open)

func set_active(active) -> void:
	set_open(active)
