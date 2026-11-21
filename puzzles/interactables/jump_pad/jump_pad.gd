@tool
extends Node3D

@export var enabled = true
@export var launch_velocity: Vector3
@export var cooldown: float = 0.4

@export var preview_start_offset = Vector3(0, 1, 0)
@export var landing_world_y = 0.0

var last_launch_time = -100000

@onready var detector: Area3D = $Detector
@onready var animation_player = $AnimationPlayer
@onready var trajectory: MeshInstance3D = $TrajectoryPreview
@onready var landing_marker: MeshInstance3D = $LandingMarker

var traj_mesh: ImmediateMesh
var traj_material
var previous_preview_state = []

func _ready() -> void:
	if Engine.is_editor_hint():
		traj_mesh = ImmediateMesh.new()
		trajectory.mesh = traj_mesh
		
		traj_material = StandardMaterial3D.new()
		traj_material.albedo_color = Color.CYAN
		traj_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		
		update_preview()
	else:
		trajectory.hide()
		landing_marker.hide()
		
		detector.body_entered.connect(_on_body_entered)
		
func _process(_delta):
	if not Engine.is_editor_hint():
		return
		
	var current_state = [
		global_transform,
		launch_velocity,
		preview_start_offset,
		landing_world_y
	]
	
	if current_state != previous_preview_state:
		previous_preview_state = current_state
		update_preview()
		
func update_preview():
	traj_mesh.clear_surfaces()
	
	var basis = global_basis.orthonormalized()
	
	var start_position = global_position + basis * preview_start_offset
	
	var start_velocity = basis * launch_velocity
	
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	
	# Finds time when player reaches landing height
	var discriminant = (start_velocity.y * start_velocity.y + 2 * gravity * (start_position.y - landing_world_y))
	
	if discriminant < 0:
		landing_marker.hide()
		return
		
	var flight_time = (
		start_velocity.y + sqrt(discriminant)
	) / gravity
	
	if flight_time <= 0:
		landing_marker.hide()
		return
		
	traj_mesh.surface_begin(
		Mesh.PRIMITIVE_LINE_STRIP,
		traj_material
	)
	
	var loop = 40
	
	var landing_position = start_position
	
	for i in range(loop):
		var x = flight_time * float(i) / (loop - 1)
		
		var world_position = (
			start_position + start_velocity * x + Vector3.DOWN * 0.5 * gravity * x * x
		)
		
		traj_mesh.surface_add_vertex(trajectory.to_local(world_position))
		
		landing_position = world_position
		
	traj_mesh.surface_end()
	
	landing_marker.global_position = landing_position
	landing_marker.show()
		

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or not enabled:
		return
		
	if not body.has_method("launch"):
		return
		
	var now = Time.get_ticks_msec()
	
	if now - last_launch_time < cooldown * 1000:
		return
		
	last_launch_time = now
		
	var launch = global_basis.orthonormalized() * launch_velocity
		
	body.launch(launch)

	#animation_player.play("launch")
