extends Node2D

var cell_size: int = 16
@warning_ignore("integer_division")
var grid_width: int = floori(960 / cell_size) #this will be 60 when finalized for 16x16
@warning_ignore("integer_division")
var grid_height: int = floori(540 / cell_size) #this will be 33 when finalized for 16x16

var target: Vector2 = Vector2(10, 10)

var grid: Array = [] #this will store data using [x][y]

var neighbors: Array = [
	Vector2.UP,
	Vector2(1, -1),
	Vector2.RIGHT,
	Vector2(1, 1),
	Vector2.DOWN,
	Vector2(-1, 1),
	Vector2.LEFT,
	Vector2(-1, -1)
]

var neighbor_queue: Array = []

func _ready():
	grid = generate_new_grid()
	queue_redraw()

func _input(event: InputEvent):
	if event.is_action_pressed("right_click"):
		grid = generate_new_grid()
		target = get_target_grid_position(get_viewport().get_mouse_position())
		neighbor_queue = []
		neighbor_queue.append(target)
		grid[target.x][target.y].visited = true
		calculate_costs()
		print(target)
		queue_redraw()
		
	if event.is_action_pressed("left_click"):
		var pos: Vector2 = get_target_grid_position(get_viewport().get_mouse_position())
		print(grid[pos.x][pos.y].cost)

func _draw():
	for x in range(grid_width):
		for y in range(grid_height):
			var pos = Vector2(x * cell_size, y * cell_size)
			var cost: int = grid[x][y].cost
			var fill_color: Color = Color(255, 0, 0, float(cost) / 50)
			print(fill_color)
			draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), fill_color, true)
			draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), Color.BLACK, false, 2.0)

func get_target_grid_position(pos: Vector2):
	var grid_pos: Vector2 = Vector2.ZERO
	grid_pos.x = (floori(pos.x / cell_size))
	grid_pos.y = (floori(pos.y / cell_size))
	return grid_pos

func generate_new_grid():
	var new_grid: Array = []
	
	for x in range(grid_width):
		var column: Array = []
		for y in range(grid_height):
			var cell: Dictionary = {
				"index": Vector2i(x, y),
				"position": Vector2(x * cell_size, y * cell_size),
				"visited": false,
				"cost":  0,
				"flow_vector": Vector2.ZERO
			}
			column.append(cell)
		new_grid.append(column)
	
	return new_grid

func is_valid_cell(x: int, y: int):
	return x >= 0 and x < grid_width and y >= 0 and y < grid_height

func calculate_costs():
	while(neighbor_queue.is_empty() == false):
		var pos: Vector2 = neighbor_queue.pop_front()
		for neighbor in neighbors:
			var next_x: int = int(pos.x + neighbor.x)
			var next_y: int = int(pos.y + neighbor.y)
			var next_vector: Vector2 = Vector2(next_x, next_y)
			if(is_valid_cell(next_x, next_y)):
				if(grid[next_x][next_y].visited == false):
					grid[next_x][next_y].visited = true
					var cost_mod: int = check_for_collisions(next_vector)
					grid[next_x][next_y].cost = grid[pos.x][pos.y].cost + cost_mod
					neighbor_queue.append(next_vector)

func check_for_collisions(_pos: Vector2):
	var cost_mod: int = 1
	return cost_mod
