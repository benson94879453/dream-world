extends PlayerState

#region Public
func enter(_previous_state: StringName = &"") -> void:
	var player_ := get_actor()
	player_.move_character(Vector2.ZERO, 0.0)
	player_.play_idle_animation()


func physics_update(_delta: float) -> void:
	var player_ := get_actor()
	player_.move_character(Vector2.ZERO, 0.0)
	player_.play_idle_animation()


func get_transition() -> StringName:
	var player_ := get_actor()

	if player_.is_controls_locked():
		return &"Locked"

	var input_vector_ := player_.get_move_input()
	if input_vector_ == Vector2.ZERO:
		return &""
	if player_.is_run_requested():
		return &"Run"
	return &"Walk"
#endregion
