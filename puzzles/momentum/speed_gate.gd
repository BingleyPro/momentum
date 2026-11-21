extends Area3D

signal state_update(state: bool)

enum Mode { PULSE, LATCH }

@export var size = Vector3(4, 3, 0.4)
@export_range(0.0, 40.0, 0.5, "suffix:m/s") var min_speed = 12.0
@export var mode = Mode.PULSE
@export_range(0.1, 20.0, 0.1, "suffix:s") var hold_time = 3.0
@export var count_boxes = true

@onready var collision_shape = $"CollisionShape3D"
@onready var mesh = $"MeshInstance3D"
@onready var label = $"Label"
@onready var timer = $"Timer"

var material: StandardMaterial3D

var is_on = false

# Colours
const COLOUR_DEFAULT = Color(0.712, 0.621, 0.246, 1.0)
const COLOUR_ON = Color(0.0, 0.825, 0.21, 1.0)
const COLOUR_FAIL = Color(0.863, 0.0, 0.0, 1.0)

func _ready() -> void:
	material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = COLOUR_DEFAULT
	
	rebuild()
	
	if Engine.is_editor_hint():
		return
		
	timer.timeout.connect(_on_timeout)
	body_entered.connect(_on_body_entered)
	
func rebuild() -> void:
	collision_shape.shape.size = size
	mesh.mesh.size = size
	label.position = Vector3(0, size.y / 2.0 + 0.4, 0)
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
	
	elif not is_on:
		# show failure
		pass
		
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
	
	
