extends Area3D

@export_range(1, 10, 1, "or_greater") var checkpoint_number: int

@onready var spawn_point = $SpawnLocation

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body) -> void:
	if not body.is_in_group("player"):
		return
		
	if checkpoint_number <= body.get("checkpoint_number"):
		return
	
	body.activate_checkpoint(spawn_point.global_transform, checkpoint_number)
