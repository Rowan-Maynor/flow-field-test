extends CharacterBody2D

@export var speed: float = 100.0  # Pixels per second
@onready var flow_field_manager: Node2D = get_node("/root/Default/flow_field_manager") # Assign in editor or code

func _ready():
	print(get_node("/root/Default/flow_field_manager"))

func _physics_process(_delta: float) -> void:
	# Move along the flow field
	if flow_field_manager:
		var direction: Vector2 = flow_field_manager.get_direction_at(global_position)
		if direction != Vector2.ZERO:
			velocity = direction.normalized() * speed
			move_and_slide()
