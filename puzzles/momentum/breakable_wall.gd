extends StaticBody3D

signal state_update(state: bool)

## The speed required to break this wall.
@export_range(1.0, 20.0, 0.5, "suffix:m/s") var break_speed = 10.0
## Amount of speed lost to to the object that smashes through.
@export_range(0.0, 1.0, 0.05) var speed_loss = 0.15

@onready var detector = $"Detector"
@onready var shape = $"CollisionShape3D"
@onready var mesh = $"MeshInstance3D"

var is_on = false

func _physics_process(delta):
	if is_on:
		return
	
	for body: PhysicsBody3D in detector.get_overlapping_bodies():
		var velocity = Vector3.ZERO
		
		if body.is_in_group("player"):
			velocity = body.velocity
		elif body.is_in_group("pickupable"):
			velocity = body.linear_velocity
		else:
			continue
			
		var horizontal_speed = Vector2(velocity.x, velocity.z).length()
		
		if horizontal_speed >= break_speed:
			shatter(body)
			return
			
func shatter(body):
	is_on = true
	shape.set_deferred("disabled", true)
	mesh.hide()
	
	var keep = 1.0 - speed_loss
	if body.is_in_group("player"):
		body.velocity.x *= keep
		body.velocity.z *= keep
	elif body.is_in_group("pickupable"):
		body.linear_velocity *= keep
		
	state_update.emit(true)
	
func get_checkpoint_state():
	return is_on
	
func restore_checkpoint_state(state):
	is_on = state
	shape.set_deferred("disabled", is_on)
	mesh.visible = not is_on
	state_update.emit(is_on)
