extends Node2D

# -------------------------
# Grid settings
# -------------------------
@export var cell_size = 16.0
@export var grid_width = 60
@export var grid_height = 34

# -------------------------
# Cost arrays
# -------------------------
var static_costs = []
var dynamic_costs = []

# -------------------------
# Flow fields per goal (key = goal_id = unit instance_id)
# -------------------------
var flow_fields = {}

# -------------------------
# Neighbor offsets
# -------------------------
var neighbors = [
	Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(-1, -1)
]
var neighbor_costs = [1.0, 1.414, 1.0, 1.414, 1.0, 1.414, 1.0, 1.414]

# -------------------------
# Update interval for dynamic costs
# -------------------------
var update_timer = 0.0
const UPDATE_INTERVAL = 0.25

func _ready():
	# Initialize cost arrays
	static_costs.resize(grid_width * grid_height)
	dynamic_costs.resize(grid_width * grid_height)
	for i in range(static_costs.size()):
		static_costs[i] = 0.0
		dynamic_costs[i] = 0.0
	compute_static_costs()

func _process(delta):
	update_timer += delta
	if update_timer >= UPDATE_INTERVAL:
		update_timer = 0.0
		update_dynamic_costs()

# -------------------------
# Helpers
# -------------------------
func get_field_index(x, y):
	return y * grid_width + x

func get_field_coords(idx):
	return Vector2i(idx % grid_width, idx / grid_width)

func is_in_bounds(x, y):
	return x >= 0 and x < grid_width and y >= 0 and y < grid_height

func get_field_index_from_world(pos):
	var gx = int(pos.x / cell_size)
	var gy = int(pos.y / cell_size)
	return get_field_index(gx, gy)

# -------------------------
# Static costs (walls)
# -------------------------
func compute_static_costs():
	var space_state = get_world_2d().direct_space_state
	for y in range(grid_height):
		for x in range(grid_width):
			var idx = get_field_index(x, y)
			static_costs[idx] = get_cell_collision_cost(Vector2i(x, y), space_state)

func get_cell_collision_cost(grid_pos, space_state):
	var shape = RectangleShape2D.new()
	shape.size = Vector2(cell_size, cell_size)
	var cell_center = Vector2(grid_pos.x + 0.5, grid_pos.y + 0.5) * cell_size
	var xform = Transform2D(0, cell_center)

	var params = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = xform
	params.collision_mask = (1 << 0) # walls = layer 1
	params.collide_with_bodies = true
	params.collide_with_areas = true

	var results = space_state.intersect_shape(params, 1)
	if results.is_empty():
		return 0.0
	return 1000.0

# -------------------------
# Dynamic unit costs
# -------------------------
func update_dynamic_costs():
	# Reset
	for i in range(dynamic_costs.size()):
		dynamic_costs[i] = 0.0

	# Add units
	for unit in get_tree().get_nodes_in_group("units"):
		var idx = get_field_index_from_world(unit.global_position)
		dynamic_costs[idx] = 10.0
		var coords = get_field_coords(idx)
		for oy in range(-1, 2): # -1,0,1
			for ox in range(-1, 2):
				var nx = coords.x + ox
				var ny = coords.y + oy
				if not is_in_bounds(nx, ny):
					continue
				var n_idx = get_field_index(nx, ny)
				dynamic_costs[n_idx] += 5.0 / (abs(ox) + abs(oy) + 1)

# -------------------------
# Compute BFS flow field for a goal
# -------------------------
func compute_flow_field(goal_pos, goal_id):
	var costs = []
	costs.resize(grid_width * grid_height)
	for i in range(costs.size()):
		costs[i] = INF

	var directions = []
	directions.resize(grid_width * grid_height)
	for i in range(directions.size()):
		directions[i] = Vector2.ZERO

	var target_idx = get_field_index_from_world(goal_pos)
	costs[target_idx] = 0.0

	var queue = [target_idx]

	while queue.size() > 0:
		var current_idx = queue.pop_front()
		var current_coords = get_field_coords(current_idx)
		var current_cost = costs[current_idx]

		for i in range(neighbors.size()):
			var offset = neighbors[i]
			var nx = current_coords.x + offset.x
			var ny = current_coords.y + offset.y
			if not is_in_bounds(nx, ny):
				continue
			var n_idx = get_field_index(nx, ny)
			var travel_cost = neighbor_costs[i] + static_costs[n_idx] + dynamic_costs[n_idx]
			var total_cost = current_cost + travel_cost
			if total_cost < costs[n_idx]:
				costs[n_idx] = total_cost
				queue.append(n_idx)

	# Compute flow directions
	for y in range(grid_height):
		for x in range(grid_width):
			var idx = get_field_index(x, y)
			if costs[idx] == INF:
				continue
			var min_cost = costs[idx]
			var best_dir = Vector2.ZERO
			for offset in neighbors:
				var nx = x + offset.x
				var ny = y + offset.y
				if not is_in_bounds(nx, ny):
					continue
				var n_idx = get_field_index(nx, ny)
				if costs[n_idx] < min_cost:
					min_cost = costs[n_idx]
					best_dir = Vector2(offset.x, offset.y)
			directions[idx] = best_dir

	flow_fields[goal_id] = directions

# -------------------------
# Get movement direction for a unit
# -------------------------
func get_unit_direction(unit, goal_id):
	if not flow_fields.has(goal_id):
		return Vector2.ZERO
	var idx = get_field_index_from_world(unit.global_position)
	var dir = flow_fields[goal_id][idx]
	var gradient = get_cost_gradient(unit.global_position)
	return (dir - gradient * 0.4).normalized()

func get_cost_gradient(world_pos):
	var idx = get_field_index_from_world(world_pos)
	var coords = get_field_coords(idx)
	var left = dynamic_costs[get_field_index(coords.x - 1, coords.y)] if coords.x > 0 else 0.0
	var right = dynamic_costs[get_field_index(coords.x + 1, coords.y)] if coords.x < grid_width - 1 else 0.0
	var up = dynamic_costs[get_field_index(coords.x, coords.y - 1)] if coords.y > 0 else 0.0
	var down = dynamic_costs[get_field_index(coords.x, coords.y + 1)] if coords.y < grid_height - 1 else 0.0
	return Vector2(right - left, down - up).normalized()
