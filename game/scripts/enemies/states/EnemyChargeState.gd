class_name EnemyChargeState
extends EnemyState

var charge_timer: float = 0.0
var charge_direction: Vector2 = Vector2.ZERO

#region Public
func enter(_previous_state: StringName = &"") -> void:
	var enemy_: EnemyAIController = get_actor()
	var player_position_: Vector2 = enemy_.get_player_position()

	charge_timer = 0.0
	charge_direction = (player_position_ - enemy_.global_position).normalized()
	if charge_direction == Vector2.ZERO:
		charge_direction = Vector2.LEFT if enemy_.facing_left else Vector2.RIGHT

	enemy_.stop_movement()
	enemy_.reset_charge_visual()
	enemy_.face_direction(charge_direction)
	enemy_.play_charge_animation(0.0)


func physics_update(delta_: float) -> void:
	var enemy_: EnemyAIController = get_actor()
	if enemy_.is_dead():
		enemy_.reset_charge_visual()
		transition_to(&"Dead")
		return

	charge_timer += delta_
	enemy_.stop_movement()
	enemy_.face_direction(charge_direction)
	enemy_.play_charge_animation(delta_)

	if charge_timer < enemy_.charge_duration:
		return

	transition_to(&"Dash")


func exit() -> void:
	get_actor().reset_charge_visual()
#endregion
