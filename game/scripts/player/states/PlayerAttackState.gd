class_name PlayerAttackState
extends PlayerState

const PHASE_IDLE: StringName = &"idle"
const DASH_STATE: StringName = &"Dash"

var queued_transition: StringName = &""
var combo_queued: bool = false

#region Public
func enter(_previous_state: StringName = &"") -> void:
	queued_transition = &""
	combo_queued = false

	var player_ := get_actor()
	player_.move_character(Vector2.ZERO, 0.0)
	player_.play_idle_animation()

	if not _try_start_attack():
		queued_transition = player_.resolve_locomotion_state_name()


func exit() -> void:
	queued_transition = &""
	combo_queued = false


func handle_input(event_: InputEvent) -> void:
	var key_event_ := event_ as InputEventKey
	if key_event_ != null and key_event_.echo:
		return

	var player_ := get_actor()
	var weapon_ := player_.get_equipped_weapon_controller()
	if weapon_ == null:
		return

	if event_.is_action_pressed("dash") and player_.can_perform_dash():
		combo_queued = false
		queued_transition = &""
		weapon_.cancel_attack()
		(get_parent() as PlayerStateMachine).transition_to(DASH_STATE)
		return

	if event_.is_action_pressed("attack") and weapon_.can_combo():
		combo_queued = true


func physics_update(_delta: float) -> void:
	var player_ := get_actor()
	player_.move_character(Vector2.ZERO, 0.0)
	player_.play_idle_animation()

	if not queued_transition.is_empty():
		return

	var weapon_ := player_.get_equipped_weapon_controller()
	if weapon_ == null:
		queued_transition = player_.resolve_locomotion_state_name()
		return

	if weapon_.get_current_phase() != PHASE_IDLE:
		return

	if combo_queued and _try_start_combo_attack():
		return

	queued_transition = player_.resolve_locomotion_state_name()


func get_transition() -> StringName:
	return queued_transition


func is_combo_queued() -> bool:
	return combo_queued
#endregion

#region Helpers
func _try_start_attack() -> bool:
	var weapon_ := get_actor().get_equipped_weapon_controller()
	if weapon_ == null:
		return false
	return weapon_.try_primary_attack()


func _try_start_combo_attack() -> bool:
	var weapon_ := get_actor().get_equipped_weapon_controller()
	if weapon_ == null:
		return false

	if not weapon_.try_primary_attack():
		weapon_.cancel_attack()
		if not weapon_.try_primary_attack():
			return false

	combo_queued = false
	return true
#endregion
