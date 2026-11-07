extends StaticBody3D

signal state_update(state: bool)

@export var is_usable = true

func interact() -> void:
	if is_usable:
		state_update.emit(true)
