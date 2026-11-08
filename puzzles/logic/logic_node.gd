extends Node

signal state_update(state: bool)

enum GateType {DIRECT, AND, OR, NOT}

@export var gate_type: GateType = GateType.DIRECT
@export var inputs: Array[Node] = []
@export var outputs: Array[Node] = []

var is_on: bool = false

func _ready() -> void:
	for input_node in inputs:
		if is_instance_valid(input_node):
			if input_node.has_signal("state_update"):
				input_node.connect("state_update", _on_input_changed)
	evaluate()
				
func _on_input_changed(_state) -> void:
	evaluate()

func evaluate() -> void:
	var states: Array[bool] = []
	
	# Get each state (false/true)
	for input_node in inputs:
		if not is_instance_valid(input_node):
			return
			
		var value = input_node.get("is_on")
		
		if typeof(value) != TYPE_BOOL:
			push_warning("Logic input must have a boolean is_on property.")
			return
			
		states.append(value)
		
	if states.is_empty():
		return
		
	var result = false
	
	match gate_type:
		GateType.DIRECT:
			result = states[0]
			
		GateType.AND:
			result = true
			for state in states:
				if not state:
					result = false
					
		GateType.OR:
			result = false
			for state in states:
				if state:
					result = true
					
		GateType.NOT:
			result = not states[0]
			
	
	var changed = result != is_on
	is_on = result
		
	for output_node in outputs:
		if is_instance_valid(output_node):
			if output_node.has_method("set_active"):
				output_node.set_active(is_on)
					
	if changed:
		state_update.emit(is_on)
