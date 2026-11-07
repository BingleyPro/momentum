extends StaticBody3D

signal state_update(is_on: bool)

@export var is_on: bool = false
@export var is_toggleable = true

func interact() -> void:
	if is_toggleable:
		is_on = not is_on
		
		state_update.emit(is_on)
