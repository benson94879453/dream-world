class_name EnemyDashState
extends EnemyState

var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

#region Public
func enter(_previous_state: StringName = &"") -> void:
	var enemy_: EnemyAIController = get_actor()
	var player_position_: Vector2 = enemy_.get_player_position()

	dash_timer = 0.0
	dash_direction = (player_position_ - enemy_.global_position).normalized()
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2.LEFT if enemy_.facing_left else Vector2.RIGHT

	enemy_.reset_charge_visual()
	enemy_.face_direction(dash_direction)
	enemy_.start_dash_attack()


func physics_update(delta_: float) -> void:
	var enemy_: EnemyAIController = get_actor()
	if enemy_.is_dead():
		enemy_.end_dash_attack()
		transition_to(&"Dead")
		return

	enemy_.velocity = dash_direction * enemy_.dash_speed
	enemy_.move_and_slide()
	enemy_.play_move_animation(delta_)

	dash_timer += delta_
	if dash_timer < enemy_.dash_duration:
		return

	transition_to(&"Idle")


func exit() -> void:
	var enemy_: EnemyAIController = get_actor()
	enemy_.velocity = Vector2.ZERO
	enemy_.end_dash_attack()
	enemy_.start_dash_cooldown()
#endregion
