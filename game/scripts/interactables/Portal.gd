class_name Portal
extends Area2D

const SCENE_TRANSITION_MANAGER_PATH: NodePath = NodePath("/root/SceneTransitionManager")
const DIALOG_MANAGER_PATH: NodePath = NodePath("/root/DialogManager")
const SCENE_STATE_MANAGER_PATH: NodePath = NodePath("/root/SceneStateManager")

@export var target_scene: String = ""
@export var target_spawn_point: StringName = &""
@export var interaction_prompt: String = "[F] 進入傳送門"
@export var activate_on_state_id: String = ""
@export var sealed_interaction_prompt: String = "尚未開放"
@export var inactive_visual_color: Color = Color(0.20, 0.28, 0.40, 0.5)
@export var inactive_inner_glow_color: Color = Color(0.56, 0.63, 0.73, 0.35)
@export var active_visual_color: Color = Color(0.28, 0.74, 1.0, 0.92)
@export var active_inner_glow_color: Color = Color(0.88, 0.97, 1.0, 0.94)
@export var active_highlight_color: Color = Color(0.50, 0.86, 1.0, 0.28)
@export var seal_band_color: Color = Color(0.95, 0.68, 0.28, 0.85)
@export var active_pulse_speed: float = 2.4
@export var active_pulse_scale_amount: float = 0.08

var _player_in_range: bool = false
var _player_reference: Node = null
var _portal_is_active: bool = true
var _active_pulse_time: float = 0.0

@onready var visual: Polygon2D = $Visual
@onready var inner_glow: Polygon2D = $InnerGlow
@onready var highlight_glow: Polygon2D = get_node_or_null("HighlightGlow") as Polygon2D
@onready var seal_band: Polygon2D = get_node_or_null("SealBand") as Polygon2D
@onready var interaction_prompt_label: Label = $InteractionPrompt


func _ready() -> void:
	assert(visual != null, "Portal requires Visual")
	assert(inner_glow != null, "Portal requires InnerGlow")
	assert(interaction_prompt_label != null, "Portal requires InteractionPrompt label")

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_connect_scene_state_hooks()
	_refresh_portal_state()
	_update_prompt_visibility()


func _process(delta_: float) -> void:
	if not _portal_is_active:
		return

	_active_pulse_time += delta_ * maxf(active_pulse_speed, 0.0)
	_update_active_visuals()


func _input(event_: InputEvent) -> void:
	if not _player_in_range:
		return

	if _is_modal_ui_active() or _is_dialog_active():
		return

	var key_event_: InputEventKey = event_ as InputEventKey
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
	if not _is_portal_available():
		return

	if target_scene.is_empty():
		push_warning("[Portal] Missing target_scene on portal %s" % name)
		return

	var scene_transition_manager_: Node = _get_scene_transition_manager()
	if scene_transition_manager_ == null:
		push_warning("[Portal] SceneTransitionManager autoload is unavailable")
		return

	if scene_transition_manager_.is_transitioning():
		return

	scene_transition_manager_.transition_to(target_scene, target_spawn_point)


func _update_prompt_visibility() -> void:
	var scene_transition_manager_: Node = _get_scene_transition_manager()
	var transition_active_: bool = scene_transition_manager_ != null and scene_transition_manager_.is_transitioning()
	interaction_prompt_label.text = _get_current_prompt_text()
	interaction_prompt_label.visible = _player_in_range and not transition_active_ and not _is_modal_ui_active() and not _is_dialog_active()


func _get_scene_transition_manager() -> Node:
	return get_node_or_null(SCENE_TRANSITION_MANAGER_PATH)


func _get_scene_state_manager() -> Node:
	return get_node_or_null(SCENE_STATE_MANAGER_PATH)


func _connect_scene_state_hooks() -> void:
	if activate_on_state_id.is_empty():
		return

	var scene_state_manager_: Node = _get_scene_state_manager()
	if scene_state_manager_ == null:
		return

	var recorded_callable_: Callable = Callable(self, "_on_scene_state_recorded")
	if scene_state_manager_.has_signal("state_recorded") and not scene_state_manager_.is_connected("state_recorded", recorded_callable_):
		scene_state_manager_.connect("state_recorded", recorded_callable_)

	var reapplied_callable_: Callable = Callable(self, "_on_current_scene_state_reapplied")
	if scene_state_manager_.has_signal("current_scene_state_reapplied") and not scene_state_manager_.is_connected("current_scene_state_reapplied", reapplied_callable_):
		scene_state_manager_.connect("current_scene_state_reapplied", reapplied_callable_)


func _refresh_portal_state() -> void:
	_portal_is_active = _evaluate_portal_state()
	_apply_visual_state()
	_update_prompt_visibility()


func _evaluate_portal_state() -> bool:
	if activate_on_state_id.is_empty():
		return true

	var scene_state_manager_: Node = _get_scene_state_manager()
	if scene_state_manager_ == null:
		return false

	var state_data_: Dictionary = scene_state_manager_.get_state(activate_on_state_id)
	return bool(state_data_.get("defeated", false))


func _apply_visual_state() -> void:
	if _portal_is_active:
		visual.color = active_visual_color
		inner_glow.visible = true
		if highlight_glow != null:
			highlight_glow.visible = true
			highlight_glow.color = active_highlight_color
		if seal_band != null:
			seal_band.visible = false
		_active_pulse_time = 0.0
		set_process(true)
		_update_active_visuals()
		return

	set_process(false)
	visual.color = inactive_visual_color
	visual.scale = Vector2.ONE
	inner_glow.visible = true
	inner_glow.color = inactive_inner_glow_color
	inner_glow.scale = Vector2(0.94, 0.94)
	if highlight_glow != null:
		highlight_glow.visible = false
		highlight_glow.scale = Vector2.ONE
	if seal_band != null:
		seal_band.visible = true
		seal_band.color = seal_band_color


func _update_active_visuals() -> void:
	var pulse_: float = (sin(_active_pulse_time) + 1.0) * 0.5
	var pulse_scale_: float = 1.0 + pulse_ * active_pulse_scale_amount
	var inner_alpha_: float = lerpf(active_inner_glow_color.a * 0.78, active_inner_glow_color.a, pulse_)
	var highlight_alpha_: float = lerpf(active_highlight_color.a * 0.45, active_highlight_color.a, pulse_)

	visual.scale = Vector2.ONE * lerpf(1.0, 1.03, pulse_)
	inner_glow.scale = Vector2.ONE * pulse_scale_
	inner_glow.color = _with_alpha(active_inner_glow_color, inner_alpha_)

	if highlight_glow != null:
		highlight_glow.scale = Vector2.ONE * lerpf(1.02, 1.12, pulse_)
		highlight_glow.color = _with_alpha(active_highlight_color, highlight_alpha_)


func _get_current_prompt_text() -> String:
	return interaction_prompt if _portal_is_active else sealed_interaction_prompt


func _is_portal_available() -> bool:
	return _portal_is_active


func _on_scene_state_recorded(_state_id_: String, _state_data_: Dictionary) -> void:
	if activate_on_state_id.is_empty():
		return

	_refresh_portal_state()


func _on_current_scene_state_reapplied(_scene_path_: String) -> void:
	if activate_on_state_id.is_empty():
		return

	_refresh_portal_state()


func _is_dialog_active() -> bool:
	var dialog_manager_: Node = get_node_or_null(DIALOG_MANAGER_PATH)
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


func _with_alpha(color_: Color, alpha_: float) -> Color:
	return Color(color_.r, color_.g, color_.b, alpha_)
