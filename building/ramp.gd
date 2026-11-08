@tool
extends Node3D

# Temp script for finding good ramp dimensions

@export_group("Dimensions")

@export_range(1.0, 20.0, 1.0, "suffix:m", "or_greater") var ramp_length = 4.0:
	set(value):
		ramp_length = value
		update_ramp()

@export_range(1.0, 20.0, 1.0, "suffix:m", "or_greater") var ramp_width = 2.0:
	set(value):
		ramp_width = value
		update_ramp()

@export_range(1.0, 10.0, 1.0, "suffix:m", "or_greater") var ramp_height = 1.0:
	set(value):
		ramp_height = value
		update_ramp()
		
func _ready() -> void:
	update_ramp()
	
func update_ramp() -> void:
	var mesh = get_node_or_null("CSGPolygon3D")
	
	if mesh == null: return
	
	mesh.mode = CSGPolygon3D.MODE_DEPTH
	
	mesh.polygon = PackedVector2Array([
		Vector2(0,0),
		Vector2(ramp_length, 0),
		Vector2(ramp_length, ramp_height)
	])
	
	mesh.depth = ramp_width
	
	mesh.position.z = ramp_width / 2.0
