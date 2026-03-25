class_name PlayerController
extends CharacterBody2D

@export var walk_speed: float = 140.0
@export var run_speed: float = 220.0
@export var walk_animation_fps: float = 7.0
@export var run_animation_fps: float = 10.0

@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var state_machine: PlayerStateMachine = $StateMachine

var facing_left: bool = false
var animation_time: float = 0.0
var controls_locked: bool = false

#region Public
func get_move_input() -> Vector2:
	if controls_locked:
		return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func is_run_requested() -> bool:
	return Input.is_action_pressed("move_run")


func move_character(input_vector_: Vector2, speed_: float) -> void:
	_update_facing(input_vector_)
	velocity = input_vector_ * speed_
	move_and_slide()


func play_idle_animation() -> void:
	animation_time = 0.0
	sprite.frame = 0


func play_move_animation(delta_: float, animation_fps_: float) -> void:
	animation_time += delta_ * animation_fps_
	sprite.frame = int(animation_time) % sprite.hframes


func set_controls_locked(value_: bool) -> void:
	controls_locked = value_


func get_current_state_name() -> StringName:
	if state_machine == null or state_machine.current_state == null:
		return &""
	return state_machine.current_state.name
#endregion

#region Helpers
func _update_facing(input_vector_: Vector2) -> void:
	if input_vector_.x < 0.0:
		facing_left = true
	elif input_vector_.x > 0.0:
		facing_left = false

	sprite.flip_h = facing_left
#endregion
