@tool
extends Node3D

enum GenerationMode {
	FLOOR_TILES,
	AREA
}

# Scenes
const FLOOR_2M = "res://building/floor_2m.tscn"
const FLOOR_4M = "res://building/floor_4m.tscn"

const WALL_SCENES = {
	1: preload("res://building/wall_1m.tscn"),
	2: preload("res://building/wall_2m.tscn"),
	4: preload("res://building/wall_4m.tscn"),
	8: preload("res://building/wall_8m.tscn")
}

const GRID_SIZE = 1.0
const WALL_HEIGHT = 2.0

@export_group("Generation")
## Floor tiles mode generates wall tiles around a given set of floors. Area mode generate walls over a specific rectangular prism based area.
@export var generation_mode: GenerationMode = GenerationMode.FLOOR_TILES

## The parent node to the floors to use.
@export var floor_root: Node3D

@export_group("Rectangle Area")
## One corner of the rectangular section.
@export var area_corner_a: Marker3D
## The opposite corner of the rectangular section.
@export var area_corner_b: Marker3D

## The height at which walls start when using area mode.
@export var area_base_y = 0.0

@export_group("Ramp Settings")

@export var ramp_root: Node3D

@export_group("Actions")

## Regenerate the walls based on the given selection and mode.
@export_tool_button("Regenerate Walls") var regenerate_button: Callable = regenerate_walls

var layers: Dictionary = {}

func regenerate_walls() -> void:
	# Remove previously generated walls
	var old_walls = get_node_or_null("GeneratedWalls")
	if old_walls:
		old_walls.free()
		
	var generated_walls = Node3D.new()
	generated_walls.name = "GeneratedWalls"
	add_child(generated_walls)
	
	var edited_scene = get_tree().edited_scene_root
	
	if edited_scene:
		generated_walls.owner = edited_scene
		
	layers = {}
	
	match generation_mode:
		GenerationMode.FLOOR_TILES:
			generate_from_floor_tiles()
			
		GenerationMode.AREA:
			generate_from_area()
			
	var total_walls = 0
	
	for layer_key in layers:
		var layer = layers[layer_key]
		
		var cells = layer["cells"]
		var base_y = layer["base_y"]
		
		generate_layer_walls(cells, base_y, generated_walls)
		
	total_walls = generated_walls.get_child_count()
	
	print("Wall Generator: Generated %d wall segments." % total_walls)
		
	if ramp_root != null:
		generate_ramp_walls(ramp_root, generated_walls)
		
func generate_from_floor_tiles() -> void:
	if floor_root == null:
		push_error("Wall Generator: Assign a floor root.")
		return
		
	print("Floor root: ", floor_root.get_path())
		
	var floor_instances: Array[Node3D] = []
	
	collect_floor_instances(floor_root, floor_instances)
	
	print("Total floors found: ", floor_instances.size())
	
	if floor_instances.is_empty():
		push_error("Wall Generator: No floor tiles were found on the root.")
		return
		
	for floor_instance in floor_instances:
		add_floor_to_grid(floor_instance)
		
	print("Total layers registered: ", layers.size())
	
func collect_floor_instances(node: Node, result: Array[Node3D]) -> void:
	print("Checking: ", node.name, " | Type: ", node.get_class(), " | Scene: ", node.scene_file_path)
	if node is Node3D:
		var scene_path = node.scene_file_path
		
		if scene_path == FLOOR_2M or scene_path == FLOOR_4M:
			print("FOUND FLOOR: ", node.name)
			result.append(node)
		
	# Recursive
	for child in node.get_children():
		collect_floor_instances(child, result)
	
func add_floor_to_grid(floor_instance: Node3D) -> void:
	var collision = find_collision_shape(floor_instance)
	
	if collision == null or not collision.shape is BoxShape3D:
		return
		
	var box = collision.shape as BoxShape3D
	
	var half_x = box.size.x / 2.0
	var half_z = box.size.z / 2.0
	
	var min_x = INF
	var max_x = -INF
	var min_z = INF
	var max_z = -INF
	
	for x_sign in [-1.0, 1.0]:
		for z_sign in [-1.0, 1.0]:
			var corner = Vector3(x_sign * half_x, 0.0, z_sign * half_z)
			
			var world_corner = collision.to_global(corner)
			var local_corner = to_local(world_corner)
			
			min_x = minf(min_x, local_corner.x)
			max_x = maxf(max_x, local_corner.x)
			
			min_z = minf(min_z, local_corner.z)
			max_z = maxf(max_z, local_corner.z)
			
	var start_x = floori(min_x + 0.001)
	var end_x = ceili(max_x - 0.001)
	
	var start_z = floori(min_z + 0.001)
	var end_z = ceili(max_z - 0.001)
	
	var floor_position = to_local(floor_instance.global_position)
	var layer_key = roundi(floor_position.y * 100.0)
	
	var layer = layers.get(layer_key, {
		"base_y": floor_position.y,
		"cells": {}
	})
	
	var cells = layer["cells"]
	
	for x in range(start_x, end_x):
		for z in range(start_z, end_z):
			cells[Vector2i(x, z)] = true
			
	layer["cells"] = cells
	layers[layer_key] = layer
	
func find_collision_shape(node: Node) -> CollisionShape3D:
	if node is CollisionShape3D:
		return node
		
	for child in node.get_children():
		var result = find_collision_shape(child)
		
		if result != null:
			return result
	return null
	
func generate_from_area() -> void:
	return
	
func generate_layer_walls(cells: Dictionary, base_y: float, parent: Node3D) -> void:
	var edge_groups = {}
	
	for cell in cells:
		var x: int = cell.x
		var z: int = cell.y
		
		# north
		if not cells.has(Vector2i(x, z - 1)):
			add_edge(edge_groups, "N:%d" % z, x)
			
		# South
		if not cells.has(Vector2i(x, z + 1)):
			add_edge(edge_groups, "S:%d" % (z + 1), x)
			
		# West
		if not cells.has(Vector2i(x -1, z)):
			add_edge(edge_groups, "W:%d" % x, z)
			
		# East
		if not cells.has(Vector2i(x + 1, z)):
			add_edge(edge_groups, "E:%d" % (x + 1), z)
			
	for edge_key in edge_groups:
		var positions: Array = edge_groups[edge_key]
		
		positions.sort()
		
		if positions.is_empty():
			continue
		
		var split = str(edge_key).split(":")
		var side = split[0]
		var line = int(split[1])
		
		var run_start = positions[0]
		var previous = run_start
		
		for i in range(1, positions.size()):
			var current = positions[i]
			
			if current == previous + 1:
				previous = current
				continue
				
			create_wall_run(side, line, run_start, previous + 1, base_y, parent)
			
			run_start = current
			previous = current
			
		create_wall_run(side, line, run_start, previous + 1, base_y, parent)
			
func add_edge(groups: Dictionary, key: String, position: int) -> void:
	if not groups.has(key):
		groups[key] = []
		
	groups[key].append(position)
	
func create_wall_run(side: String, line: int, start: int, end: int, base_y: float, parent: Node3D) -> void:
	var remaining = end - start
	var current_position = start
	
	# Use the largest avaiable wall scenes
	# e.g 13m -> 8m + 4m + 1m
	while remaining > 0:
		var segment_length = 1
		
		for candidate in [8, 4, 2, 1]:
			if candidate <= remaining:
				segment_length = candidate
				break
				
		create_wall_segment(side, line, current_position, segment_length, base_y, parent)
		
		current_position += segment_length
		remaining -= segment_length
		
func create_wall_segment(side: String, line: int, start: int, length: int, base_y: float, parent: Node3D) -> void:
	var scene: PackedScene = WALL_SCENES[length]
	
	var wall = scene.instantiate() as Node3D
	
	parent.add_child(wall)
	
	var edited_scene = get_tree().edited_scene_root
	
	if edited_scene:
		wall.owner = edited_scene
		
	var wall_position = Vector3.ZERO
	var wall_rotation = 0.0
	
	match side:
		"N":
			wall_position = Vector3(
				start,
				base_y,
				line
			)
			wall_rotation = 0.0
			
		"S":
			wall_position = Vector3(
				start + length,
				base_y,
				line
			)
			wall_rotation = PI
			
		"W":
			wall_position = Vector3(
				line,
				base_y,
				start + length
			)
			wall_rotation = PI / 2.0
			
		"E":
			wall_position = Vector3(
				line,
				base_y,
				start
			)
			wall_rotation = -PI / 2.0
			
	wall.position = wall_position
	wall.rotation.y = wall_rotation
	
	wall.name = "Generated_%s_%d_%dm" % [
		side,
		start,
		length
	]

func collect_ramp_shapes(node: Node, result: Array[CSGPolygon3D]) -> void:
	if node is CSGPolygon3D:
		var ramp = node as CSGPolygon3D
		
		if ramp.mode == CSGPolygon3D.MODE_DEPTH and ramp.polygon.size() == 3:
			result.append(ramp)
			
	for child in node.get_children():
		collect_ramp_shapes(child, result)

func generate_ramp_walls(root: Node3D, parent: Node3D) -> void:
	var ramps: Array[CSGPolygon3D] = []
	collect_ramp_shapes(root, ramps)
	
	print("Wall Generator: Found %d ramps." % ramps.size())
	
	for ramp in ramps:
		print("Processing ramp: ", ramp.get_path())
		
		var start: Vector2 = ramp.polygon[0]
		var finish: Vector2 = ramp.polygon[2]
		
		var horizontal_length = absf(finish.x - start.x)
		
		if horizontal_length <= 0.001:
			continue
		
		generate_ramp_side(ramp, start, horizontal_length, 0.0, parent)
		
		generate_ramp_side(ramp, start, horizontal_length, -ramp.depth, parent)

func generate_ramp_side(ramp: CSGPolygon3D, start: Vector2, ramp_length: float, side_z: float, parent: Node3D) -> void:
	var remaining = ramp_length
	var current_distance = 0.0
	
	while remaining > 0.001:
		var segment_length = 1
		
		for candidate in [8, 4, 2, 1]:
			if candidate <= remaining + 0.001:
				segment_length = candidate
				break
				
		var wall_scene = WALL_SCENES[segment_length]
		var wall = wall_scene.instantiate() as Node3D
		
		parent.add_child(wall)
		
		var midpoint_x = start.x + current_distance
		
		var ramp_local_position = Vector3(midpoint_x, 0.0, side_z)
		
		wall.global_position = ramp.to_global(ramp_local_position)
		wall.global_rotation = Vector3.ZERO
		
		var edited_scene = get_tree().edited_scene_root
		if edited_scene:
			wall.owner = edited_scene
			
		wall.name = "RampWall_%dm" % segment_length
		
		print("   Generated ramp wall: ", segment_length, "m")
		
		current_distance += segment_length
		remaining -= segment_length
