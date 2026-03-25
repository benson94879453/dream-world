class_name PlayerStateMachine
extends Node

@export var initial_state: NodePath = "Idle"

var actor: PlayerController
var current_state: PlayerState

#region Core Lifecycle
func _ready() -> void:
	actor = get_parent() as PlayerController
	assert(actor != null, "PlayerStateMachine parent must be PlayerController")

	var current_state_ := get_node_or_null(initial_state) as PlayerState
	if current_state_ == null:
		current_state_ = _find_first_state()
	assert(current_state_ != null, "PlayerStateMachine failed to resolve initial state")

	current_state = current_state_
	current_state.enter()


func _physics_process(delta_: float) -> void:
	assert(current_state != null, "PlayerStateMachine current_state must be valid before physics update")

	current_state.physics_update(delta_)
	var next_state_name_ := current_state.get_transition()
	if next_state_name_.is_empty():
		return

	transition_to(next_state_name_)
#endregion

#region State Management
func transition_to(state_name_: StringName) -> void:
	var next_state_ := get_node_or_null(NodePath(str(state_name_))) as PlayerState
	assert(next_state_ != null, "PlayerStateMachine failed to resolve next state: %s" % state_name_)

	if next_state_ == current_state:
		return

	current_state.exit()
	var previous_state_ := current_state
	current_state = next_state_
	current_state.enter(previous_state_.name)
#endregion

#region Helpers
func _find_first_state() -> PlayerState:
	for child_ in get_children():
		if child_ is PlayerState:
			return child_ as PlayerState
	return null
#endregion
