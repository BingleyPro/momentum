extends Node

signal state_update(state: bool)

enum GateType {AND, OR, NOT}

@export var inputs: Array[NodePath]
@export var type: GateType = GateType.AND

var is_on: bool = false

func interact() -> void:
	state_update.emit(true)
