class_name Portal
extends Area2D

const SCENE_TRANSITION_MANAGER_PATH: NodePath = NodePath("/root/SceneTransitionManager")
const DIALOG_MANAGER_PATH: NodePath = NodePath("/root/DialogManager")

@export var target_scene: String = ""
@export var target_spawn_point: StringName = &""
@export var interaction_prompt: String = "[F] 進入傳送門"

var _player_in_range: bool = false
var _player_reference: Node = null

@onready var interaction_prompt_label: Label = $InteractionPrompt


func _ready() -> void:
	assert(interaction_prompt_label != null, "Portal requires InteractionPrompt label")

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	interaction_prompt_label.text = interaction_prompt
	_update_prompt_visibility()


func _input(event_: InputEvent) -> void:
	if not _player_in_range:
		return

	if _is_modal_ui_active() or _is_dialog_active():
		return

	var key_event_ := event_ as InputEventKey
	if key_event_ != null and key_event_.echo:
		return

	if not event_.is_action_pressed("interact"):
		return

	interact(_player_reference)
	get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if body == null or not body.is_in_group("player"):
		return

	_player_in_range = true
	_player_reference = body
	_update_prompt_visibility()


func _on_body_exited(body: Node2D) -> void:
	if body == null or not body.is_in_group("player"):
		return

	_player_in_range = false
	_player_reference = null
	_update_prompt_visibility()


func interact(player: Node) -> void:
	if player == null:
		return

	if target_scene.is_empty():
		push_warning("[Portal] Missing target_scene on portal %s" % name)
		return

	var scene_transition_manager_ := _get_scene_transition_manager()
	if scene_transition_manager_ == null:
		push_warning("[Portal] SceneTransitionManager autoload is unavailable")
		return

	if scene_transition_manager_.is_transitioning():
		return

	scene_transition_manager_.transition_to(target_scene, target_spawn_point)


func _update_prompt_visibility() -> void:
	var scene_transition_manager_ := _get_scene_transition_manager()
	var transition_active_: bool = scene_transition_manager_ != null and scene_transition_manager_.is_transitioning()
	interaction_prompt_label.text = interaction_prompt
	interaction_prompt_label.visible = _player_in_range and not transition_active_ and not _is_modal_ui_active() and not _is_dialog_active()


func _get_scene_transition_manager() -> Node:
	return get_node_or_null(SCENE_TRANSITION_MANAGER_PATH)


func _is_dialog_active() -> bool:
	var dialog_manager_ := get_node_or_null(DIALOG_MANAGER_PATH)
	if dialog_manager_ == null:
		return false

	return bool(dialog_manager_.get("is_dialog_active"))


func _is_modal_ui_active() -> bool:
	for modal_ui_ in get_tree().get_nodes_in_group("modal_ui"):
		if modal_ui_ == null:
			continue
		if modal_ui_.visible:
			return true

	return false
