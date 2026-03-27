class_name FeedbackReceiver
extends Node

@export var visual_path: NodePath = NodePath("../Visual")
@export var flash_color: Color = Color(1.0, 0.55, 0.55, 1.0)
@export var flash_duration: float = 0.08

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
	flash_time_remaining = maxf(flash_time_remaining - delta_, 0.0)
	if flash_time_remaining > 0.0:
		return

	visual.modulate = default_modulate
	set_process(false)
#endregion

#region Public
func play_hit_feedback(attack_context_: AttackContext) -> void:
	visual.modulate = flash_color
	flash_time_remaining = flash_duration
	_play_hit_audio(attack_context_)
	_spawn_hit_effect(attack_context_)
	set_process(true)
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
	if attack_context_ == null or attack_context_.hit_effect_scene == null:
		return

	var host_node_ := get_parent() as Node2D
	if host_node_ == null:
		return

	var hit_effect_ := attack_context_.hit_effect_scene.instantiate()
	host_node_.add_child(hit_effect_)

	var hit_effect_node_ := hit_effect_ as Node2D
	if hit_effect_node_ == null:
		return

	hit_effect_node_.global_position = host_node_.global_position
#endregion
