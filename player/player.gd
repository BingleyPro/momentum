extends CharacterBody3D

const JUMP_VELOCITY = 4.5

const WALK_SPEED = 5
const SPRINT_SPEED = 9

const GROUND_ACCELERATION = 15
const GROUND_FRICTION = 10
const AIR_ACCELERATION = 3
const AIR_FRICTION = 0.2

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

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get the direction of player movement
	var input_dir = Input.get_vector("left", "right", "forwards", "backwards")
	
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Calculate the speed (if sprinting or not)
	var target_speed = WALK_SPEED
	
	if Input.is_action_pressed("sprint") and is_on_floor():
		target_speed = SPRINT_SPEED
	
	# Horizontal velocity calculations
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	
	if direction != Vector3.ZERO:
		# Set the desired velocity
		var desired_velocity = direction * target_speed
		
		# Set transitioning towards that desired velocity
		if is_on_floor():
			horizontal_velocity = horizontal_velocity.move_toward(
				desired_velocity,
				GROUND_ACCELERATION * delta)
		else:
			horizontal_velocity = horizontal_velocity.move_toward(
				desired_velocity,
				AIR_ACCELERATION * delta)
	else:
		# Use friction to slow down more realistically
		if is_on_floor():
			horizontal_velocity = horizontal_velocity.move_toward(
				Vector3.ZERO,
				GROUND_FRICTION * delta)
		else:
			horizontal_velocity = horizontal_velocity.move_toward(
				Vector3.ZERO,
				AIR_FRICTION * delta)
			
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	move_and_slide()
