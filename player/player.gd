extends CharacterBody3D

@export_category("Movement")
@export_group("Velocity")
@export_range(0.0, 10.0, 0.5, "suffix:m/s") var JUMP_VELOCITY = 4.5
@export_range(0.0, 20.0, 0.5, "suffix:m/s") var WALK_SPEED = 5.0
@export_range(0.0, 25.0, 0.5, "suffix:m/s") var SPRINT_SPEED = 9.0

@export_group("Acceleration")
@export_range(0.0, 100.0, 1.0, "suffix:m/s/s") var GROUND_ACCELERATION = 50.0
@export_range(0.0, 75.0, 1.0, "suffix:m/s/s") var GROUND_FRICTION = 25.0
@export_range(0.0, 20.0, 0.1, "suffix:m/s/s") var AIR_ACCELERATION = 3.0
@export_range(0.0, 5.0, 0.05, "suffix:m/s/s") var AIR_FRICTION = 0.2

const GROUND_TURN_GRIP = 35.0

var mouse_sensitivity: float = 0.002

@onready var head = $Head

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
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

	if Input.is_action_just_pressed("escape"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	var grounded = is_on_floor()
	
	if not grounded:
		velocity += get_gravity() * delta
		
	if grounded and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("left", "right", "forwards", "backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Player should move faster forwards
	var backward_amount = maxf(0.0, input_dir.y)
	
	var horizontal_velocity = Vector3(
		velocity.x, 0, velocity.z
	)
	
	var acceleration = GROUND_ACCELERATION if grounded else AIR_ACCELERATION
	var friction = GROUND_FRICTION if grounded else AIR_FRICTION
	
	var target_speed = WALK_SPEED
	if grounded and Input.is_action_pressed("sprint"):
		target_speed = SPRINT_SPEED
	
	# Make walking backwards just slightly slower
	target_speed += lerpf(1.0, 0.9, backward_amount)
	"""
	# Ground movement
	if grounded:
		if direction != Vector3.ZERO:
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
				"""
	
	# Apply friction
	horizontal_velocity = horizontal_velocity.move_toward(
		Vector3.ZERO,
		friction * delta
	)
	
	if grounded and direction != Vector3.ZERO:
		var parallel_velocity = direction * horizontal_velocity.dot(direction)
		var sideways_velocity = horizontal_velocity - parallel_velocity
		
		horizontal_velocity -= sideways_velocity.limit_length(GROUND_TURN_GRIP * delta)
	
	# Apply movement acceleration
	if direction != Vector3.ZERO:
		# Calculate speed in direction using dot product!
		var speed_in_dir = horizontal_velocity.dot(direction)
		var speed_to_add = target_speed - speed_in_dir
		
		if speed_to_add > 0:
			var acceleration_step = min(
				acceleration * delta,
				speed_to_add
			)
			
			horizontal_velocity += direction * acceleration_step
			
	# Update velocity
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	
	# Collisions
	move_and_slide()
