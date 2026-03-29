class_name NPCDialogTrigger
extends Area2D

const DIALOG_MANAGER_PATH: NodePath = NodePath("/root/DialogManager")
const DialogDataResource = preload("res://game/scripts/data/DialogData.gd")
const NPCQuestGiverResource = preload("res://game/scripts/components/NPCQuestGiver.gd")

@export var npc_name: String = "NPC"
@export var npc_id: StringName = &""
@export var dialog_data: DialogDataResource
@export var interaction_key: StringName = &"interact"

var player_in_range: bool = false

@onready var interaction_prompt: Control = $InteractionPrompt
@onready var interaction_prompt_label: Label = $InteractionPrompt

#region Core Lifecycle
func _ready() -> void:
	assert(interaction_prompt != null, "NPCDialogTrigger requires InteractionPrompt")
	assert(interaction_prompt_label != null, "NPCDialogTrigger InteractionPrompt must be Label")
	assert(dialog_data != null or _get_quest_giver() != null, "NPCDialogTrigger requires dialog_data or NPCQuestGiver")

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	interaction_prompt_label.text = "[F] 與%s交談" % npc_name
	_update_prompt_visibility()

	var dialog_manager_ = _get_dialog_manager()
	if dialog_manager_ != null:
		dialog_manager_.dialog_started.connect(_on_dialog_started)
		dialog_manager_.dialog_ended.connect(_on_dialog_ended)


func _input(event_: InputEvent) -> void:
	if not player_in_range:
		return
	if _is_modal_ui_active():
		return

	var key_event_ := event_ as InputEventKey
	if key_event_ != null and key_event_.echo:
		return

	var dialog_manager_ = _get_dialog_manager()
	if dialog_manager_ != null and dialog_manager_.is_dialog_active:
		return

	if event_.is_action_pressed(String(interaction_key)):
		_start_dialog()
		get_viewport().set_input_as_handled()
#endregion

#region Helpers
func _on_body_entered(body_: Node) -> void:
	if not body_.is_in_group("player"):
		return

	player_in_range = true
	_update_prompt_visibility()


func _on_body_exited(body_: Node) -> void:
	if not body_.is_in_group("player"):
		return

	player_in_range = false
	_update_prompt_visibility()


func _start_dialog() -> void:
	var dialog_manager_ = _get_dialog_manager()
	if dialog_manager_ == null or dialog_manager_.is_dialog_active:
		return

	var dialog_to_open_ := dialog_data
	var quest_giver_ := _get_quest_giver()
	if quest_giver_ != null:
		var quest_dialog_ := quest_giver_.build_runtime_dialog(dialog_data, npc_name)
		if quest_dialog_ != null:
			dialog_to_open_ = quest_dialog_

	if dialog_to_open_ == null:
		return

	dialog_manager_.start_dialog(dialog_to_open_, _get_runtime_npc_id())


func _on_dialog_started(_dialog_id_: StringName) -> void:
	_update_prompt_visibility()


func _on_dialog_ended(_dialog_id_: StringName) -> void:
	_update_prompt_visibility()


func _update_prompt_visibility() -> void:
	var dialog_manager_ = _get_dialog_manager()
	var dialog_active_: bool = dialog_manager_ != null and dialog_manager_.is_dialog_active
	interaction_prompt.visible = player_in_range and not dialog_active_ and not _is_modal_ui_active()


func _get_dialog_manager() -> Node:
	return get_node_or_null(DIALOG_MANAGER_PATH)


func _get_quest_giver() -> NPCQuestGiverResource:
	for child_ in get_children():
		var quest_giver_ := child_ as NPCQuestGiverResource
		if quest_giver_ != null:
			return quest_giver_
	return null


func _get_runtime_npc_id() -> StringName:
	if not npc_id.is_empty():
		return npc_id
	return StringName(String(name).to_lower())


func _is_modal_ui_active() -> bool:
	for modal_ui_ in get_tree().get_nodes_in_group("modal_ui"):
		if modal_ui_ == null:
			continue
		if modal_ui_.visible:
			return true

	return false
#endregion
