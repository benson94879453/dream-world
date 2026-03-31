class_name AttackContext
extends RefCounted

#region Public
var source_node: Node = null
var attacker_node: Node = null
var attacker_faction: StringName = &"neutral"
var base_damage: float = 0.0
var damage_type: StringName = &"physical"
var poise_damage: float = 0.0
var knockback_force: Vector2 = Vector2.ZERO
var hitstop_duration_ms: int = 0
var hitstop_scale: float = 1.0
var tags: Array[StringName] = []
var can_trigger_on_hit: bool = true
var hit_audio: AudioStream = null
var hit_effect_scene: PackedScene = null
var weapon_instance: WeaponInstance = null
#endregion

#region Helpers
func duplicate_context() -> AttackContext:
	var copy_: AttackContext = AttackContext.new()
	copy_.source_node = source_node
	copy_.attacker_node = attacker_node
	copy_.attacker_faction = attacker_faction
	copy_.base_damage = base_damage
	copy_.damage_type = damage_type
	copy_.poise_damage = poise_damage
	copy_.knockback_force = knockback_force
	copy_.hitstop_duration_ms = hitstop_duration_ms
	copy_.hitstop_scale = hitstop_scale
	copy_.tags = tags.duplicate()
	copy_.can_trigger_on_hit = can_trigger_on_hit
	copy_.hit_audio = hit_audio
	copy_.hit_effect_scene = hit_effect_scene
	copy_.weapon_instance = weapon_instance
	return copy_
#endregion
