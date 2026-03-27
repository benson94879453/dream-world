extends PlayerState

#region Public
func physics_update(delta_: float) -> void:
	var player_ := get_actor()
	var input_vector_ := player_.get_move_input()
	player_.move_character(input_vector_, player_.run_speed)
	player_.play_move_animation(delta_, player_.run_animation_fps)


func get_transition() -> StringName:
	var player_ := get_actor()

	if player_.is_controls_locked():
		return &"Locked"

	var input_vector_ := player_.get_move_input()
	if input_vector_ == Vector2.ZERO:
		return &"Idle"
	if not player_.is_run_requested():
		return &"Walk"
	return &""
#endregion
