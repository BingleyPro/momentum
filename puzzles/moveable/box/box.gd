extends RigidBody3D

func get_checkpoint_state():
	return {
		"transform": global_transform,
	}
	
func restore_checkpoint_state(state) -> void:
	global_transform = state["transform"]
	
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	reset_physics_interpolation()
