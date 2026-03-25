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
func receive_hit(attack_context_: AttackContext) -> void:
	var applied_damage_: float = health_component.apply_damage(attack_context_.base_damage)
	if applied_damage_ <= 0.0:
		return

	feedback_receiver.play_hit_feedback(attack_context_)
	hit_received.emit(attack_context_, applied_damage_)
#endregion
