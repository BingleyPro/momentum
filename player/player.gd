extends CharacterBody3D

@export_category("Movement")
@export_group("Velocity")
## The velocity applied when the player jumps.
@export_range(0.0, 10.0, 0.5, "suffix:m/s") var JUMP_VELOCITY = 4.5
## The maximum speed at which the player can walk.
@export_range(0.0, 20.0, 0.5, "suffix:m/s") var WALK_SPEED = 5.0
## The maximum speed at which the player can sprint.
@export_range(0.0, 25.0, 0.5, "suffix:m/s") var SPRINT_SPEED = 9.0

@export_group("Acceleration")
## The acceleration (m/s) applied to the player while on the ground.
@export_range(0.0, 100.0, 1.0, "suffix:m/s/s") var GROUND_ACCELERATION = 50.0
## The friction (m/s) applied to the player while on the ground.
@export_range(0.0, 75.0, 1.0, "suffix:m/s/s") var GROUND_FRICTION = 25.0
## The acceleration (m/s) applied to the player while in the air
@export_range(0.0, 10.0, 0.1, "suffix:m/s/s") var AIR_ACCELERATION = 3.0
## The friction (m/s) applied to the player while in the air.
@export_range(0.0, 1.0, 0.05, "suffix:m/s/s") var AIR_FRICTION = 0.2

@export_group("Sliding")
## The minimum speed that the player must be at to start sliding.
@export_range(0.0, 20.0, 0.5, "suffix:m/s") var SLIDE_MIN_SPEED = 6.0
## The friction (m/s) applied to the player while sliding.
@export_range(0.0, 20.0, 1.0, "suffix:m/s") var SLIDE_FRICTION = 3.0
## --
@export_range(0.0, 10.0, 1.0, "suffix:m/s") var SLIDE_STEER = 2.0
## The maximum horizontal speed that slopes can push the player to while sliding.
@export_range(5.0, 50.0, 1.0 ,"suffix:m/s") var SLIDE_MAX_SPEED = 25.0
## How far down the camera drops while sliding
@export_range(0.0, 3.0, 0.05, "suffix:m") var SLIDE_CAMERA_DROP = 0.7
## What speed the camera moves down at when sliding
@export_range(0.0, 10.0, 1.0, "suffix:m/s") var CAMERA_TRANSITION_SPEED = 5.0

## The speed boost applied when the player starts sliding.
@export_range(0.0, 10.0, 0.5, "suffix:m/s") var SLIDE_BOOST = 4.0
## The cooldown between slide boosts.
@export_range(0.0, 3.0, 0.1, "suffix:s") var SLIDE_BOOST_COOLDOWN = 1.0
## --
@export_range(0.0, 3.0, 0.1, "suffix:m/s") var SLIDE_SLOPE_GRAVITY = 1.5

## The angle at which a floor counts as a slope, and requires no sprint to slide down it.
@export_range(0.0, 45.0, 1.0, "suffix:deg") var SLIDE_SLOPE_MIN_ANGLE = 8.0
# How long the player can leave the ground during a slide without the slide ending.
@export_range(0.0, 0.5, 0.01) var SLIDE_AIR_GRACE = 0.15

@export_group("Feel")
## How long the player has after leaving a platform to still be able to jump.
@export_range(0.0, 0.3, 0.01, "suffix:s") var COYOTE_TIME = 0.12
## --
@export_range(0.0, 0.3, 0.01, "suffix:s") var JUMP_BUFFER = 0.12

## The change in FOV that is applied while going above the fov max speed.
@export_range(0.0, 30.0, 1.0, "suffix:deg") var FOV_BOOST = 12.0
## The 
@export_range(5.0, 40.0, 1.0, "suffix:m/s") var FOV_MAX_SPEED = 18.0

@export_category("Audio")
## The distance between footstep sounds.
@export_range(0.5, 5.0, 0.1, "suffix:m") var STEP_LENGTH = 2.2
## The volume of wind at full speed.
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var WIND_MAX_VOLUME = -8.0
## The speed at which wind starts to be heard.
@export_range(0.0, 20.0, 0.5, "suffix:m/s") var WIND_START_SPEED = 7.0

@export_category("Settings")
@export var mouse_sensitivity: float = 0.002
## Whether this player is active.
@export var is_active = true

@export_group("Pickup")
@export var follow_speed = 8.0
@export var follow_strength = 10.0
## The speed at which the player can throw an object.
@export_range(0.0, 30.0, 0.5, "suffix:m/s") var THROW_SPEED = 8.0

@export_category("Debug")
## If selected, the player will start at the given checkpoint.
@export var start_at_checkpoint: Node

const MEDAL_NAMES = ["Dev", "Gold", "Silver", "Bronze"]

const MENU_SCENE = "res://menus/main_menu.tscn"
const BEST_TIMES_FILE = "user://best_times.cfg"
const SETTINGS_FILE = "user://settings.cfg"

const SENSITIVITY_SCALE = 0.00004

var held_object: RigidBody3D = null
var original_gravity = 1.0
var original_rotation_lock = false

var sliding = false
var standing_head_y: float

var checkpoint_number = 0
var current_checkpoint = null

var will_launch = false
var pending_launch_velocity = Vector3.ZERO

var run_time = 0.0
var timer_running = false
var finished = false
var next_level_path = ""

var slide_boost_timer = 0.0
var slide_air_timer = 0.0
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var was_grounded = true

var shake = 0.0

var step_distance = 0.0
var air_fall_speed = 0.0

var base_fov: float
var hud_label: Label
var complete_label: Label

var pre_move_velocity = Vector3.ZERO

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/RayCast3D
@onready var hold_point: Marker3D = $Head/HoldPoint

@onready var prompt_panel: PanelContainer = $CanvasLayer/PromptPanel
@onready var action_label: Label = $CanvasLayer/PromptPanel/HBoxContainer/ActionLabel
@onready var canvas: CanvasLayer = $CanvasLayer
@onready var pause_menu = $CanvasLayer/PauseMenu

@onready var sensitivity_slider = $CanvasLayer/PauseMenu/VBoxContainer/Sensitivity

@onready var footstep_sound = $Footstep
@onready var wind_sound = $Wind

var checkpoint_location: Transform3D

func _ready() -> void:
	standing_head_y = head.position.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	base_fov = camera.fov
	floor_snap_length = 0.5
	build_hud()
	
	floor_max_angle = deg_to_rad(60)
	
	checkpoint_location = global_transform
	
	wind_sound.volume_db = -80.0
	wind_sound.play()
	
	pause_menu.hide()
	pause_menu.get_node("VBoxContainer/Resume").pressed.connect(set_paused.bind(false))
	pause_menu.get_node("VBoxContainer/Restart").pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	pause_menu.get_node("VBoxContainer/Menu").pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file(MENU_SCENE))
		
	pause_menu.resume_requested.connect(set_paused.bind(false))
	
	var settings = ConfigFile.new()
	settings.load(SETTINGS_FILE)
	var slider_value = settings.get_value("controls", "mouse_sensitivity", 50.0)
	sensitivity_slider.value = slider_value
	mouse_sensitivity = slider_value
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	
	if not is_active:
		queue_free()
		
	if start_at_checkpoint and OS.has_feature("editor"):
		_start_at_debug_checkpoint.call_deferred()
		
func _on_sensitivity_changed(value):
	mouse_sensitivity = value * SENSITIVITY_SCALE
	var settings = ConfigFile.new()
	settings.load(SETTINGS_FILE)
	settings.set_value("controls", "mouse_sensitivity", value)
	settings.save(SETTINGS_FILE)
		
func set_paused(value):
	get_tree().paused = value
	pause_menu.visible = value
	if value:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
func _start_at_debug_checkpoint() -> void:
	start_at_checkpoint.save_puzzle_state()
		
	activate_checkpoint(start_at_checkpoint.find_child("SpawnLocation").global_transform, start_at_checkpoint.get("checkpoint_number"), start_at_checkpoint)
	respawn()
	
func _unhandled_input(event) -> void:
	if finished:
		handle_finished_input(event)
		return
	
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
			
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_instance_valid(held_object):
			throw_object()
			
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
		set_paused(true)
		get_viewport().set_input_as_handled()
			
	elif Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	elif Input.is_action_just_pressed("respawn"):
		respawn()
		
func handle_finished_input(event) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		if next_level_path.is_empty():
			get_tree().change_scene_to_file(MENU_SCENE)
		else:
			get_tree().change_scene_to_file(next_level_path)
	elif event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("escape"):
		get_tree().change_scene_to_file(MENU_SCENE)
		
func throw_object() -> void:
	var object = held_object
	drop_object()
	
	object.linear_velocity = velocity + THROW_SPEED * -camera.global_basis.z
	
func get_horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()
		
func launch(launch_velocity: Vector3):
	pending_launch_velocity = launch_velocity
	will_launch = true
	
func add_shake(amount) -> void:
	shake = minf(shake + amount, 1.0)

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
	
	global_transform = checkpoint_location
	velocity = Vector3.ZERO
	sliding = false
	head.position.y = standing_head_y
	head.rotation.x = 0.0
	
	if is_instance_valid(current_checkpoint):
		current_checkpoint.restore_puzzle_state()
	else:
		get_tree().reload_current_scene()
	
	reset_physics_interpolation()
	
func _process(delta) -> void:
	update_hud(delta)
	if finished:
		return
	
	var action = ""
	var world_position = Vector3.ZERO
	
	if raycast.is_colliding():
		var target = raycast.get_collider()
		
		if target is RigidBody3D and target.is_in_group("pickupable"):
			action = "Pick up"
			
		elif target.has_method("interact"):
			action = "Interact"
			
		if not action.is_empty():
			world_position = (raycast.get_collision_point() + raycast.get_collision_normal() * 0.12 + Vector3.UP * 0.25)
		
	if action.is_empty():
		prompt_panel.hide()
		return
	
	if action_label.text != action:
		action_label.text = action
		prompt_panel.reset_size()
		
	prompt_panel.show()
		
	var screen_position = camera.unproject_position(world_position)
	
	prompt_panel.position = screen_position - Vector2(
		prompt_panel.size.x / 2,
		prompt_panel.size.y + 12
	)
	
func build_hud() -> void:
	# Programatically build hud
	hud_label = Label.new()
	hud_label.position = Vector2(48, 32)
	hud_label.add_theme_font_size_override("font_size", 64)
	hud_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hud_label.add_theme_constant_override("outline_size", 12)
	canvas.add_child(hud_label)
	
	complete_label = Label.new()
	complete_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	complete_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	complete_label.add_theme_font_size_override("font_size", 110)
	complete_label.add_theme_color_override("font_outline_color", Color.BLACK)
	complete_label.add_theme_constant_override("outline_size", 20)
	complete_label.hide()
	canvas.add_child(complete_label)
	
func update_hud(delta) -> void:
	if timer_running:
		run_time += delta
		
	var speed = get_horizontal_speed()
	hud_label.text = "%4.1f m/s\n%s" % [speed, format_time(run_time)]
	
	# Increase FOV
	var t = clampf(inverse_lerp(SPRINT_SPEED, FOV_MAX_SPEED, speed), 0.0, 1.0)
	camera.fov = lerpf(camera.fov, base_fov + FOV_BOOST * t, 1.0 - exp(-8.0 * delta))
	
	# Shake
	shake = maxf(shake - delta * 2.0, 0.0)
	camera.h_offset = randf_range(-1, 1) * shake * shake * 0.15
	camera.v_offset = randf_range(-1, 1) * shake * shake * 0.15
	
	# Wind sound (fades out during finish)
	var wind = clampf(inverse_lerp(WIND_START_SPEED, FOV_MAX_SPEED, speed), 0.0, 1.0)
	var target_db = linear_to_db(maxf(wind, 0.001)) + WIND_MAX_VOLUME
	wind_sound.volume_db = lerpf(wind_sound.volume_db, target_db, 1.0 - exp(-6.0 * delta))
	wind_sound.pitch_scale = lerpf(0.85, 1.25, wind)
	
func boost(direction: Vector3, amount: float, max_speed: float) -> void:
	direction.y = 0
	direction = direction.normalized()
	
	var current = velocity.dot(direction)
	
	if current < max_speed:
		velocity += direction * minf(amount, max_speed - current)
	
func get_slope_pull() -> Vector3:
	var normal = get_floor_normal()
	var g = get_gravity()
	var along = g - normal * g.dot(normal)
	
	return Vector3(along.x, 0, along.z)
	
func finish_level(next_level: String, medal_times: Array = []) -> void:
	if finished:
		return
	finished = true
	timer_running = false
	next_level_path = next_level
	
	velocity = Vector3.ZERO
	if is_instance_valid(held_object):
		drop_object()
		
	# Save time
	var file = ConfigFile.new()
	file.load(BEST_TIMES_FILE)
	
	var key = get_tree().current_scene.scene_file_path
	var best = file.get_value("times", key, INF)
	var new_best = run_time < best
	
	if new_best:
		file.set_value("times", key, run_time)
		file.save(BEST_TIMES_FILE)
		best = run_time
		
	var text = "Level Complete!\n%s" % format_time(run_time)
	text += "   NEW BEST!" if new_best else "   (best %s)" % format_time(best)
	
	var medal = get_medal(run_time, medal_times)
	if not medal.is_empty():
		text += "\n%s medal" % medal
		
	var next_target = get_next_target(run_time, medal_times)
	if not next_target.is_empty():
		text += "\n%s" % next_target
	
	text += "\n\n[Space] %s    [T] Retry    [Esc] Menu" % ("Next level" if not next_level.is_empty() else "Menu")
	
	complete_label.text = text
	complete_label.show()
	prompt_panel.hide()
	
func get_medal(time: float, medal_times: Array) -> String:
	for i in medal_times.size():
		if medal_times[i] > 0.0 and time <= medal_times[i]:
			return MEDAL_NAMES[i]
	return ""
	
func get_next_target(time: float, medal_times: Array) -> String:
	for i in range(medal_times.size() -1, -1, -1):
		if medal_times[i] > 0.0 and time > medal_times[i]:
			return "%s: under %s" % [MEDAL_NAMES[i], format_time(medal_times[i])]
	return ""
	
func update_movement_audio(delta) -> void:
	var speed = get_horizontal_speed()
	var grounded = is_on_floor()
	
	if grounded and not sliding and speed > 0.5:
		step_distance += speed * delta
		if step_distance >= STEP_LENGTH:
			step_distance = 0.0
			footstep_sound.play()
	
func format_time(seconds: float) -> String:
	var minutes = int(seconds) / 60
	return "%d:%05.2f" % [minutes, fmod(seconds, 60.0)]

func _physics_process(delta):
	if finished or get_tree().paused:
		return
	
	if will_launch:
		will_launch = false
		
		velocity = pending_launch_velocity
		sliding = false
		
		move_and_slide()
		return
	
	var grounded = is_on_floor()
	
	var on_slope = grounded and get_floor_angle() > deg_to_rad(SLIDE_SLOPE_MIN_ANGLE)
	var slope_pull = get_slope_pull() if on_slope else Vector3.ZERO
		
	slide_boost_timer = maxf(0.0, slide_boost_timer - delta)
		
	# Coyote time/jump buffer
	if grounded:
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
		
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER
	else:
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
		
	if not grounded:
		velocity += get_gravity() * delta
		
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		sliding = false
		grounded = false
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	var input_dir = Input.get_vector("left", "right", "forwards", "backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Start timer if not already running
	if not timer_running and (input_dir != Vector2.ZERO or Input.is_action_pressed("jump")):
		timer_running = true
	
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
			if slope_pull.dot(horizontal_velocity) <= 0.0:
				horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, SLIDE_FRICTION * delta)
			
			if horizontal_velocity.length() < SLIDE_MAX_SPEED:
				horizontal_velocity += slope_pull * SLIDE_SLOPE_GRAVITY * delta
			
			# Limited sideways steering
			if direction != Vector3.ZERO and horizontal_velocity.length() > 0.01:
				var motion_direction = horizontal_velocity.normalized()
				
				var steering_direction = direction - motion_direction * direction.dot(motion_direction)
				
				horizontal_velocity += steering_direction * SLIDE_STEER * delta
		
		elif direction != Vector3.ZERO:
			var desired_velocity = direction * target_speed
			
			if horizontal_velocity.length() > target_speed and horizontal_velocity.dot(direction) > 0:
				horizontal_velocity = horizontal_velocity.move_toward(
				desired_velocity,
				GROUND_FRICTION * delta
			)
			else:
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
				
	var speed = horizontal_velocity.length()
				
	if sliding:
		if grounded:
			slide_air_timer = 0.0
		else:
			slide_air_timer += delta
			
		var too_slow = speed < 2.0 and not on_slope
		
		if slide_air_timer > SLIDE_AIR_GRACE or not Input.is_action_pressed("slide") or too_slow:
			sliding = false
	elif grounded and Input.is_action_pressed("slide"):
		var just_landed = not was_grounded
		var just_pressed = Input.is_action_just_pressed("slide")
		var fast_enough = speed > SLIDE_MIN_SPEED
		var heading_downhill = on_slope and (speed < 1.0 or slope_pull.dot(horizontal_velocity) > 0.0)
		
		if heading_downhill or ((just_pressed or just_landed) and fast_enough):
			if fast_enough and (just_pressed or just_landed) and slide_boost_timer <= 0.0:
				horizontal_velocity += horizontal_velocity.normalized() * SLIDE_BOOST
				slide_boost_timer = SLIDE_BOOST_COOLDOWN
			slide_air_timer = 0.0
			sliding = true

	was_grounded = grounded
				
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
	
	floor_snap_length = 1.2 if sliding else 0.5
	
	pre_move_velocity = velocity
	
	# Collisions
	move_and_slide()
	
	update_movement_audio(delta)
	
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
