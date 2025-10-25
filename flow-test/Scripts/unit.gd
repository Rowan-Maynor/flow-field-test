extends CharacterBody2D

var grid: Array
var speed: int = 100
var control: String

func _physics_process(_delta: float):
	if(grid.is_empty() == false):
		var curr_square: Vector2 = get_target_grid_position(self.position)
		velocity = grid[curr_square.x][curr_square.y].flow_vector * speed
		move_and_slide()

func get_target_grid_position(pos: Vector2):
	var grid_pos: Vector2 = Vector2.ZERO
	grid_pos.x = (floori(pos.x / 16))
	grid_pos.y = (floori(pos.y / 16))
	return grid_pos
