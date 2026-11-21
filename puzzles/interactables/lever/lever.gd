extends StaticBody3D

signal state_update(is_on: bool)

## Whether the lever is toggled by default.
@export var is_on: bool = false

## Whether the lever can be toggled.
@export var is_toggleable = true

func interact() -> void:
	if is_toggleable:
		is_on = not is_on
		
		state_update.emit(is_on)

func get_checkpoint_state():
	return is_on
	
func restore_checkpoint_state(state):
	is_on = state
	state_update.emit(is_on)
