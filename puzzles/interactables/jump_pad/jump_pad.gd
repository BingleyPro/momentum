@tool
extends Node3D

@export var enabled = true
@export var launch_direction: Vector3

@onready var detector: Area3D = $Detector
@onready var animation_player = $AnimationPlayer
@onready var raycast: RayCast3D = $RayCast3D

func _ready() -> void:
	if not Engine.is_editor_hint():
		detector.body_entered.connect(_on_body_entered)
		
func _process(_delta):
	if Engine.is_editor_hint():
		raycast.target_position = launch_direction

func _on_body_entered(body) -> void:
	if not body.is_in_group("jump_pad_activators") or not enabled:
		return
		
	# Launch
	animation_player.play("launch")

	if body is CharacterBody3D:
		var force = launch_direction
		body.velocity += force
	else:
		var force = launch_direction * body.mass
		body.apply_central_force(force)
	
	animation_player.play_backwards("launch")
