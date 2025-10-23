extends Node2D

var debug: bool = true

const CELL_SIZE: int = 16
@warning_ignore("integer_division")
var grid_width: int = floori(960 / CELL_SIZE) #this will be 60 when finalized for 16x16
@warning_ignore("integer_division")
var grid_height: int = floori(540 / CELL_SIZE) #this will be 33 when finalized for 16x16

var target: Vector2 = Vector2(10, 10)

var grid: Array = [] #this will store data using [x][y]

#Using this will properly propogate costs in a BFS
const NEIGHBORS: Array = [
	Vector2.UP,
	Vector2.RIGHT,
	Vector2.DOWN,
	Vector2.LEFT,
]

#Using this when calculating flow will prioritize 4 way cardinal directions over diagonals
const NEIGHBORS_FLOW: Array = [
	Vector2.UP,
	Vector2.RIGHT,
	Vector2.DOWN,
	Vector2.LEFT,
	Vector2(1, -1),
	Vector2(1, 1),
	Vector2(-1, 1),
	Vector2(-1, -1),
]

var cell_queue: Array = []

func _input(event: InputEvent):
	if event.is_action_pressed("right_click"):
		if(debug == true):
			queue_redraw()
		
	if event.is_action_pressed("left_click"):
		if(grid):
			var pos: Vector2 = get_target_grid_position(get_viewport().get_mouse_position())
			print("cost: ", grid[pos.x][pos.y].cost)
			print("vector: ", grid[pos.x][pos.y].flow_vector)
			print("index: ", grid[pos.x][pos.y].index)
			print("position: ", grid[pos.x][pos.y].position)
			print("mouse_position: ", get_viewport().get_mouse_position())

func _draw():
	if grid.is_empty():
		return
	for x in range(grid_width):
		for y in range(grid_height):
			var pos = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			var cost: int = grid[x][y].cost
			var fill_color: Color = Color(255, 0, 0, float(cost)/100)
			draw_rect(Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE)), fill_color, true)
			draw_rect(Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE)), Color.BLACK, false, 2.0)
			if(grid[x][y].flow_vector != Vector2.ZERO):
				@warning_ignore("integer_division")
				var center = pos + Vector2(CELL_SIZE / 2, CELL_SIZE / 2)
				var line_end = center + grid[x][y].flow_vector * (CELL_SIZE * 0.5)
				draw_line(center, line_end, Color.BLUE, 2.0)

func get_target_grid_position(pos: Vector2):
	var grid_pos: Vector2 = Vector2.ZERO
	grid_pos.x = (floori(pos.x / CELL_SIZE))
	grid_pos.y = (floori(pos.y / CELL_SIZE))
	return grid_pos

func generate_new_grid(new_target: Vector2):
	var new_grid: Array = []
	
	for x in range(grid_width):
		var column: Array = []
		for y in range(grid_height):
			var cell: Dictionary = {
				"index": Vector2i(x, y),
				"position": Vector2(x * CELL_SIZE, y * CELL_SIZE),
				"visited": false,
				"cost":  0.0,
				"flow_vector": Vector2.ZERO
			}
			column.append(cell)
		new_grid.append(column)
	
	cell_queue = []
	cell_queue.append(new_target)
	new_grid[new_target.x][new_target.y].cost = 0
	calculate_costs(new_grid, new_target)
	return new_grid

func is_valid_cell(x: int, y: int):
	return x >= 0 and x < grid_width and y >= 0 and y < grid_height

func is_diagonal(pos: Vector2):
	return pos == Vector2(-1, -1) or pos == Vector2(1, -1) or pos == Vector2(1, 1) or pos == Vector2(-1, 1)

func calculate_costs(new_grid: Array, new_target: Vector2):
	while(cell_queue.is_empty() == false):
		var curr_cell: Vector2 = cell_queue.pop_front()
		new_grid[curr_cell.x][curr_cell.y].visited = true
		for neighbor in NEIGHBORS:
			var next_x: int = int(curr_cell.x + neighbor.x)
			var next_y: int = int(curr_cell.y + neighbor.y)
			var next_vector: Vector2 = Vector2(next_x, next_y)
			if(is_valid_cell(next_x, next_y) and not new_grid[next_x][next_y].visited):
				new_grid[next_x][next_y].visited = true
				var cost_total = new_grid[curr_cell.x][curr_cell.y].cost + 1
				
				#generate a collision check for walls/units
				var space_state = get_world_2d().direct_space_state
				var shape: RectangleShape2D = RectangleShape2D.new()
				shape.size = Vector2(8, 8)
				
				var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
				query.shape = shape
				query.transform = Transform2D(0, new_grid[next_x][next_y].position + Vector2(8, 8))
				query.collision_mask = 2
				query.collide_with_areas = true
				query.collide_with_bodies = true
				
				#check if units blocking (layer 2)
				var results: Array = space_state.intersect_shape(query)
				if not results.is_empty():
					cost_total += 5
					
				new_grid[next_x][next_y].cost = cost_total
				cell_queue.append(next_vector)
	
	calculate_vectors(new_grid, new_target)

func calculate_vectors(new_grid: Array, new_target: Vector2):
	for x in range(grid_width):
		for y in range(grid_height):
			var min_cost: float = 9999
			var min_neighbor_pos: Vector2 = Vector2.ZERO
			for neighbor in NEIGHBORS_FLOW:
				var nx: int = x + neighbor.x
				var ny: int = y + neighbor.y
				if(is_valid_cell(nx, ny)):
					var neighbor_cost: float = new_grid[nx][ny].cost
					if(neighbor_cost < min_cost):
						min_cost = neighbor_cost
						min_neighbor_pos = new_grid[nx][ny].position
			
			new_grid[x][y].flow_vector = (min_neighbor_pos - new_grid[x][y].position).normalized()
	
	new_grid[new_target.x][new_target.y].flow_vector = Vector2.ZERO
	
