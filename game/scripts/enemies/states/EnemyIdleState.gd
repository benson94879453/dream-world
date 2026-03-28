class_name EnemyIdleState
extends EnemyState

#region Public
func enter(_previous_state: StringName = &"") -> void:
	var enemy_: EnemyAIController = get_actor()
	enemy_.stop_movement()
	enemy_.play_idle_animation(0.0)


func physics_update(delta_: float) -> void:
	var enemy_: EnemyAIController = get_actor()
	enemy_.stop_movement()
	enemy_.play_idle_animation(delta_)

	if enemy_.is_dead():
		transition_to(&"Dead")
		return

	if not enemy_.can_see_player():
		return

	var player_position_: Vector2 = enemy_.get_player_position()
	var distance_to_player_: float = enemy_.global_position.distance_to(player_position_)
	if enemy_.should_start_charge(distance_to_player_):
		transition_to(&"Charge")
		return

	transition_to(enemy_.get_combat_movement_state_name())
#endregion
