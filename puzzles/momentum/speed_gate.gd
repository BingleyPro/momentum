@tool
extends Area3D

signal state_update(state: bool)

enum Mode { PULSE, LATCH }

## The size of the speed gate in metres.
@export var size = Vector3(4, 3, 0.4):
	set(value):
		size = value
		rebuild()
## The minimum speed required to activate the gate.
@export_range(0.0, 40.0, 0.5, "suffix:m/s") var min_speed = 12.0:
	set(value):
		min_speed = value
		rebuild()
## The mode of the gate. Latch is where when the gate is triggered, and stays triggered. Pulse is where the gate only stays activate for a certain amount of time.
@export var mode: Mode = Mode.PULSE
## The amount of time for the gate to stay triggered if the mode is set to pulse.
@export_range(0.1, 20.0, 0.1, "suffix:s") var hold_time = 3.0
## Whether boxes should be counted as well as the player to activate the gate.
@export var count_boxes = true

@onready var collision_shape = $"CollisionShape3D"
@onready var mesh = $"MeshInstance3D"
@onready var label = $"Label"
@onready var timer = $"Timer"

var material: StandardMaterial3D

var is_on = false

# Colours
const COLOUR_DEFAULT = Color(0.712, 0.621, 0.246, 0.4)
const COLOUR_ON = Color(0.0, 0.825, 0.21, 0.4)
const COLOUR_FAIL = Color(0.863, 0.0, 0.0, 0.4)

func _ready() -> void:
	collision_shape.shape = collision_shape.shape.duplicate()
	mesh.mesh = mesh.mesh.duplicate()
	
	material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = COLOUR_DEFAULT
	
	mesh.material_override = material
	
	rebuild()
	
	if Engine.is_editor_hint():
		return
		
	timer.timeout.connect(_on_timeout)
	body_entered.connect(_on_body_entered)
	
func rebuild() -> void:
	if not is_node_ready():
		return
	
	var center = Vector3(size.x / 2.0, size.y / 2.0, -size.z / 2.0)
	collision_shape.shape.size = size
	collision_shape.position = center
	mesh.mesh.size = size
	mesh.position = center
	label.position = Vector3(size.x / 2.0, size.y / 2.0 + 0.4, 0)
	label.text = "%d m/s" % int(min_speed)
	
func get_speed(body) -> float:
	var velocity = Vector3.ZERO
	if body is CharacterBody3D:
		velocity = body.velocity
	elif body is RigidBody3D and count_boxes:
		velocity = body.linear_velocity
	else:
		return -1.0
	return Vector2(velocity.x, velocity.z).length()
	
func _on_body_entered(body) -> void:
	if not (body.is_in_group("player") or (count_boxes and body.is_in_group("pickupable"))):
		return
		
	var speed = get_speed(body)
	if speed < 0.0:
		return
		
	if speed >= min_speed:
		_set_on(true)
		
		if mode == Mode.PULSE:
			timer.start(hold_time)
	
	elif not is_on:
		label.text = "%.1f m/s" % speed
		var tween = create_tween()
		material.albedo_color = COLOUR_FAIL
		tween.tween_property(material, "albedo_color", COLOUR_DEFAULT, 0.6)
		tween.tween_callback(
			func():
				label.text = "%d m/s" % int(min_speed)
		)
		
func _on_timeout() -> void:
	_set_on(false)

func _set_on(value) -> void:
	if value:
		material.albedo_color = COLOUR_ON
	else:
		material.albedo_color = COLOUR_DEFAULT
		
	if value == is_on:
		return
	is_on = value
	state_update.emit(is_on)
	
func get_checkpoint_state():
	return {
		"is_on": is_on,
		"time_left": timer.time_left
	}
	
func restore_checkpoint_state(state) -> void:
	timer.stop()
	_set_on(state["is_on"])
	if state["is_on"] and state["time_left"] > 0.0:
		timer.start(state["time_left"])
