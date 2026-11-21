extends Area3D

## The level that players can access when finishing the current level.
@export_file("*.tscn") var next_level = ""

func _ready() -> void:
	
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("finish_level"):
		body.finish_level(next_level)
