class_name NPCQuestGiver
extends Node

const DialogChoiceDataResource = preload("res://game/scripts/data/DialogChoiceData.gd")
const DialogDataResource = preload("res://game/scripts/data/DialogData.gd")
const DialogNodeDataResource = preload("res://game/scripts/data/DialogNodeData.gd")
const QuestDataResource = preload("res://game/scripts/data/QuestData.gd")
const QuestInstanceResource = preload("res://game/scripts/data/QuestInstance.gd")

const ACTION_ACCEPT_PREFIX: String = "quest_accept:"
const ACTION_TURN_IN_PREFIX: String = "quest_turn_in:"
const ACTION_OPEN_BASE_DIALOG: StringName = &"quest_open_base_dialog"
const DEFAULT_EMPTY_DIALOG_MESSAGE: String = "目前沒有新的委託，之後再來看看吧。"

@export var npc_id: StringName = &""
@export var available_quest_ids: Array[StringName] = []

var _pending_dialog: DialogDataResource = null
var _base_dialog: DialogDataResource = null

#region Core Lifecycle
func _ready() -> void:
	var dialog_manager_: Node = _get_dialog_manager()
	if dialog_manager_ == null:
		return

	if not dialog_manager_.dialog_action_requested.is_connected(_on_dialog_action_requested):
		dialog_manager_.dialog_action_requested.connect(_on_dialog_action_requested)
	if not dialog_manager_.dialog_ended.is_connected(_on_dialog_ended):
		dialog_manager_.dialog_ended.connect(_on_dialog_ended)
#endregion

#region Public
func get_available_quests() -> Array[QuestDataResource]:
	var quest_manager_: Node = _get_quest_manager()
	var result_: Array[QuestDataResource] = []
	if quest_manager_ == null:
		return result_

	for quest_id_ in available_quest_ids:
		var quest_data_: QuestDataResource = quest_manager_.get_quest_data(quest_id_) as QuestDataResource
		if quest_data_ == null:
			continue
		if quest_manager_.can_accept_quest(quest_data_):
			result_.append(quest_data_)

	return result_


func get_turn_in_quests() -> Array[QuestInstanceResource]:
	var quest_manager_: Node = _get_quest_manager()
	var result_: Array[QuestInstanceResource] = []
	if quest_manager_ == null:
		return result_

	for quest_ in quest_manager_.get_active_quests():
		if quest_ == null or quest_.quest_data == null:
			continue
		if quest_.status != QuestDataResource.QuestStatus.COMPLETED:
			continue
		if quest_.quest_data.target_npc_id == npc_id:
			result_.append(quest_)

	return result_


func build_runtime_dialog(base_dialog_: DialogDataResource, npc_name_: String) -> DialogDataResource:
	_base_dialog = base_dialog_

	var available_quests_: Array[QuestDataResource] = get_available_quests()
	var turn_in_quests_: Array[QuestInstanceResource] = get_turn_in_quests()
	var tracked_quests_: Array[QuestInstanceResource] = _get_relevant_active_quests()
	if available_quests_.is_empty() and turn_in_quests_.is_empty() and tracked_quests_.is_empty():
		if base_dialog_ != null:
			return base_dialog_
		return _build_feedback_dialog(DEFAULT_EMPTY_DIALOG_MESSAGE)

	var menu_choices_: Array[DialogChoiceDataResource] = []
	for quest_ in turn_in_quests_:
		menu_choices_.append(_build_choice(
			"回報任務：%s" % quest_.quest_data.quest_name,
			StringName("%s%s" % [ACTION_TURN_IN_PREFIX, String(quest_.quest_id)])
		))

	for quest_data_ in available_quests_:
		menu_choices_.append(_build_choice(
			"接取任務：%s" % quest_data_.quest_name,
			StringName("%s%s" % [ACTION_ACCEPT_PREFIX, String(quest_data_.quest_id)])
		))

	if base_dialog_ != null:
		menu_choices_.append(_build_choice("聊聊其他事", ACTION_OPEN_BASE_DIALOG))

	menu_choices_.append(_build_choice("先這樣", &""))

	var menu_node_: DialogNodeDataResource = DialogNodeDataResource.new()
	menu_node_.node_id = &"quest_menu"
	menu_node_.node_type = DialogData.NodeType.CHOICE
	menu_node_.speaker_name = npc_name_
	menu_node_.text = _build_menu_text(available_quests_, turn_in_quests_, tracked_quests_)
	menu_node_.choices = menu_choices_

	var dialog_: DialogDataResource = DialogDataResource.new()
	dialog_.dialog_id = StringName("%s_menu" % String(npc_id))
	dialog_.nodes = [menu_node_]
	dialog_.start_node_id = menu_node_.node_id
	return dialog_
#endregion

#region Helpers
func _get_relevant_active_quests() -> Array[QuestInstanceResource]:
	var result_: Array[QuestInstanceResource] = []
	var quest_manager_: Node = _get_quest_manager()
	if quest_manager_ == null:
		return result_

	for quest_ in quest_manager_.get_active_quests():
		if quest_ == null or quest_.quest_data == null:
			continue
		if quest_.status == QuestDataResource.QuestStatus.TURNED_IN:
			continue
		if quest_.quest_data.target_npc_id != npc_id:
			continue
		result_.append(quest_)

	return result_


func _build_menu_text(
	available_quests_: Array[QuestDataResource],
	turn_in_quests_: Array[QuestInstanceResource],
	tracked_quests_: Array[QuestInstanceResource]
) -> String:
	var lines_: PackedStringArray = PackedStringArray(["有什麼需要幫忙的嗎？"])

	if not turn_in_quests_.is_empty():
		lines_.append("")
		lines_.append("可回報：")
		for quest_ in turn_in_quests_:
			lines_.append("- %s" % quest_.quest_data.quest_name)

	if not available_quests_.is_empty():
		lines_.append("")
		lines_.append("可接任務：")
		for quest_data_ in available_quests_:
			lines_.append("- %s" % quest_data_.quest_name)

	var progress_lines_: PackedStringArray = PackedStringArray()
	for quest_ in tracked_quests_:
		if quest_ == null or quest_.status != QuestDataResource.QuestStatus.ACTIVE:
			continue
		progress_lines_.append("- %s (%s)" % [quest_.quest_data.quest_name, quest_.get_progress_text()])

	if not progress_lines_.is_empty():
		lines_.append("")
		lines_.append("進行中：")
		lines_.append_array(progress_lines_)

	return "\n".join(lines_)


func _build_choice(choice_text_: String, action_id_: StringName) -> DialogChoiceDataResource:
	var choice_: DialogChoiceDataResource = DialogChoiceDataResource.new()
	choice_.choice_text = choice_text_
	choice_.action_id = action_id_
	return choice_


func _build_feedback_dialog(message_: String) -> DialogDataResource:
	var text_node_: DialogNodeDataResource = DialogNodeDataResource.new()
	text_node_.node_id = &"feedback"
	text_node_.speaker_name = _get_npc_display_name()
	text_node_.text = message_
	text_node_.next_node_id = &"end"

	var end_node_: DialogNodeDataResource = DialogNodeDataResource.new()
	end_node_.node_id = &"end"
	end_node_.node_type = DialogData.NodeType.END

	var dialog_: DialogDataResource = DialogDataResource.new()
	dialog_.dialog_id = StringName("%s_feedback" % String(npc_id))
	dialog_.nodes = [text_node_, end_node_]
	dialog_.start_node_id = text_node_.node_id
	return dialog_


func _on_dialog_action_requested(action_id_: StringName) -> void:
	var dialog_manager_: Node = _get_dialog_manager()
	if dialog_manager_ == null or dialog_manager_.current_npc_id != npc_id:
		return

	var action_text_: String = String(action_id_)
	var quest_manager_: Node = _get_quest_manager()
	if quest_manager_ == null:
		return

	if action_id_ == ACTION_OPEN_BASE_DIALOG:
		_queue_pending_dialog(_base_dialog)
		return

	if action_text_.begins_with(ACTION_ACCEPT_PREFIX):
		var quest_id_: StringName = StringName(action_text_.trim_prefix(ACTION_ACCEPT_PREFIX))
		var success_: bool = quest_manager_.accept_quest(quest_id_)
		if success_:
			_pending_dialog = null
			return

		_queue_pending_dialog(_build_feedback_dialog("現在還不能接這個任務。"))
		return

	if action_text_.begins_with(ACTION_TURN_IN_PREFIX):
		var quest_id_: StringName = StringName(action_text_.trim_prefix(ACTION_TURN_IN_PREFIX))
		var success_: bool = quest_manager_.turn_in_quest(quest_id_)
		if success_:
			_pending_dialog = null
			return

		_queue_pending_dialog(_build_feedback_dialog("這個任務目前還不能回報。"))


func _on_dialog_ended(_dialog_id_: StringName) -> void:
	if _pending_dialog == null:
		return

	call_deferred("_start_pending_dialog")


func _queue_pending_dialog(dialog_data_: DialogDataResource) -> void:
	_pending_dialog = dialog_data_


func _start_pending_dialog() -> void:
	if _pending_dialog == null:
		return

	var dialog_manager_: Node = _get_dialog_manager()
	if dialog_manager_ == null or dialog_manager_.is_dialog_active:
		return

	var next_dialog_ := _pending_dialog
	_pending_dialog = null
	dialog_manager_.start_dialog(next_dialog_, npc_id)


func _get_npc_display_name() -> String:
	var parent_: Node = get_parent()
	if parent_ != null:
		var npc_name_value_ = parent_.get("npc_name")
		if npc_name_value_ != null:
			return String(npc_name_value_)
	return String(npc_id)


func _get_dialog_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("DialogManager")


func _get_quest_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("QuestManager")
#endregion
