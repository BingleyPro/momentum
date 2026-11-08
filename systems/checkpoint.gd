extends Area3D

@export_range(1, 10, 1, "or_greater") var checkpoint_number: int

@export_group("Reset")
@export var reset_nodes: Array[Node] = []

@onready var spawn_point = $SpawnLocation
@onready var trigger_preview = $TriggerPreview

var saved_states = {}

func _ready() -> void:
	trigger_preview.hide()
	
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body) -> void:
	if not body.is_in_group("player"):
		return
		
	if checkpoint_number <= body.get("checkpoint_number"):
		return
		
	save_puzzle_state()
	
	body.activate_checkpoint(spawn_point.global_transform, checkpoint_number, self)
	
func save_puzzle_state() -> void:
	saved_states.clear()
	
	for node in reset_nodes:
		if is_instance_valid(node):
			if node.has_method("get_checkpoint_state"):
				saved_states[node] = node.get_checkpoint_state()
				
func restore_puzzle_state() -> void:
	for node in saved_states:
		if is_instance_valid(node):
			if node.has_method("restore_checkpoint_state"):
				node.restore_checkpoint_state(saved_states[node])
