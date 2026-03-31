class_name DamageReceiver
extends Node

signal hit_received(attack_context_: AttackContext, applied_damage_: float)

@export var health_component_path: NodePath = NodePath("../HealthComponent")
@export var feedback_receiver_path: NodePath = NodePath("../FeedbackReceiver")

var health_component: HealthComponent
var feedback_receiver: FeedbackReceiver

#region Core Lifecycle
func _ready() -> void:
	health_component = get_node_or_null(health_component_path) as HealthComponent
	feedback_receiver = get_node_or_null(feedback_receiver_path) as FeedbackReceiver

	assert(health_component != null, "DamageReceiver health_component_path must point to HealthComponent")
	assert(feedback_receiver != null, "DamageReceiver feedback_receiver_path must point to FeedbackReceiver")
#endregion

#region Public
func receive_hit(attack_context_: AttackContext) -> float:
	if attack_context_ == null:
		return 0.0

	var applied_damage_: float = health_component.apply_damage(calculate_damage_preview(attack_context_))
	if applied_damage_ <= 0.0:
		return 0.0

	feedback_receiver.play_hit_feedback(attack_context_)
	_apply_on_hit_rune_effects(attack_context_, applied_damage_)
	hit_received.emit(attack_context_, applied_damage_)
	return applied_damage_
#endregion

#region Helpers
static func calculate_damage_preview(attack_context_: AttackContext) -> float:
	if attack_context_ == null:
		return 0.0

	var total_damage_: float = maxf(attack_context_.base_damage, 0.0)
	if total_damage_ <= 0.0:
		return 0.0

	var weapon_instance_ := attack_context_.weapon_instance
	if weapon_instance_ != null:
		if attack_context_.tags.has(&"fire"):
			total_damage_ *= 1.0 + weapon_instance_.get_total_stat_modifier(&"fire_damage_percent")
		if attack_context_.tags.has(&"elemental"):
			total_damage_ *= 1.0 + weapon_instance_.get_total_stat_modifier(&"elemental_damage_bonus_pct")

	return total_damage_


func _apply_on_hit_rune_effects(attack_context_: AttackContext, applied_damage_: float) -> void:
	var weapon_instance_ := attack_context_.weapon_instance
	if weapon_instance_ == null or not weapon_instance_.has_active_rune_effect(&"overheal_to_shield"):
		return

	var attacker_player_: PlayerController = attack_context_.attacker_node as PlayerController
	if attacker_player_ == null:
		return

	var health_component_ := attacker_player_.get_health_component()
	if health_component_ == null or health_component_.is_dead():
		return

	var lifesteal_pct_: float = weapon_instance_.get_total_stat_modifier(&"lifesteal_pct")
	if lifesteal_pct_ <= 0.0:
		return

	var total_restore_: float = applied_damage_ * lifesteal_pct_
	if total_restore_ <= 0.0:
		return

	var restored_hp_: float = health_component_.heal(total_restore_)
	var overflow_restore_: float = total_restore_ - restored_hp_
	if overflow_restore_ <= 0.0:
		return

	var overheal_shield_pct_: float = maxf(weapon_instance_.get_total_stat_modifier(&"overheal_shield_pct"), 0.0)
	if overheal_shield_pct_ <= 0.0:
		return

	health_component_.add_temporary_hp(overflow_restore_ * overheal_shield_pct_)
#endregion
