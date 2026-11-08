extends Node3D

signal state_update(state: bool)

var is_on: bool = false
var occupants: Array[Node3D] = []

@onready var detector: Area3D = $Detector
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
	detector.body_entered.connect(_on_body_entered)
	detector.body_exited.connect(_on_body_exited)

func _on_body_entered(body) -> void:
	if not body.is_in_group("plate_activators"):
		return
	
	if not occupants.has(body):
			occupants.append(body)
			
	update_state()
	
func _on_body_exited(body) -> void:
	occupants.erase(body)
	update_state()
	
func update_state() -> void:
	var new_state = not occupants.is_empty()
	
	if new_state != is_on:
		is_on = new_state
		
		if is_on:
			animation_player.play("press")
		else:
			animation_player.play_backwards("press")
		
		state_update.emit(is_on)
