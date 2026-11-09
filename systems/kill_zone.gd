@tool
extends Area3D

@export var size: Vector3
@export var preview = true

var set_size: Vector3

@onready var trigger_preview = $TriggerPreview
@onready var kill_zone = $CollisionShape3D

func _ready() -> void:
	if not Engine.is_editor_hint():
		trigger_preview.hide()
		body_entered.connect(_on_body_entered)
		
		kill_zone.shape = BoxShape3D.new()
		kill_zone.shape.size = size
	
func _process(_delta):
	if preview:
		if Engine.is_editor_hint() and (size != set_size):
			trigger_preview.show()
			trigger_preview.mesh = BoxMesh.new()
			trigger_preview.mesh.size = size
			set_size = size
		
	else:
		trigger_preview.hide()
		set_size = Vector3.ZERO
	
	
func _on_body_entered(body) -> void:
	if body.is_in_group("player") and body.has_method("respawn"):
		body.respawn()
