class_name EnemyKeepDistanceState
extends EnemyState

@export var preferred_distance_min: float = 100.0
@export var preferred_distance_max: float = 180.0
@export var retreat_distance: float = 50.0
@export var strafe_distance: float = 30.0

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
	if distance_to_player_ <= enemy_.attack_range and enemy_.can_attack():
		enemy_.stop_movement()
		transition_to(&"Attack")
		return

	var direction_to_player_: Vector2 = (player_position_ - enemy_.global_position).normalized()
	var target_position_: Vector2 = enemy_.global_position
	if distance_to_player_ < preferred_distance_min:
		target_position_ = enemy_.global_position - direction_to_player_ * retreat_distance
	elif distance_to_player_ > preferred_distance_max:
		target_position_ = player_position_
	else:
		var perpendicular_: Vector2 = Vector2(-direction_to_player_.y, direction_to_player_.x)
		target_position_ = enemy_.global_position + perpendicular_ * strafe_distance

	var move_direction_: Vector2 = (target_position_ - enemy_.global_position).normalized()
	enemy_.move_character(move_direction_, enemy_.move_speed)
	enemy_.face_direction(direction_to_player_)
	enemy_.play_move_animation(delta_)
#endregion
