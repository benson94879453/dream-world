class_name EnemyChaseState
extends EnemyState

#region Public
func enter(_previous_state: StringName = &"") -> void:
	var enemy_: EnemyAIController = get_actor()
	enemy_.play_move_animation(0.0)


func physics_update(delta_: float) -> void:
	var enemy_: EnemyAIController = get_actor()
	if enemy_.is_dead():
		transition_to(&"Dead")
		return

	if not enemy_.can_see_player():
		transition_to(&"Idle")
		return

	var player_position_: Vector2 = enemy_.get_player_position()
	var distance_to_player_: float = enemy_.global_position.distance_to(player_position_)
	if enemy_.should_start_charge(distance_to_player_):
		enemy_.stop_movement()
		transition_to(&"Charge")
		return

	if distance_to_player_ <= enemy_.attack_range and enemy_.has_state(&"Attack"):
		enemy_.stop_movement()
		transition_to(&"Attack")
		return

	var direction_: Vector2 = (player_position_ - enemy_.global_position).normalized()
	enemy_.move_character(direction_, enemy_.chase_speed)
	enemy_.face_direction(direction_)
	enemy_.play_move_animation(delta_)
#endregion
