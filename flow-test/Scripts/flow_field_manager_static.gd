extends Node2D

#most of this generated with grok, and actually works pretty well so far

# Grid settings
# must use pixel perfect ratios or everything will break
@export var cell_size: float = 16.0  # Pixels per cell, fits 960x540
@warning_ignore("narrowing_conversion")
@export var grid_width: int = ceili(960 / cell_size) # 960 project size
@warning_ignore("narrowing_conversion")
@export var grid_height: int = ceili(540 / cell_size) # 540 project size
@export var target_pos: Vector2i = Vector2i(5, 5)  # Approx center of grid

# Internal arrays
var costs: Array = []  # Float array for path costs
var directions: Array = []  # Vector2 array for flow directions
var seen: Dictionary = {}  # For BFS

func _ready() -> void:
	# Initialize arrays
	costs.resize(grid_width * grid_height)
	costs.fill(INF)
	directions.resize(grid_width * grid_height)
	directions.fill(Vector2.ZERO)
	# Compute initial flow field
	update_flow_field(target_pos)

func get_field_index(x: int, y: int) -> int:
	# Convert grid coordinates to flat array index
	return y * grid_width + x

func get_grid_coords(idx: int) -> Vector2i:
	# Convert flat index to grid coordinates
	@warning_ignore("integer_division")
	return Vector2i(idx % grid_width, idx / grid_width)

func update_flow_field(target: Vector2i) -> void:
	# Compute costs and directions for the flow field
	# Reset arrays
	costs.fill(INF)
	directions.fill(Vector2.ZERO)
	seen.clear()
	
	# BFS queue
	var queue: Array[int] = []
	var target_idx: int = get_field_index(target.x, target.y)
	queue.append(target_idx)
	seen[target_idx] = true
	costs[target_idx] = 0.0
	
	# Neighbor offsets (up, up-right, right, down-right, down, down-left, left, up-left)
	var neighbors: Array[Vector2i] = [
		Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(1, 0), Vector2i(1, 1),
		Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(-1, -1)
	]
	# Costs for neighbors (cardinal = 1.0, diagonal = sqrt(2))
	var neighbor_costs: Array[float] = [
		1.0, 1.414,
		1.0, 1.414,
		1.0, 1.414,
		1.0, 1.414
	]
	
	# BFS for costs
	while not queue.is_empty():
		var current_idx: int = queue.pop_front()
		var current: Vector2i = get_grid_coords(current_idx)
		var current_cost: float = costs[current_idx]
		
		#ChatGPT changed this for implementation, may break everything
		for i in range(neighbors.size()):
			var offset: Vector2i = neighbors[i]
			var nx: int = current.x + offset.x
			var ny: int = current.y + offset.y
			
			if nx < 0 or nx >= grid_width or ny < 0 or ny >= grid_height:
				continue
			
			var n_idx := get_field_index(nx, ny)
			
			# Base travel cost (cardinal or diagonal)
			var travel_cost := neighbor_costs[i]
			
			# Add obstacle influence
			var collision_cost := get_cell_collision_cost(nx, ny)
			
			if collision_cost >= 1000.0:
				# Walls = hard block, skip cell
				continue
			
			var total_cost := current_cost + travel_cost + collision_cost
			
			if total_cost < costs[n_idx]:
				costs[n_idx] = total_cost
				queue.append(n_idx)

	
	# Compute directions: point to lowest-cost neighbor
	for y in range(grid_height):
		for x in range(grid_width):
			var idx: int = get_field_index(x, y)
			if costs[idx] == INF:
				continue
			var min_cost: float = costs[idx]
			var best_dir: Vector2 = Vector2.ZERO
			for offset in neighbors:
				var nx: int = x + offset.x
				var ny: int = y + offset.y
				var n_idx: int = get_field_index(nx, ny)
				if nx >= 0 and nx < grid_width and ny >= 0 and ny < grid_height:
					var neighbor_cost: float = costs[n_idx]
					if neighbor_cost < min_cost:
						min_cost = neighbor_cost
						best_dir = Vector2(offset.x, offset.y)
			directions[idx] = best_dir
	
	# Request redraw
	queue_redraw()

func get_direction_at(pos: Vector2) -> Vector2:
	# Get flow direction at a world position (pixels)
	var grid_pos: Vector2i = Vector2i(pos / cell_size)
	if grid_pos.x >= 0 and grid_pos.x < grid_width and grid_pos.y >= 0 and grid_pos.y < grid_height:
		return directions[get_field_index(grid_pos.x, grid_pos.y)]
	return Vector2.ZERO

func _draw() -> void:
	# Draw debug arrows for the flow field
	for y in range(grid_height):
		for x in range(grid_width):
			var idx: int = get_field_index(x, y)
			if costs[idx] == INF:
				continue
			var dir: Vector2 = directions[idx]
			if dir == Vector2.ZERO:
				continue
			# Center of the cell in world coords
			var cell_center: Vector2 = Vector2(x + 0.5, y + 0.5) * cell_size
			var dir_norm: Vector2 = dir.normalized()
			var arrow_end: Vector2 = cell_center + dir_norm * cell_size * 0.4
			# Draw arrow line
			draw_line(cell_center, arrow_end, Color.BLUE, 1.0)
			# Draw arrowhead (simple triangle)
			var arrow_size: float = cell_size * 0.2  # Scale with cell_size
			var perp: Vector2 = Vector2(-dir_norm.y, dir_norm.x)
			var p1: Vector2 = arrow_end - dir_norm * arrow_size
			var p2: Vector2 = p1 + perp * arrow_size * 0.5
			var p3: Vector2 = p1 - perp * arrow_size * 0.5
			# Skip if points are too close (prevents triangulation errors)
			if p1.distance_to(p2) > 0.01 and p2.distance_to(p3) > 0.01 and p3.distance_to(p1) > 0.01:
				draw_colored_polygon([arrow_end, p2, p3], Color.BLUE)
	# Draw target
	var target_center: Vector2 = Vector2(target_pos.x + 0.5, target_pos.y + 0.5) * cell_size
	draw_circle(target_center, cell_size * 0.2, Color.RED)

func _input(event: InputEvent) -> void:
	# Update target position on click (for testing)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos: Vector2 = get_global_mouse_position()
		var grid_pos: Vector2i = Vector2i(mouse_pos / cell_size)
		if grid_pos.x >= 0 and grid_pos.x < grid_width and grid_pos.y >= 0 and grid_pos.y < grid_height:
			target_pos = grid_pos
			update_flow_field(target_pos)
			

#generated with ChatGPT, which is known to be meme and not work
#LMAO it does 9500 calls when I try to change the target position.
func get_cell_collision_cost(x: int, y: int) -> float:
	var space_state := get_world_2d().direct_space_state

	var shape := RectangleShape2D.new()
	shape.size = Vector2(cell_size, cell_size)

	@warning_ignore("shadowed_variable_base_class")
	var position := Vector2(x + 0.5, y + 0.5) * cell_size
	@warning_ignore("shadowed_variable_base_class")
	var transform := Transform2D(0, position)

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = transform
	params.collision_mask = (1 << 0) | (1 << 1)  # layers 1 and 2
	params.collide_with_areas = true
	params.collide_with_bodies = true

	# Run the intersection query
	var results := space_state.intersect_shape(params, 8)
	if results.is_empty():
		return 0.0

	var wall_cost := 100.0
	var unit_cost := 10.0

	for hit in results:
		var maybe_collider = hit["collider"]
		if maybe_collider is CollisionObject2D:
			var collider: CollisionObject2D = maybe_collider
			if (collider.collision_layer & (1 << 0)) != 0:
				return wall_cost
			elif (collider.collision_layer & (1 << 1)) != 0:
				return unit_cost
	
	return 0.0
