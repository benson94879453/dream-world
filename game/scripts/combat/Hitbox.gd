class_name Hitbox
extends Area2D

@export var attacker_faction: StringName = &"player"
@export var base_damage: float = 20.0
@export var damage_type: StringName = &"physical"
@export var poise_damage: float = 0.0
@export var active_duration: float = 0.12
@export var hitstop_scale: float = 1.0

var active_time_remaining: float = 0.0
var already_hit: Array[Hurtbox] = []
var source_root: Node = null
var attack_tags: Array[StringName] = [&"melee"]
var hit_audio: AudioStream = null
var hit_effect_scene: PackedScene = null

#region Core Lifecycle
func _ready() -> void:
	monitoring = false
	set_physics_process(false)


func _physics_process(delta_: float) -> void:
	var overlapping_areas_: Array[Area2D] = get_overlapping_areas()
	for area_ in overlapping_areas_:
		_try_hit(area_)

	active_time_remaining = maxf(active_time_remaining - delta_, 0.0)
	if active_time_remaining > 0.0:
		return

	monitoring = false
	set_physics_process(false)
#endregion

#region Public
func activate() -> void:
	already_hit.clear()
	active_time_remaining = active_duration
	monitoring = true
	set_physics_process(true)


func deactivate() -> void:
	active_time_remaining = 0.0
	monitoring = false
	set_physics_process(false)
#endregion

#region Helpers
func _try_hit(area_: Area2D) -> void:
	var hurtbox_ := area_ as Hurtbox
	if hurtbox_ == null:
		return

	var source_root_ := _resolve_source_root()
	if source_root_ == hurtbox_ or source_root_.is_ancestor_of(hurtbox_):
		return

	if already_hit.has(hurtbox_):
		return

	already_hit.append(hurtbox_)
	hurtbox_.receive_hit(_build_attack_context())


func _build_attack_context() -> AttackContext:
	var attack_context_: AttackContext = AttackContext.new()

	attack_context_.source_node = self
	attack_context_.attacker_faction = attacker_faction
	attack_context_.base_damage = base_damage
	attack_context_.damage_type = damage_type
	attack_context_.poise_damage = poise_damage
	attack_context_.hitstop_scale = hitstop_scale
	attack_context_.tags = attack_tags.duplicate()
	attack_context_.hit_audio = hit_audio
	attack_context_.hit_effect_scene = hit_effect_scene

	return attack_context_


func _resolve_source_root() -> Node:
	if source_root != null:
		return source_root

	if owner != null:
		return owner

	var source_root_ := get_parent()
	assert(source_root_ != null, "Hitbox requires source_root, scene owner, or parent")
	return source_root_
#endregion
