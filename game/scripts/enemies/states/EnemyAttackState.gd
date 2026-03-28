class_name EnemyAttackState
extends EnemyState

var attack_timer: float = 0.0

#region Public
func enter(_previous_state: StringName = &"") -> void:
	var enemy_: EnemyAIController = get_actor()

	attack_timer = 0.0
	enemy_.stop_movement()
	enemy_.play_attack_animation(0.0)
	if enemy_.attack_type == EnemyAIController.AttackType.MELEE:
		enemy_.perform_attack()
	else:
		enemy_.perform_ranged_attack()
	enemy_.mark_attack_started()


func physics_update(delta_: float) -> void:
	var enemy_: EnemyAIController = get_actor()
	if enemy_.is_dead():
		transition_to(&"Dead")
		return

	enemy_.stop_movement()
	enemy_.play_attack_animation(delta_)

	attack_timer += delta_
	if attack_timer < enemy_.attack_cooldown:
		return

	if enemy_.can_see_player():
		transition_to(enemy_.get_combat_movement_state_name())
		return

	transition_to(&"Idle")
#endregion
