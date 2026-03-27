class_name AttackContext
extends RefCounted

#region Public
var source_node: Node = null
var attacker_faction: StringName = &"neutral"
var base_damage: float = 0.0
var damage_type: StringName = &"physical"
var poise_damage: float = 0.0
var knockback_force: Vector2 = Vector2.ZERO
var hitstop_scale: float = 1.0
var tags: Array[StringName] = []
var can_trigger_on_hit: bool = true
var hit_audio: AudioStream = null
var hit_effect_scene: PackedScene = null
#endregion
