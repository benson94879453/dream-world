class_name Checkpoint
extends Area2D

const SCENE_TRANSITION_MANAGER_PATH: NodePath = NodePath("/root/SceneTransitionManager")
const SAVE_MANAGER_PATH: NodePath = NodePath("/root/SaveManager")
const SCENE_STATE_MANAGER_PATH: NodePath = NodePath("/root/SceneStateManager")
const DIALOG_MANAGER_PATH: NodePath = NodePath("/root/DialogManager")

signal checkpoint_activated(checkpoint: Checkpoint)

@export var checkpoint_id: StringName = &""
@export var heal_amount: float = 9999.0
@export var interaction_key: StringName = &"interact"

var is_activated: bool = false
var _player_in_range: bool = false
var _state_id: String = ""

@onready var interaction_prompt_label: Label = $InteractionPrompt
@onready var flame_outer: Polygon2D = $FlameOuter
@onready var flame_inner: Polygon2D = $FlameInner
@onready var glow: Polygon2D = $Glow


func _ready() -> void:
	assert(interaction_prompt_label != null, "Checkpoint requires InteractionPrompt")
	assert(flame_outer != null, "Checkpoint requires FlameOuter")
	assert(flame_inner != null, "Checkpoint requires FlameInner")
	assert(glow != null, "Checkpoint requires Glow")

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_state_id = _build_state_id()
	_load_state()
	_update_visual_state()
	_update_prompt_visibility()


func _input(event_: InputEvent) -> void:
	if not _player_in_range:
		return
	if _is_dialog_active() or _is_modal_ui_active():
		return

	var key_event_: InputEventKey = event_ as InputEventKey
	if key_event_ != null and key_event_.echo:
		return

	if not event_.is_action_pressed(String(interaction_key)):
		return

	var player_ := get_tree().get_first_node_in_group("player")
	activate(player_)
	get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if body == null or not body.is_in_group("player"):
		return

	_player_in_range = true
	activate(body)
	_update_prompt_visibility()


func _on_body_exited(body: Node2D) -> void:
	if body == null or not body.is_in_group("player"):
		return

	_player_in_range = false
	_update_prompt_visibility()


func activate(player: Node) -> void:
	if player == null:
		return
	if checkpoint_id.is_empty():
		push_warning("[Checkpoint] Missing checkpoint_id on %s" % name)
		return

	var player_controller_: PlayerController = player as PlayerController
	if player_controller_ == null:
		return

	var health_component_ := player_controller_.get_health_component()
	if health_component_ != null:
		health_component_.heal(maxf(heal_amount, health_component_.max_hp))

	var scene_path_: String = _get_current_scene_path()
	var transition_manager_: Node = _get_scene_transition_manager()
	if transition_manager_ != null and not scene_path_.is_empty():
		transition_manager_.set_respawn_point(scene_path_, checkpoint_id, global_position)

	var did_activate_: bool = not is_activated
	is_activated = true
	_save_state()
	_update_visual_state()
	_play_activation_feedback()

	if did_activate_:
		print("[Checkpoint] Activated: %s" % String(checkpoint_id))

	var save_manager_: Node = _get_save_manager()
	if save_manager_ != null:
		save_manager_.save_game()

	checkpoint_activated.emit(self)


func _load_state() -> void:
	var scene_state_manager_: Node = _get_scene_state_manager()
	if scene_state_manager_ == null or _state_id.is_empty():
		return

	var state_data_: Dictionary = scene_state_manager_.get_state(_state_id)
	is_activated = bool(state_data_.get("activated", false))


func _save_state() -> void:
	var scene_state_manager_: Node = _get_scene_state_manager()
	if scene_state_manager_ == null or _state_id.is_empty():
		return

	scene_state_manager_.record_state(_state_id, {
		"type": "checkpoint",
		"activated": is_activated
	})


func _play_activation_feedback() -> void:
	glow.visible = true
	glow.scale = Vector2.ONE
	glow.modulate = Color(1.0, 0.85, 0.45, 0.45 if is_activated else 0.0)

	var tween_: Tween = create_tween()
	tween_.set_parallel(true)
	tween_.tween_property(glow, "scale", Vector2(1.18, 1.18), 0.12)
	tween_.tween_property(glow, "modulate:a", 0.72, 0.12)
	await tween_.finished

	var settle_tween_: Tween = create_tween()
	settle_tween_.set_parallel(true)
	settle_tween_.tween_property(glow, "scale", Vector2.ONE, 0.18)
	settle_tween_.tween_property(glow, "modulate:a", 0.45, 0.18)


func _update_visual_state() -> void:
	flame_outer.color = Color(1.0, 0.52, 0.16, 1.0) if is_activated else Color(0.46, 0.30, 0.20, 1.0)
	flame_inner.color = Color(1.0, 0.92, 0.46, 1.0) if is_activated else Color(0.68, 0.58, 0.32, 0.9)
	glow.visible = is_activated
	glow.modulate = Color(1.0, 0.84, 0.42, 0.45) if is_activated else Color(1.0, 0.84, 0.42, 0.0)


func _update_prompt_visibility() -> void:
	interaction_prompt_label.visible = _player_in_range and not _is_dialog_active() and not _is_modal_ui_active()


func _build_state_id() -> String:
	if checkpoint_id.is_empty():
		return ""

	var scene_path_: String = _get_current_scene_path()
	if scene_path_.is_empty():
		return ""

	var scene_state_manager_: Node = _get_scene_state_manager()
	if scene_state_manager_ == null:
		return ""

	return scene_state_manager_.generate_state_id(scene_path_, "checkpoint_%s" % String(checkpoint_id), 0)


func _get_current_scene_path() -> String:
	var scene_transition_manager_: Node = _get_scene_transition_manager()
	if scene_transition_manager_ != null and scene_transition_manager_.has_method("get_current_scene_path"):
		return String(scene_transition_manager_.get_current_scene_path())

	var current_scene_ := get_tree().current_scene
	if current_scene_ == null:
		return ""
	return current_scene_.scene_file_path


func _get_scene_transition_manager() -> Node:
	return get_node_or_null(SCENE_TRANSITION_MANAGER_PATH)


func _get_save_manager() -> Node:
	return get_node_or_null(SAVE_MANAGER_PATH)


func _get_scene_state_manager() -> Node:
	return get_node_or_null(SCENE_STATE_MANAGER_PATH)


func _is_dialog_active() -> bool:
	var dialog_manager_ := get_node_or_null(DIALOG_MANAGER_PATH)
	if dialog_manager_ == null:
		return false
	return bool(dialog_manager_.get("is_dialog_active"))


func _is_modal_ui_active() -> bool:
	for modal_ui_ in get_tree().get_nodes_in_group("modal_ui"):
		if modal_ui_ != null and modal_ui_.visible:
			return true
	return false
