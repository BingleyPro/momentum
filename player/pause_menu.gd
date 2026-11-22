extends PanelContainer

signal resume_requested

func _unhandled_input(event) -> void:
	if event.is_action_pressed("escape"):
		get_viewport().set_input_as_handled()
		resume_requested.emit()
