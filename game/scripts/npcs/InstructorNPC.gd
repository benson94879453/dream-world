class_name InstructorNPC
extends Node2D

const DIALOG_MANAGER_PATH: NodePath = NodePath("/root/DialogManager")
const SCENE_STATE_MANAGER_PATH: NodePath = NodePath("/root/SceneStateManager")

@export var npc_name: String = "教官"
@export var npc_id: StringName = &"npc_instructor"
@export var default_dialog: DialogData
@export var post_boss_dialog: DialogData
@export var interaction_key: StringName = &"interact"
@export var boss_state_id: String = "dungeon01_boss_boar"

var _player_in_range: bool = false

@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt_label: Label = $InteractionPrompt


func _ready() -> void:
	assert(interaction_area != null, "InstructorNPC requires InteractionArea")
	assert(interaction_prompt_label != null, "InstructorNPC requires InteractionPrompt")
	assert(default_dialog != null, "InstructorNPC requires default_dialog")
	assert(post_boss_dialog != null, "InstructorNPC requires post_boss_dialog")

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	interaction_prompt_label.text = "[F] 與%s交談" % npc_name
	_update_prompt_visibility()

	var dialog_manager_: Node = _get_dialog_manager()
	if dialog_manager_ != null:
		dialog_manager_.dialog_started.connect(_on_dialog_started)
		dialog_manager_.dialog_ended.connect(_on_dialog_ended)


func _input(event_: InputEvent) -> void:
	if not _player_in_range:
		return
	if _is_modal_ui_active():
		return

	var key_event_: InputEventKey = event_ as InputEventKey
	if key_event_ != null and key_event_.echo:
		return

	var dialog_manager_: Node = _get_dialog_manager()
	if dialog_manager_ != null and dialog_manager_.is_dialog_active:
		return

	if not event_.is_action_pressed(String(interaction_key)):
		return

	var dialog_data_: DialogData = get_available_dialog()
	if dialog_data_ == null:
		push_warning("[InstructorNPC] Missing dialog resource for %s" % name)
		return

	dialog_manager_.start_dialog(dialog_data_, npc_id)
	get_viewport().set_input_as_handled()


func get_available_dialog() -> DialogData:
	var has_defeated_boss_: bool = _check_boss_defeated()
	return post_boss_dialog if has_defeated_boss_ else default_dialog


func _check_boss_defeated() -> bool:
	var scene_state_manager_: Node = _get_scene_state_manager()
	if scene_state_manager_ == null or boss_state_id.is_empty():
		return false

	var boss_state_: Dictionary = scene_state_manager_.get_state(boss_state_id)
	return bool(boss_state_.get("defeated", false))


func _on_body_entered(body_: Node) -> void:
	if body_ == null or not body_.is_in_group("player"):
		return

	_player_in_range = true
	_update_prompt_visibility()


func _on_body_exited(body_: Node) -> void:
	if body_ == null or not body_.is_in_group("player"):
		return

	_player_in_range = false
	_update_prompt_visibility()


func _on_dialog_started(_dialog_id_: StringName) -> void:
	_update_prompt_visibility()


func _on_dialog_ended(_dialog_id_: StringName) -> void:
	_update_prompt_visibility()


func _update_prompt_visibility() -> void:
	var dialog_manager_: Node = _get_dialog_manager()
	var dialog_active_: bool = dialog_manager_ != null and dialog_manager_.is_dialog_active
	interaction_prompt_label.visible = _player_in_range and not dialog_active_ and not _is_modal_ui_active()


func _get_dialog_manager() -> Node:
	return get_node_or_null(DIALOG_MANAGER_PATH)


func _get_scene_state_manager() -> Node:
	return get_node_or_null(SCENE_STATE_MANAGER_PATH)


func _is_modal_ui_active() -> bool:
	for modal_ui_ in get_tree().get_nodes_in_group("modal_ui"):
		if modal_ui_ != null and modal_ui_.visible:
			return true
	return false
