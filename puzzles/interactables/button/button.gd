extends StaticBody3D

signal pressed()

@export var is_usable = true

func interact() -> void:
	if is_usable:
		pressed.emit()
