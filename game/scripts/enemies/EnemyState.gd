class_name EnemyState
extends Node

var queued_transition: StringName = &""

#region Public
func enter(_previous_state: StringName = &"") -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func get_transition() -> StringName:
	return queued_transition


func transition_to(state_name_: StringName) -> void:
	queued_transition = state_name_


func clear_transition() -> void:
	queued_transition = &""
#endregion

#region Helpers
func get_actor() -> EnemyAIController:
	var machine_ := get_parent() as EnemyStateMachine

	assert(machine_ != null, "EnemyState must be parented under EnemyStateMachine")
	assert(machine_.actor != null, "EnemyStateMachine actor must be assigned before state access")

	return machine_.actor
#endregion
