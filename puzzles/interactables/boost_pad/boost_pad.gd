extends Area3D

## The speed added in the direction of the boost pad.
@export_range(0.0, 30.0, 0.5, "suffix:m/s", "or_greater") var boost_amount = 6.0
## The maximum speed that the player can travel.
@export_range(0.0, 50.0, 0.5, "suffix:m/s", "or_greater") var max_speed = 20.0
## Whether the boost pad is active.
@export var enabled = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body) -> void:
	if not enabled:
		return
		
	var direction = global_basis.x
	
	if body.is_in_group("player"):
		body.boost(direction, boost_amount, max_speed)
	elif body.is_in_group("pickupable"):
		direction.y = 0
		body.linear_velocity += direction.normalized() * boost_amount
		
func set_active(active: bool) -> void:
	enabled = active
