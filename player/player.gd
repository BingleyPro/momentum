extends CharacterBody3D

@export_category("Movement")
@export_group("Velocity")
@export_range(0.0, 10.0, 0.5, "suffix:m/s") var JUMP_VELOCITY = 4.5
@export_range(0.0, 20.0, 0.5, "suffix:m/s") var WALK_SPEED = 5.0
@export_range(0.0, 25.0, 0.5, "suffix:m/s") var SPRINT_SPEED = 9.0

@export_group("Acceleration")
@export_range(0.0, 100.0, 1.0, "suffix:m/s/s") var GROUND_ACCELERATION = 50.0
@export_range(0.0, 75.0, 1.0, "suffix:m/s/s") var GROUND_FRICTION = 25.0
@export_range(0.0, 10.0, 0.1, "suffix:m/s/s") var AIR_ACCELERATION = 3.0
@export_range(0.0, 1.0, 0.05, "suffix:m/s/s") var AIR_FRICTION = 0.2

@export_group("Sliding")
@export_range(0.0, 20.0, 0.5, "suffix:m/s") var SLIDE_MIN_SPEED = 6.0
@export_range(0.0, 20.0, 1.0, "suffix:m/s") var SLIDE_FRICTION = 3.0
@export_range(0.0, 10.0, 1.0, "suffix:m/s") var SLIDE_STEER = 2.0
@export_range(0.0, 3.0, 0.05, "suffix:m") var SLIDE_CAMERA_DROP = 0.7
@export_range(0.0, 10.0, 1.0, "suffix:m/s") var CAMERA_TRANSITION_SPEED = 5.0

@export_category("Settings")
@export var mouse_sensitivity: float = 0.002
@export var is_active = true

@export_group("Pickup")
@export var follow_speed = 8.0
@export var follow_strength = 10.0

@export_category("Debug")
@export var start_at_checkpoint: Node

var held_object: RigidBody3D = null
var original_gravity = 1.0
var original_rotation_lock = false

var sliding = false
var standing_head_y: float

var checkpoint_number = 0
var current_checkpoint = null

@onready var head = $Head
@onready var raycast = $Head/RayCast3D
@onready var hold_point = $Head/HoldPoint

var checkpoint_location: Transform3D

func _ready() -> void:
	standing_head_y = head.position.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	checkpoint_location = global_transform
	
	if not is_active:
		queue_free()
		
	if start_at_checkpoint:
		start_at_checkpoint.save_puzzle_state()
		
		activate_checkpoint(start_at_checkpoint.find_child("SpawnLocation").global_transform, start_at_checkpoint.get("checkpoint_number"), start_at_checkpoint)
		respawn()
	
func _unhandled_input(event) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			# Rotate the player's head for mouse movement
			rotate_y(-event.screen_relative.x * mouse_sensitivity)
			head.rotate_x(-event.screen_relative.y * mouse_sensitivity)
			head.rotation.x = clampf(
				head.rotation.x,
				deg_to_rad(-85),
				deg_to_rad(85)
			)
			
	elif event.is_action_pressed("interact"):
		# If holding object, drop it
		if is_instance_valid(held_object):
			drop_object()
			return
			
		if not raycast.is_colliding():
			return
		
		var target = raycast.get_collider()
		
		if target is RigidBody3D and target.is_in_group("pickupable"):
			pickup_object(target)
			
		elif target.has_method("interact"):
			target.interact()

	elif Input.is_action_just_pressed("escape"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	elif Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	elif Input.is_action_just_pressed("respawn"):
		respawn()

func pickup_object(object: RigidBody3D) -> void:
	held_object = object
	
	original_gravity = object.gravity_scale
	original_rotation_lock = object.lock_rotation
	
	object.gravity_scale = 0.0
	object.lock_rotation = true
	object.linear_velocity = Vector3.ZERO
	object.angular_velocity = Vector3.ZERO
	
	object.add_collision_exception_with(self)
	self.add_collision_exception_with(object)
	raycast.add_exception(object)
	
func drop_object() -> void:
	if not is_instance_valid(held_object):
		held_object = null
		return
		
	held_object.gravity_scale = original_gravity
	held_object.lock_rotation = original_rotation_lock
	
	held_object.remove_collision_exception_with(self)
	self.remove_collision_exception_with(held_object)
	raycast.remove_exception(held_object)
	
	held_object = null
	
func activate_checkpoint(spawn: Transform3D, number: int, checkpoint) -> void:
	checkpoint_location = spawn
	
	current_checkpoint = checkpoint
	
	if number:
		checkpoint_number = number
	
func respawn() -> void:
	if is_instance_valid(held_object):
		drop_object()
		
	if is_instance_valid(current_checkpoint):
		current_checkpoint.restore_puzzle_state()
	
	global_transform = checkpoint_location
	velocity = Vector3.ZERO
	sliding = false
	head.position.y = standing_head_y
	head.rotation.x = 0.0
	
	reset_physics_interpolation()
	
func _physics_process(delta):
	var grounded = is_on_floor()
	
	if not grounded:
		velocity += get_gravity() * delta
		
	if grounded and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY
		sliding = false
		grounded = false

	var input_dir = Input.get_vector("left", "right", "forwards", "backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Player should move faster forwards
	var backward_amount = maxf(0.0, input_dir.y)
	
	var horizontal_velocity = Vector3(
		velocity.x, 0, velocity.z
	)

	var target_speed = WALK_SPEED
	if grounded and Input.is_action_pressed("sprint"):
		target_speed = SPRINT_SPEED
	
	# Make walking backwards just slightly slower
	target_speed *= lerpf(1.0, 0.9, backward_amount)

	# Ground movement
	if grounded:
		# Sliding
		if sliding:
			horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO,
			SLIDE_FRICTION * delta)
			
			# Limited sideways steering
			if direction != Vector3.ZERO:
				var motion_direction = horizontal_velocity.normalized()
				
				var steering_direction = direction - motion_direction * direction.dot(motion_direction)
				
				horizontal_velocity += steering_direction * SLIDE_STEER * delta
		
		elif direction != Vector3.ZERO:
			var desired_velocity = direction * target_speed
			
			horizontal_velocity = horizontal_velocity.move_toward(
				desired_velocity,
				GROUND_ACCELERATION * delta
			)
		else:
			horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO,
			GROUND_FRICTION * delta)
	else:
		# Air movement
		horizontal_velocity = horizontal_velocity.move_toward(
		Vector3.ZERO,
		AIR_FRICTION * delta)
		
		if direction != Vector3.ZERO:
			var speed_in_dir = horizontal_velocity.dot(direction)
			var speed_to_add = target_speed - speed_in_dir
			
			if speed_to_add > 0:
				var acceleration_step = min(
					AIR_ACCELERATION * delta,
					speed_to_add
				)
				
				horizontal_velocity += direction * acceleration_step
				
	if sliding:
		if not grounded or not Input.is_action_pressed("slide") or horizontal_velocity.length() < 2.0:
			sliding = false
	elif grounded and Input.is_action_just_pressed("slide"):
		if horizontal_velocity.length() >= SLIDE_MIN_SPEED:
			# Add initial speed boost
			horizontal_velocity += direction * (horizontal_velocity.length() - 4.0)
			
			sliding = true
				
	# Lower camera if sliding
	var target_head_y = standing_head_y
	
	if sliding:
		target_head_y -= SLIDE_CAMERA_DROP
		
	head.position.y = move_toward(
		head.position.y,
		target_head_y,
		CAMERA_TRANSITION_SPEED * delta
	)

	# Update velocity
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	
	# Collisions
	move_and_slide()
	
	# Held object
	if is_instance_valid(held_object):
		var displacement = hold_point.global_position - held_object.global_position
		
		if displacement.length() > 3.5:
			drop_object()
			return
		
		var desired_velocity = displacement * follow_speed
		
		var force = (desired_velocity - held_object.linear_velocity) * held_object.mass * follow_strength
		
		force = force.limit_length(held_object.mass * 120.0)
		
		held_object.apply_central_force(force)
