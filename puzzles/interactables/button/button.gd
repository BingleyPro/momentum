extends StaticBody3D

signal state_update(state: bool)

enum ButtonType {Toggle, Timed}

@export var is_usable = true
@export var type: ButtonType
@export_range(0.0, 10.0, 0.5, "or_greater", "suffix:s") var time: float = 2.0

var is_on = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer

func interact() -> void:
	if is_usable:
		match type:
			ButtonType.Toggle:
				update_state(not is_on)
			ButtonType.Timed:
				if not is_on:
					update_state(true)
					timer.start(time)

func update_state(new_state) -> void:
	if new_state != is_on:
		is_on = new_state
		
		if is_on:
			animation_player.play("press")
		else:
			animation_player.play_backwards("press")
		
		state_update.emit(is_on)

func _on_timer_timeout():
	update_state(false)

func get_checkpoint_state():
	return {
		"is_on": is_on,
		"time_left": timer.time_left
	}
	
func restore_checkpoint_state(state):
	is_on = state["is_on"]
	
	var time_left = state["time_left"]
	
	if is_on:
		animation_player.play("press")
	else:
		animation_player.play_backwards("press")
	
	if time_left != 0:
		timer.start(time_left)
