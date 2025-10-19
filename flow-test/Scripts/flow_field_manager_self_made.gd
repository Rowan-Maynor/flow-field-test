extends Node2D

var debug: bool = true

var cell_size: int = 16
@warning_ignore("integer_division")
var grid_width: int = floori(960 / cell_size) #this will be 60 when finalized for 16x16
@warning_ignore("integer_division")
var grid_height: int = floori(540 / cell_size) #this will be 33 when finalized for 16x16

var target: Vector2 = Vector2(10, 10)

var grid: Array = [] #this will store data using [x][y]

var neighbors: Array = [
	Vector2.UP,
	Vector2.RIGHT,
	Vector2.DOWN,
	Vector2.LEFT,
	Vector2(1, -1),
	Vector2(1, 1),
	Vector2(-1, 1),
	Vector2(-1, -1)
]

var neighbor_queue: Array = []

func _ready():
	grid = generate_new_grid(target)
	$"../units/Unit".connect("request_grid", handle_request_grid)
	if(debug == true):
		queue_redraw()

func _input(event: InputEvent):
	if event.is_action_pressed("right_click"):
		if(debug == true):
			queue_redraw()
		
	if event.is_action_pressed("left_click"):
		var pos: Vector2 = get_target_grid_position(get_viewport().get_mouse_position())
		print(grid[pos.x][pos.y].cost)
		print(grid[pos.x][pos.y].flow_vector)

func _draw():
	for x in range(grid_width):
		for y in range(grid_height):
			var pos = Vector2(x * cell_size, y * cell_size)
			#var cost: int = grid[x][y].cost
			#var fill_color: Color = Color(255, 0, 0, float(cost) / 50)
			#draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), fill_color, true)
			draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), Color.BLACK, false, 2.0)
			if(grid[x][y].flow_vector != Vector2.ZERO):
				@warning_ignore("integer_division")
				var center = pos + Vector2(cell_size / 2, cell_size / 2)
				var line_end = center + grid[x][y].flow_vector * (cell_size * 0.5)
				draw_line(center, line_end, Color.BLUE, 1.0)

func get_target_grid_position(pos: Vector2):
	var grid_pos: Vector2 = Vector2.ZERO
	grid_pos.x = (floori(pos.x / cell_size))
	grid_pos.y = (floori(pos.y / cell_size))
	return grid_pos

func generate_new_grid(new_target: Vector2):
	var new_grid: Array = []
	
	for x in range(grid_width):
		var column: Array = []
		for y in range(grid_height):
			var cell: Dictionary = {
				"index": Vector2i(x, y),
				"position": Vector2(x * cell_size, y * cell_size),
				"visited": false,
				"cost":  0.0,
				"flow_vector": Vector2.ZERO
			}
			column.append(cell)
		new_grid.append(column)
	
	neighbor_queue = []
	neighbor_queue.append(new_target)
	new_grid[new_target.x][new_target.y].visited = true
	calculate_costs(new_grid, new_target)
	return new_grid

func is_valid_cell(x: int, y: int):
	return x >= 0 and x < grid_width and y >= 0 and y < grid_height

func is_diagonal(pos: Vector2):
	return pos == Vector2(-1, -1) or pos == Vector2(1, -1) or pos == Vector2(1, 1) or pos == Vector2(-1, 1)

func calculate_costs(target_grid: Array, new_target: Vector2):
	while(neighbor_queue.is_empty() == false):
		var pos: Vector2 = neighbor_queue.pop_front()
		for neighbor in neighbors:
			var next_x: int = int(pos.x + neighbor.x)
			var next_y: int = int(pos.y + neighbor.y)
			var next_vector: Vector2 = Vector2(next_x, next_y)
			if(is_valid_cell(next_x, next_y)):
				if(target_grid[next_x][next_y].visited == false):
					target_grid[next_x][next_y].visited = true
					var cost_mod: float = 0
					if(is_diagonal(neighbor)):
						cost_mod += 1.414
					else:
						cost_mod += 1.0
					target_grid[next_x][next_y].cost = target_grid[pos.x][pos.y].cost + cost_mod
					neighbor_queue.append(next_vector)
	
	calculate_vectors(target_grid, new_target)

func calculate_vectors(target_grid: Array, new_target: Vector2):
	for x in range(grid_width):
		for y in range(grid_height):
			var min_cost: float = -1
			var min_neighbor_pos: Vector2 = Vector2.ZERO
			for neighbor in neighbors:
				var nx: int = x + neighbor.x
				var ny: int = y + neighbor.y
				if(is_valid_cell(nx, ny)):
					var neighbor_cost: float = target_grid[nx][ny].cost
					if(neighbor_cost < min_cost or min_cost == -1):
						min_cost = neighbor_cost
						min_neighbor_pos = target_grid[nx][ny].position
			
			target_grid[x][y].flow_vector = (min_neighbor_pos - target_grid[x][y].position).normalized()
	
	target_grid[new_target.x][new_target.y].flow_vector = Vector2.ZERO
	

func handle_request_grid(body: CharacterBody2D, new_target: Vector2):
	var new_grid: Array = generate_new_grid(new_target)
	body.grid = new_grid
	grid = new_grid
