class_name PlayerDashState
extends PlayerState

var dash_time_elapsed: float = 0.0
var queued_transition: StringName = &""

#region Public
func enter(_previous_state: StringName = &"") -> void:
	var player_ := get_actor()

	dash_time_elapsed = 0.0
	queued_transition = &""
	player_.start_dash()

	if player_.dash_invincible:
		player_.set_invincible(true)

	player_.enable_dash_ghost(true)


func physics_update(delta_: float) -> void:
	var player_ := get_actor()

	dash_time_elapsed += delta_
	player_.perform_dash_movement(delta_)
	player_.play_dash_animation(delta_)

	if dash_time_elapsed < player_.dash_duration:
		return

	queued_transition = player_.resolve_locomotion_state_name()


func exit() -> void:
	var player_ := get_actor()

	player_.end_dash()

	if player_.dash_invincible:
		player_.set_invincible(false)

	player_.enable_dash_ghost(false)
	player_.start_dash_cooldown()
	queued_transition = &""


func get_transition() -> StringName:
	return queued_transition
#endregion
