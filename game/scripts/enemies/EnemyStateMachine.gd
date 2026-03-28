class_name EnemyStateMachine
extends Node

@export var initial_state: NodePath = "Idle"

var actor: EnemyAIController = null
var current_state: EnemyState = null

#region Core Lifecycle
func _ready() -> void:
	actor = get_parent() as EnemyAIController
	assert(actor != null, "EnemyStateMachine parent must be EnemyAIController")

	var current_state_: EnemyState = get_node_or_null(initial_state) as EnemyState
	if current_state_ == null:
		current_state_ = _find_first_state()
	assert(current_state_ != null, "EnemyStateMachine failed to resolve initial state")

	current_state = current_state_
	set_physics_process(false)


func _physics_process(delta_: float) -> void:
	assert(current_state != null, "EnemyStateMachine current_state must be valid before physics update")

	current_state.physics_update(delta_)
	var next_state_name_: StringName = current_state.get_transition()
	if next_state_name_.is_empty():
		return

	transition_to(next_state_name_)
#endregion

#region Public
func start() -> void:
	assert(current_state != null, "EnemyStateMachine requires a resolved current_state before start")

	current_state.clear_transition()
	set_physics_process(true)
	current_state.enter()


func transition_to(state_name_: StringName) -> void:
	var next_state_: EnemyState = get_node_or_null(NodePath(str(state_name_))) as EnemyState
	assert(next_state_ != null, "EnemyStateMachine failed to resolve next state: %s" % state_name_)

	if next_state_ == current_state:
		current_state.clear_transition()
		return

	current_state.exit()
	var previous_state_: EnemyState = current_state
	current_state = next_state_
	current_state.clear_transition()
	current_state.enter(previous_state_.name)
#endregion

#region Helpers
func _find_first_state() -> EnemyState:
	for child_ in get_children():
		if child_ is EnemyState:
			return child_ as EnemyState
	return null
#endregion
