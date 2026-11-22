@tool
extends StaticBody3D

enum GlassType { NORMAL, REINFORCED }

const GLASS_COLOURS = {
	GlassType.NORMAL: Color(1, 1, 1, 0.3),
	GlassType.REINFORCED: Color(0.086, 0.086, 0.086, 0.619)
}

signal state_update(state: bool)

## The speed required to break this wall.
@export_range(1.0, 20.0, 0.5, "suffix:m/s") var break_speed = 10.0
## Amount of speed lost to to the object that smashes through.
@export_range(0.0, 1.0, 0.05) var speed_loss = 0.15

@export var glass_type: GlassType = GlassType.NORMAL:
	set(value):
		glass_type = value
		apply_glass_type()

@onready var detector = $"Detector"
@onready var shape = $"CollisionShape3D"
@onready var mesh = $"MeshInstance3D"
@onready var label = $"Label3D"

@onready var break_sound = $AudioStreamPlayer3D

var material: StandardMaterial3D

var is_on = false

func _ready():
	material = mesh.get_surface_override_material(0).duplicate()
	mesh.set_surface_override_material(0, material)
	
	label.text = "%d m/s" % int(break_speed)
	apply_glass_type()
	
func apply_glass_type() -> void:
	if not is_node_ready():
		return
		
	var colour = GLASS_COLOURS[glass_type]
	material.albedo_color = colour

func _physics_process(_delta):
	if is_on or Engine.is_editor_hint():
		return
	
	for body in detector.get_overlapping_bodies():
		var velocity = Vector3.ZERO
		
		if body.is_in_group("player"):
			velocity = body.pre_move_velocity
		elif body.is_in_group("pickupable"):
			velocity = body.linear_velocity
		else:
			continue
			
		var horizontal_speed = Vector2(velocity.x, velocity.z).length()
		
		if horizontal_speed >= break_speed:
			shatter(body, velocity)
			return
			
func shatter(body, velocity):
	is_on = true
	shape.set_deferred("disabled", true)
	mesh.hide()
	label.hide()
	
	break_sound.play()
	
	var keep = 1.0 - speed_loss
	if body.is_in_group("player"):
		body.velocity.x = velocity.x * keep
		body.velocity.z = velocity.z * keep

		if glass_type == GlassType.NORMAL:
			body.add_shake(0.6)
		elif glass_type == GlassType.REINFORCED:
			body.add_shake(1.2)
	elif body.is_in_group("pickupable"):
		body.linear_velocity *= keep
		
	spawn_shards(body, velocity)
		
	state_update.emit(true)
	
func spawn_shards(body, velocity):
	var shard_mesh = BoxMesh.new()
	shard_mesh.size = Vector3(0.25, 0.25, 0.04)
	var shard_shape = BoxShape3D.new()
	shard_shape.size = shard_mesh.size
	var size = mesh.mesh.size
	
	for i in 60:
		var shard = RigidBody3D.new()
		shard.mass = 0.1
		shard.collision_layer = 0
		
		var m = MeshInstance3D.new()
		m.mesh = shard_mesh
		m.material_override = material
		shard.add_child(m)
		
		var c = CollisionShape3D.new()
		c.shape = shard_shape
		shard.add_child(c)
		
		get_tree().current_scene.add_child(shard)
		
		var offset = Vector3(randf_range(-0.5, 0.5) * size.x, randf_range(-0.5, 0.5) * size.y, 0)
		shard.global_position = mesh.global_transform * offset
		shard.rotation = Vector3(randf(), randf(), randf()) * TAU
		shard.linear_velocity = velocity * randf_range(0.3, 0.8) + Vector3(randf_range(-2.0, 2.0), randf_range(0.0, 3.0), randf_range(-2.0, 2.0))
		
		var tween = shard.create_tween()
		tween.tween_interval(6.0)
		tween.tween_callback(shard.queue_free)

func get_checkpoint_state():
	return is_on
	
func restore_checkpoint_state(state):
	is_on = state
	shape.set_deferred("disabled", is_on)
	mesh.visible = not is_on
	label.visible = not is_on
	state_update.emit(is_on)
