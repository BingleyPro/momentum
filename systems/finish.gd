extends Area3D

## The level that players can access when finishing the current level.
@export_file("*.tscn") var next_level = ""

@export_group("Medals")
## Time needed to beat the developer!
@export_range(0.0, 60.0, 0.1, "suffix:s", "or_greater") var dev_time: float
## Time needed for the gold medal.
@export_range(0.0, 60.0, 0.1, "suffix:s", "or_greater") var gold_time: float
## Time needed for the silver medal.
@export_range(0.0, 100.0, 0.1, "suffix:s", "or_greater") var silver_time: float
## Time needed for the gold medal.
@export_range(0.0, 150.0, 0.1, "suffix:s", "or_greater") var bronze_time: float

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body) -> void:
	if not body.is_in_group("player"):
		return
	
	var times = [gold_time, silver_time, bronze_time]
	if dev_time > 0.0:
		times.push_front(dev_time)
	
	if body.has_method("finish_level"):
		body.finish_level(next_level, times)
