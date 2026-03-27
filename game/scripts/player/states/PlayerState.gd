class_name PlayerState
extends Node

#region Public
func enter(_previous_state: StringName = &"") -> void:
	pass


func exit() -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func get_transition() -> StringName:
	return &""
#endregion

#region Helpers
func get_actor() -> PlayerController:
	
	var machine_ := get_parent() as PlayerStateMachine
	
	assert(machine_ != null, "PlayerState must be parented under PlayerStateMachine")
	assert(machine_.actor != null, "PlayerStateMachine actor must be assigned before state access")
	
	return machine_.actor
#endregion
