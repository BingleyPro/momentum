extends RigidBody3D

var pending_reset = null

func get_checkpoint_state():
	return {
		"transform": global_transform,
	}
	
func restore_checkpoint_state(state) -> void:
	pending_reset = state["transform"]
	sleeping = false

func _integrate_forces(state) -> void:
	if pending_reset == null:
		return
		
	state.transform = pending_reset
	state.linear_velocity = Vector3.ZERO
	state.angular_velocity = Vector3.ZERO
	pending_reset = null
	
	reset_physics_interpolation()
