class_name Hurtbox
extends Area2D

@export var damage_receiver_path: NodePath = NodePath("../DamageReceiver")

var damage_receiver: DamageReceiver

#region Core Lifecycle
func _ready() -> void:
	damage_receiver = get_node_or_null(damage_receiver_path) as DamageReceiver

	assert(damage_receiver != null, "Hurtbox damage_receiver_path must point to DamageReceiver")
	add_to_group("hurtbox")
#endregion

#region Public
func receive_hit(attack_context_: AttackContext) -> void:
	damage_receiver.receive_hit(attack_context_)
#endregion
