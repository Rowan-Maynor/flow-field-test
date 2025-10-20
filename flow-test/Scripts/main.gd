extends Node2D

@onready var flow_field_manager: Node2D = $flow_field_manager
@onready var units: Node2D = $units

const CELL_SIZE: int = 16 #matches to the size of one tile

func _input(event: InputEvent) -> void:
	if(event.is_action("right_click")):
		var new_grid: Array = flow_field_manager.generate_new_grid(
			get_target_grid_position(get_viewport().get_mouse_position())
		)
		flow_field_manager.grid = new_grid
		for unit in units.get_children():
			unit.grid = new_grid

func get_target_grid_position(pos: Vector2):
	var grid_pos: Vector2 = Vector2.ZERO
	grid_pos.x = (floori(pos.x / CELL_SIZE))
	grid_pos.y = (floori(pos.y / CELL_SIZE))
	return grid_pos
