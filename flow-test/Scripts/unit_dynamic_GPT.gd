extends CharacterBody2D

@export var speed = 100.0
@export var goal_position: Vector2

@onready var flow_field_manager = get_parent().get_node("/root/Default/flow_field_manager")

func _ready():
	# Register unit in group for dynamic cost updates
	if not is_in_group("units"):
		add_to_group("units")

func _physics_process(_delta):
	if flow_field_manager == null:
		return

	# Compute a flow field for this unit's goal if it doesn't exist
	var goal_id = get_instance_id()
	if not flow_field_manager.flow_fields.has(goal_id):
		flow_field_manager.compute_flow_field(goal_position, goal_id)

	# Get desired direction from the flow field
	var dir = flow_field_manager.get_unit_direction(self, goal_id)
	if dir == Vector2.ZERO:
		return

	# Move the unit using CharacterBody2D
	velocity = dir * speed
	move_and_slide()
