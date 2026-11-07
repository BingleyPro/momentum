extends StaticBody3D

signal toggled(is_on: bool)

@export var is_on: bool = false
@export var is_toggleable = true

func interact() -> void:
	if is_toggleable:
		is_on = not is_on
		
		toggled.emit(is_on)
