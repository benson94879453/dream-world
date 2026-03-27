class_name HealSpellActor
extends SpellActor

@export var heal_amount: float = 24.0
@export var visual_path: NodePath = NodePath("Visual")
@export var audio_player_path: NodePath = NodePath("AudioPlayer")

var visual: CanvasItem = null
var audio_player: AudioStreamPlayer2D = null

#region Helpers
func _setup_spell_actor() -> void:
	visual = get_node_or_null(visual_path) as CanvasItem
	audio_player = get_node_or_null(audio_player_path) as AudioStreamPlayer2D

	if owner_actor != null:
		global_position = owner_actor.global_position


func _activate_spell() -> void:
	if owner_actor != null:
		global_position = owner_actor.global_position

	if audio_player != null and audio_player.stream != null:
		audio_player.play()

	var restored_hp_: float = 0.0
	if owner_actor != null and _can_affect_target(owner_actor):
		var health_component_ := _get_target_health_component(owner_actor)
		if health_component_ != null:
			restored_hp_ = health_component_.heal(heal_amount)

	print("[HealSpellActor] Triggered heal: %.1f" % restored_hp_)

	if lifetime_seconds > 0.0:
		start_lifetime_timer()
	else:
		complete_spell()


func _on_lifetime_timeout() -> void:
	if visual != null:
		visual.visible = false
#endregion
