extends Node2D

@onready var enemy_ffm: Node2D = $enemy_ffm
@onready var player_ffm: Node2D = $player_ffm
@onready var units: Node2D = $units
@onready var enemies: Node2D = $enemies

const CELL_SIZE: int = 16 #matches to the size of one tile

func _ready():
	for enemy in enemies.get_children():
		enemy.control = "enemy"

func _input(event: InputEvent) -> void:
	if(event.is_action("right_click")):
		var new_grid: Array = player_ffm.generate_new_grid(
			get_target_grid_position(get_viewport().get_mouse_position())
		)
		player_ffm.grid = new_grid
		for unit in units.get_children():
			unit.grid = new_grid

func get_target_grid_position(pos: Vector2):
	var grid_pos: Vector2 = Vector2.ZERO
	grid_pos.x = (floori(pos.x / CELL_SIZE))
	grid_pos.y = (floori(pos.y / CELL_SIZE))
	return grid_pos

func _on_enemy_path_trigger_1_body_entered(body: Node2D) -> void:
	if(body.control == "player"):
		return
		
	body.grid = enemy_ffm.grids[0]


func _on_enemy_path_trigger_2_body_entered(body: Node2D) -> void:
	if(body.control == "player"):
		return
		
	body.grid = enemy_ffm.grids[1]


func _on_enemy_path_trigger_3_body_entered(body: Node2D) -> void:
	if(body.control == "player"):
		return
		
	body.grid = enemy_ffm.grids[2]


func _on_enemy_path_trigger_4_body_entered(body: Node2D) -> void:
	if(body.control == "player"):
		return
		
	body.grid = enemy_ffm.grids[3]
