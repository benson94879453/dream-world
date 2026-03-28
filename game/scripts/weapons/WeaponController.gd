class_name WeaponController
extends Node2D

const WeaponAttackProfileResource = preload("res://game/scripts/data/WeaponAttackProfile.gd")

@export var weapon_sprite_path: NodePath = NodePath("WeaponSprite")
@export var use_weapon_sprite_offset_override: bool = false
@export var weapon_sprite_offset_override: Vector2 = Vector2.ZERO

var owner_actor: PlayerController = null
var weapon_instance: WeaponInstance = null
var weapon_data: WeaponData = null
var weapon_sprite: Sprite2D = null
var startup_audio_player: AudioStreamPlayer2D = null
var proc_rng: RandomNumberGenerator = RandomNumberGenerator.new()

#region Public
func setup(owner_: PlayerController, weapon_instance_: WeaponInstance) -> void:
	assert(owner_actor == null, "WeaponController does not support double setup")
	assert(owner_ != null, "WeaponController requires owner")
	assert(weapon_instance_ != null, "WeaponController requires WeaponInstance")
	assert(weapon_instance_.weapon_data != null, "WeaponController requires WeaponData")

	owner_actor = owner_
	weapon_instance = weapon_instance_
	weapon_data = weapon_instance_.weapon_data
	weapon_sprite = get_node_or_null(weapon_sprite_path) as Sprite2D

	assert(weapon_sprite != null, "WeaponController weapon_sprite_path must point to Sprite2D")

	proc_rng.randomize()
	_apply_common_setup()
	_setup_weapon()


func try_primary_attack() -> bool:
	return false


func can_combo() -> bool:
	return false


func get_current_phase() -> StringName:
	return &"idle"


func cancel_attack() -> void:
	pass


func on_equipped() -> void:
	pass


func on_unequipped() -> void:
	if startup_audio_player != null:
		startup_audio_player.stop()
#endregion

#region Helpers
func _apply_common_setup() -> void:
	weapon_sprite.texture = weapon_data.weapon_sprite_texture
	weapon_sprite.visible = weapon_sprite.texture != null
	weapon_sprite.position = _resolve_weapon_sprite_offset()


func _setup_weapon() -> void:
	pass


func _get_attack_direction() -> Vector2:
	assert(owner_actor != null, "WeaponController owner_actor must be initialized")
	return owner_actor.get_attack_direction()


func _get_attack_profile() -> WeaponAttackProfileResource:
	if weapon_data == null:
		return null
	return weapon_data.attack_profile


func _get_attack_phase_duration_seconds(frame_count_: int) -> float:
	var ticks_per_second_: float = maxf(float(Engine.physics_ticks_per_second), 1.0)
	return maxf(float(frame_count_), 0.0) / ticks_per_second_


func _get_attack_cooldown_seconds() -> float:
	var attack_profile_ = _get_attack_profile()
	if attack_profile_ != null:
		return maxf(attack_profile_.cooldown_seconds, 0.0)
	return weapon_instance.get_attack_cooldown()


func _play_attack_animation(animation_name_: String) -> void:
	if owner_actor == null or animation_name_.is_empty():
		return

	owner_actor.play_weapon_attack_animation(animation_name_)


func _play_audio_stream(audio_stream_: AudioStream) -> void:
	if audio_stream_ == null:
		return

	if startup_audio_player == null:
		startup_audio_player = AudioStreamPlayer2D.new()
		startup_audio_player.name = "StartupAudioPlayer"
		add_child(startup_audio_player)

	startup_audio_player.stream = audio_stream_
	startup_audio_player.play()


func _spawn_presentation_scene(scene_: PackedScene, global_position_: Vector2) -> void:
	if scene_ == null:
		return

	var parent_node_: Node = owner_actor.get_parent() if owner_actor != null else get_parent()
	if parent_node_ == null:
		return

	var presentation_node_: Node = scene_.instantiate()
	parent_node_.add_child(presentation_node_)

	var presentation_node_2d_ := presentation_node_ as Node2D
	if presentation_node_2d_ == null:
		return

	presentation_node_2d_.global_position = global_position_


func _get_attack_presentation_position() -> Vector2:
	if weapon_sprite != null:
		return weapon_sprite.global_position
	return global_position


func _resolve_weapon_sprite_offset() -> Vector2:
	if use_weapon_sprite_offset_override:
		return weapon_sprite_offset_override

	if weapon_data.weapon_sprite_texture == null:
		return Vector2.ZERO

	var texture_size_: Vector2 = weapon_data.weapon_sprite_texture.get_size()
	return Vector2(texture_size_.x * 0.5, texture_size_.y * -0.5)


func _has_active_rune_effect(effect_id_: StringName) -> bool:
	return weapon_instance != null and weapon_instance.has_active_rune_effect(effect_id_)


func _get_total_weapon_modifier(stat_key_: StringName) -> float:
	if weapon_instance == null:
		return 0.0
	return weapon_instance.get_total_stat_modifier(stat_key_)


func _roll_proc(chance_: float) -> bool:
	return chance_ > 0.0 and proc_rng.randf() <= minf(chance_, 1.0)


func _get_attack_tags(base_tags_: Array[StringName]) -> Array[StringName]:
	var tags_: Array[StringName] = base_tags_.duplicate()
	if weapon_instance == null:
		return tags_

	for element_tag_ in weapon_instance.get_attack_element_tags():
		if not tags_.has(element_tag_):
			tags_.append(element_tag_)

	return tags_


func _get_rune_test_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("RuneTestManager")
#endregion
