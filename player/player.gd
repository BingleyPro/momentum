extends CharacterBody3D

const JUMP_VELOCITY = 4.5

const WALK_SPEED = 5
const SPRINT_SPEED = 9

const GROUND_ACCELERATION = 25
const GROUND_FRICTION = 25
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
	var forward_amount = maxf(0.0, -input_dir.y)
	
	var horizontal_velocity = Vector3(
		velocity.x, 0, velocity.z
	)
	
	var acceleration = GROUND_ACCELERATION if grounded else AIR_ACCELERATION
	var friction = GROUND_FRICTION if grounded else AIR_FRICTION
	
	var target_speed = lerpf(WALK_SPEED - 2.0, WALK_SPEED, forward_amount)
	if grounded and Input.is_action_pressed("sprint"):
		target_speed = lerpf(SPRINT_SPEED - 1.0, SPRINT_SPEED, forward_amount)
	
	# Apply friction
	horizontal_velocity = horizontal_velocity.move_toward(
		Vector3.ZERO,
		friction * delta
	)
	
	# Apply movement acceleration
	if direction != Vector3.ZERO:
		# Calculate speed in direction using dot product!
		var speed_in_dir = horizontal_velocity.dot(direction)
		var speed_to_add = target_speed - speed_in_dir
		
		if speed_to_add > 0:
			var acceleration_step = min(
				lerpf(acceleration - 1.0, acceleration, forward_amount) * delta,
				speed_to_add
			)
			
			horizontal_velocity += direction * acceleration_step
			
	# Update velocity
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	
	# Collisions
	move_and_slide()
