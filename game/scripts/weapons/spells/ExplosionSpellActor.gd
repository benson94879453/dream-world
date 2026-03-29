class_name ExplosionSpellActor
extends SpellActor

@export var explosion_area_path: NodePath = NodePath("ExplosionArea")
@export var explosion_shape_path: NodePath = NodePath("ExplosionArea/ExplosionShape")
@export var visual_path: NodePath = NodePath("Visual")
@export var audio_player_path: NodePath = NodePath("AudioPlayer")
@export var explosion_radius: float = 28.0
@export var explosion_damage: float = 18.0
@export var hitstop_duration_ms: int = 110
@export var hitstop_scale: float = 0.0

var explosion_area: Area2D = null
var explosion_shape: CollisionShape2D = null
var visual: CanvasItem = null
var audio_player: AudioStreamPlayer2D = null

#region Helpers
func _setup_spell_actor() -> void:
	explosion_area = get_node_or_null(explosion_area_path) as Area2D
	explosion_shape = get_node_or_null(explosion_shape_path) as CollisionShape2D
	visual = get_node_or_null(visual_path) as CanvasItem
	audio_player = get_node_or_null(audio_player_path) as AudioStreamPlayer2D

	assert(explosion_area != null, "ExplosionSpellActor explosion_area_path must point to Area2D")
	assert(explosion_shape != null, "ExplosionSpellActor explosion_shape_path must point to CollisionShape2D")

	var circle_shape_ := explosion_shape.shape as CircleShape2D
	assert(circle_shape_ != null, "ExplosionSpellActor explosion shape must be CircleShape2D")
	circle_shape_.radius = explosion_radius


func _activate_spell() -> void:
	if audio_player != null and audio_player.stream != null:
		audio_player.play()

	print("[ExplosionSpellActor] Triggered radius=%.1f damage=%.1f" % [explosion_radius, explosion_damage])
	call_deferred("_apply_explosion")

	if lifetime_seconds > 0.0:
		start_lifetime_timer()
	else:
		complete_spell()


func _on_lifetime_timeout() -> void:
	if visual != null:
		visual.visible = false


func _apply_explosion() -> void:
	await get_tree().physics_frame
	if not is_inside_tree():
		return

	var affected_count_: int = 0
	for body_ in explosion_area.get_overlapping_bodies():
		var target_body_ := body_ as Node2D
		if target_body_ == null:
			continue
		if not _can_affect_target(target_body_):
			continue

		var hurtbox_ := _get_target_hurtbox(target_body_)
		if hurtbox_ == null:
			continue

		hurtbox_.receive_hit(_build_attack_context())
		affected_count_ += 1

	print("[ExplosionSpellActor] Affected targets: %d" % affected_count_)


func _build_attack_context() -> AttackContext:
	var attack_context_ := AttackContext.new()
	attack_context_.source_node = self
	attack_context_.attacker_node = owner_actor
	attack_context_.attacker_faction = &"player" if owner_actor != null and owner_actor.is_in_group("player") else &"enemy"
	attack_context_.base_damage = explosion_damage
	attack_context_.damage_type = &"magic"
	attack_context_.hitstop_duration_ms = hitstop_duration_ms
	attack_context_.hitstop_scale = hitstop_scale
	attack_context_.tags = _get_attack_tags([&"spell", &"explosion", weapon_data.weapon_type])
	attack_context_.weapon_instance = weapon_instance

	var attack_profile_ = weapon_data.attack_profile
	if attack_profile_ != null:
		attack_context_.hit_audio = attack_profile_.hit_audio
		attack_context_.hit_effect_scene = attack_profile_.hit_effect_scene

	return attack_context_
#endregion
