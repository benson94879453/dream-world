class_name DWDialogManager
extends Node

const DialogDataResource = preload("res://game/scripts/data/DialogData.gd")
const DialogNodeDataResource = preload("res://game/scripts/data/DialogNodeData.gd")
const DialogChoiceDataResource = preload("res://game/scripts/data/DialogChoiceData.gd")

signal dialog_started(dialog_id: StringName)
signal dialog_ended(dialog_id: StringName)
signal node_changed(node_data: Resource)
signal text_advanced(text: String, speaker: String)
signal choices_presented(choices: Array)
signal dialog_action_requested(action_id: StringName)

var current_dialog: DialogDataResource = null
var current_node: DialogNodeDataResource = null
var current_choices: Array[DialogChoiceDataResource] = []
var is_dialog_active: bool = false
var dialog_flags: Dictionary = {}

#region Public
func start_dialog(dialog_data_: DialogDataResource) -> void:
	assert(dialog_data_ != null, "DialogManager.start_dialog requires DialogData")
	assert(not is_dialog_active, "DialogManager cannot start a dialog while another dialog is active")

	current_dialog = dialog_data_
	current_node = null
	current_choices.clear()
	is_dialog_active = true
	_set_player_dialog_lock(true)
	dialog_started.emit(dialog_data_.dialog_id)

	var start_node_ := current_dialog.get_node(current_dialog.start_node_id)
	_enter_node(start_node_)


func advance_text() -> void:
	if not is_dialog_active or current_node == null:
		return

	match current_node.node_type:
		DialogData.NodeType.TEXT:
			if current_node.next_node_id.is_empty():
				end_dialog()
				return

			var next_node_: DialogNodeDataResource = current_dialog.get_node(current_node.next_node_id)
			_enter_node(next_node_)

		DialogData.NodeType.CHOICE:
			return

		DialogData.NodeType.END:
			end_dialog()


func select_choice(choice_index_: int) -> void:
	if not is_dialog_active or current_node == null:
		return

	if current_node.node_type != DialogData.NodeType.CHOICE:
		return

	if choice_index_ < 0 or choice_index_ >= current_choices.size():
		return

	var choice_: DialogChoiceDataResource = current_choices[choice_index_]
	for flag_ in choice_.set_flags:
		set_flag(flag_)

	if not choice_.action_id.is_empty():
		dialog_action_requested.emit(choice_.action_id)

	if choice_.next_node_id.is_empty():
		end_dialog()
		return

	var next_node_: DialogNodeDataResource = current_dialog.get_node(choice_.next_node_id)
	_enter_node(next_node_)


func end_dialog() -> void:
	if not is_dialog_active:
		return

	var dialog_id_: StringName = current_dialog.dialog_id if current_dialog != null else &""
	current_dialog = null
	current_node = null
	current_choices.clear()
	is_dialog_active = false
	_set_player_dialog_lock(false)
	dialog_ended.emit(dialog_id_)


func has_flag(flag_name_: StringName) -> bool:
	return bool(dialog_flags.get(String(flag_name_), false))


func set_flag(flag_name_: StringName) -> void:
	if flag_name_.is_empty():
		return

	dialog_flags[String(flag_name_)] = true


func to_save_dict() -> Dictionary:
	return {
		"dialog_flags": dialog_flags.duplicate(true)
	}


func from_save_dict(data_: Dictionary) -> void:
	dialog_flags.clear()

	var raw_flags_ = data_.get("dialog_flags", {})
	if typeof(raw_flags_) != TYPE_DICTIONARY:
		return

	for flag_name_ in raw_flags_.keys():
		if bool(raw_flags_[flag_name_]):
			dialog_flags[String(flag_name_)] = true


func get_current_dialog_id() -> StringName:
	if current_dialog == null:
		return &""
	return current_dialog.dialog_id


func get_current_node_id() -> StringName:
	if current_node == null:
		return &""
	return current_node.node_id


func get_debug_flag_summary() -> String:
	if dialog_flags.is_empty():
		return "None"

	var flag_names_: PackedStringArray = PackedStringArray()
	for flag_name_ in dialog_flags.keys():
		flag_names_.append(String(flag_name_))

	flag_names_.sort()
	return ", ".join(flag_names_)
#endregion

#region Helpers
func _enter_node(node_data_: DialogNodeDataResource) -> void:
	if node_data_ == null:
		push_warning("[DialogManager] Missing dialog node, ending dialog")
		end_dialog()
		return

	if not _can_enter_node(node_data_):
		push_warning("[DialogManager] Node requirements not met: %s" % String(node_data_.node_id))
		end_dialog()
		return

	current_node = node_data_
	current_choices.clear()

	for flag_ in node_data_.set_flags:
		set_flag(flag_)

	node_changed.emit(node_data_)

	if node_data_.node_type == DialogData.NodeType.END and node_data_.text.is_empty():
		end_dialog()
		return

	if node_data_.node_type != DialogData.NodeType.CHOICE:
		text_advanced.emit(node_data_.text, node_data_.speaker_name)
		return

	var available_choices_: Array[DialogChoiceDataResource] = []
	for choice_ in node_data_.choices:
		if not _are_choice_requirements_met(choice_):
			continue
		available_choices_.append(choice_)

	if available_choices_.is_empty():
		push_warning("[DialogManager] Choice node has no available choices: %s" % String(node_data_.node_id))
		end_dialog()
		return

	current_choices = available_choices_
	text_advanced.emit(node_data_.text, node_data_.speaker_name)
	choices_presented.emit(current_choices)


func _can_enter_node(node_data_: DialogNodeDataResource) -> bool:
	for flag_name_ in node_data_.require_flags:
		if not has_flag(flag_name_):
			return false
	return true


func _are_choice_requirements_met(choice_: DialogChoiceDataResource) -> bool:
	for flag_name_ in choice_.require_flags:
		if not has_flag(flag_name_):
			return false
	return true


func _set_player_dialog_lock(enabled_: bool) -> void:
	var player_ := get_tree().get_first_node_in_group("player") as PlayerController
	if player_ == null:
		return

	player_.set_controls_locked(enabled_)
	if enabled_:
		player_.velocity = Vector2.ZERO
#endregion
