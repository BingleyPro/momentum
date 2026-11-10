extends Area3D

@onready var trigger_preview = $TriggerPreview

func _ready() -> void:
	trigger_preview.hide()
	
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body) -> void:
	if not body.is_in_group("player"):
		return
		
	# Finished level
