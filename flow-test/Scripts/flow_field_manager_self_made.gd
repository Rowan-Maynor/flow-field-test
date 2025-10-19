extends Node2D

var cell_size: int = 16
@warning_ignore("integer_division")
var grid_width: int = floori(960 / cell_size) #this will be 60 when finalized for 16x16
@warning_ignore("integer_division")
var grid_height: int = floori(540 / cell_size) #this will be 33 when finalized for 16x16

var target: Vector2 = Vector2(10, 10)

var grid: Array = [] #this will store data using [x][y]

func _ready():
	grid = []
	queue_redraw()

func _input(event: InputEvent):
	if event.is_action_pressed("right_click"):
		grid = generate_new_grid()
		target = get_target_grid_position(get_viewport().get_mouse_position())
		print(target)
		print(grid[target.x][target.y])

func _draw():
	for x in range(grid_width):
		for y in range(grid_height):
			var pos = Vector2(x * cell_size, y * cell_size)
			draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), Color.RED, false, 2.0)

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
				"cost":  0,
				"flow_vector": Vector2.ZERO
			}
			column.append(cell)
		new_grid.append(column)
	
	return new_grid
