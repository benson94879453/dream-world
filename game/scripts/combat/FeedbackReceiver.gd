class_name FeedbackReceiver
extends Node

@export var visual_path: NodePath = NodePath("../Visual")
@export var flash_color: Color = Color(1.0, 0.55, 0.55, 1.0)
@export var flash_duration: float = 0.08
@export var default_hit_effect_scene: PackedScene = preload("res://game/scenes/effects/HitEffect.tscn")

var flash_time_remaining: float = 0.0
var default_modulate: Color = Color.WHITE
var hit_audio_player: AudioStreamPlayer2D = null

@onready var visual: CanvasItem = get_node_or_null(visual_path) as CanvasItem

#region Core Lifecycle
func _ready() -> void:
	assert(visual != null, "FeedbackReceiver visual_path must point to a CanvasItem")

	default_modulate = visual.modulate
	_ensure_hit_audio_player()
	set_process(false)


func _process(delta_: float) -> void:
	if not is_instance_valid(visual):
		set_process(false)
		return

	flash_time_remaining = maxf(flash_time_remaining - delta_, 0.0)
	if flash_time_remaining > 0.0:
		return

	_reset_flash()
#endregion

#region Public
func play_hit_feedback(attack_context_: AttackContext) -> void:
	if not is_instance_valid(visual):
		return

	visual.modulate = flash_color
	flash_time_remaining = flash_duration
	set_process(true)
	_play_hit_audio(attack_context_)
	_spawn_hit_effect(attack_context_)
	_request_hit_stop(attack_context_)


func force_reset() -> void:
	_reset_flash()
#endregion

#region Helpers
func _ensure_hit_audio_player() -> void:
	if hit_audio_player != null:
		return

	var host_node_ := get_parent() as Node2D
	if host_node_ == null:
		return

	hit_audio_player = AudioStreamPlayer2D.new()
	hit_audio_player.name = "HitAudioPlayer"
	host_node_.call_deferred("add_child", hit_audio_player)


func _play_hit_audio(attack_context_: AttackContext) -> void:
	if attack_context_ == null or attack_context_.hit_audio == null:
		return

	if hit_audio_player == null:
		_ensure_hit_audio_player()
	if hit_audio_player == null:
		return

	hit_audio_player.stream = attack_context_.hit_audio
	hit_audio_player.play()


func _spawn_hit_effect(attack_context_: AttackContext) -> void:
	var host_node_ := get_parent() as Node2D
	if host_node_ == null:
		return

	var hit_effect_scene_: PackedScene = attack_context_.hit_effect_scene if attack_context_ != null and attack_context_.hit_effect_scene != null else default_hit_effect_scene
	if hit_effect_scene_ == null:
		return

	var hit_effect_ := hit_effect_scene_.instantiate()
	var effect_parent_ := host_node_.get_parent()
	if effect_parent_ == null:
		effect_parent_ = host_node_
	effect_parent_.add_child(hit_effect_)

	var hit_effect_node_ := hit_effect_ as Node2D
	if hit_effect_node_ == null:
		return

	hit_effect_node_.global_position = host_node_.global_position


func _request_hit_stop(attack_context_: AttackContext) -> void:
	if attack_context_ == null:
		return
	if attack_context_.hitstop_duration_ms <= 0 or attack_context_.hitstop_scale >= 1.0:
		return

	var hit_stop_manager_ := _get_hit_stop_manager()
	if hit_stop_manager_ == null:
		return

	var target_node_ := get_parent()
	if target_node_ != null:
		hit_stop_manager_.request_hit_stop(target_node_, attack_context_.hitstop_duration_ms, attack_context_.hitstop_scale)

	var attacker_node_ := attack_context_.attacker_node
	if attacker_node_ == null or attacker_node_ == target_node_:
		return

	hit_stop_manager_.request_hit_stop(attacker_node_, attack_context_.hitstop_duration_ms, attack_context_.hitstop_scale)


func _get_hit_stop_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("HitStopManager")


func _reset_flash() -> void:
	flash_time_remaining = 0.0
	if is_instance_valid(visual):
		visual.modulate = default_modulate
	set_process(false)
#endregion
