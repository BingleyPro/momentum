extends RayCast3D

func unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if is_colliding():
			var target = get_collider()
			
			if target.has_method("interact"):
				target.interact()
