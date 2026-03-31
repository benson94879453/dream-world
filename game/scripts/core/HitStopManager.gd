extends Node

var active_hitstops: Array[Dictionary] = []

#region Core Lifecycle
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func _process(delta_: float) -> void:
	var entry_index_: int = active_hitstops.size() - 1
	while entry_index_ >= 0:
		var entry_: Dictionary = active_hitstops[entry_index_]
		var target_: Node = entry_.get("target", null) as Node
		if not is_instance_valid(target_):
			active_hitstops.remove_at(entry_index_)
			entry_index_ -= 1
			continue

		entry_["remaining_time"] = maxf(float(entry_.get("remaining_time", 0.0)) - delta_, 0.0)
		active_hitstops[entry_index_] = entry_

		if float(entry_["remaining_time"]) <= 0.0:
			_restore_subtree(entry_)
			active_hitstops.remove_at(entry_index_)

		entry_index_ -= 1
#endregion

#region Public
func request_hit_stop(target_: Node, duration_ms_: int, time_scale_: float = 0.0) -> void:
	if target_ == null or duration_ms_ <= 0:
		return
	if not is_instance_valid(target_) or not target_.is_inside_tree():
		return

	var duration_seconds_: float = maxf(float(duration_ms_) / 1000.0, 0.0)
	if duration_seconds_ <= 0.0:
		return

	var existing_index_: int = _find_existing_entry_index(target_)
	if existing_index_ != -1:
		var existing_entry_: Dictionary = active_hitstops[existing_index_]
		existing_entry_["remaining_time"] = maxf(float(existing_entry_.get("remaining_time", 0.0)), duration_seconds_)
		active_hitstops[existing_index_] = existing_entry_
		return

	var node_states_: Array[Dictionary] = []
	_capture_subtree_states(target_, node_states_)
	_freeze_subtree(node_states_, time_scale_)

	active_hitstops.append({
		"target": target_,
		"remaining_time": duration_seconds_,
		"time_scale": clampf(time_scale_, 0.0, 1.0),
		"node_states": node_states_
	})
#endregion

#region Helpers
func _find_existing_entry_index(target_: Node) -> int:
	for entry_index_ in range(active_hitstops.size()):
		var existing_target_: Node = active_hitstops[entry_index_].get("target", null) as Node
		if existing_target_ == target_:
			return entry_index_
	return -1


func _capture_subtree_states(node_: Node, node_states_: Array[Dictionary]) -> void:
	var entry_ := {
		"node": node_,
		"processing": node_.is_processing(),
		"physics_processing": node_.is_physics_processing(),
		"processing_input": node_.is_processing_input(),
		"processing_unhandled_input": node_.is_processing_unhandled_input(),
		"processing_unhandled_key_input": node_.is_processing_unhandled_key_input(),
		"processing_shortcut_input": node_.is_processing_shortcut_input(),
		"processing_internal": node_.is_processing_internal(),
		"physics_processing_internal": node_.is_physics_processing_internal()
	}

	var timer_: Timer = node_ as Timer
	if timer_ != null:
		entry_["timer_paused"] = timer_.paused

	node_states_.append(entry_)

	for child_ in node_.get_children():
		var child_node_: Node = child_ as Node
		if child_node_ == null:
			continue
		_capture_subtree_states(child_node_, node_states_)


func _freeze_subtree(node_states_: Array[Dictionary], time_scale_: float) -> void:
	var should_freeze_fully_: bool = time_scale_ < 1.0
	if not should_freeze_fully_:
		return

	for state_ in node_states_:
		var node_: Node = state_.get("node", null) as Node
		if not is_instance_valid(node_):
			continue

		node_.set_process(false)
		node_.set_physics_process(false)
		node_.set_process_input(false)
		node_.set_process_unhandled_input(false)
		node_.set_process_unhandled_key_input(false)
		node_.set_process_shortcut_input(false)
		node_.set_process_internal(false)
		node_.set_physics_process_internal(false)

		var timer_: Timer = node_ as Timer
		if timer_ != null:
			timer_.paused = true


func _restore_subtree(entry_: Dictionary) -> void:
	var node_states_ = entry_.get("node_states", [])
	if typeof(node_states_) != TYPE_ARRAY:
		return

	for state_ in node_states_:
		if typeof(state_) != TYPE_DICTIONARY:
			continue

		var node_: Node = state_.get("node", null) as Node
		if not is_instance_valid(node_):
			continue

		node_.set_process(bool(state_.get("processing", false)))
		node_.set_physics_process(bool(state_.get("physics_processing", false)))
		node_.set_process_input(bool(state_.get("processing_input", false)))
		node_.set_process_unhandled_input(bool(state_.get("processing_unhandled_input", false)))
		node_.set_process_unhandled_key_input(bool(state_.get("processing_unhandled_key_input", false)))
		node_.set_process_shortcut_input(bool(state_.get("processing_shortcut_input", false)))
		node_.set_process_internal(bool(state_.get("processing_internal", false)))
		node_.set_physics_process_internal(bool(state_.get("physics_processing_internal", false)))

		var timer_: Timer = node_ as Timer
		if timer_ != null and state_.has("timer_paused"):
			timer_.paused = bool(state_.get("timer_paused", false))
#endregion
