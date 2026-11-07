extends Node

signal pressed()

@export var inputs = []

@export var is_usable = true

func interact() -> void:
	if is_usable:
		pressed.emit()
