class_name PlayerController
extends CharacterBody2D

@export var walk_speed: float = 140.0
@export var run_speed: float = 220.0
@export var walk_animation_fps: float = 7.0
@export var run_animation_fps: float = 10.0
@export var equipped_weapon_data: WeaponData

var facing_left: bool = false
var animation_time: float = 0.0
var controls_locked: bool = false
var equipped_weapon: WeaponInstance = null
var equipped_weapon_controller: WeaponController = null

@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var weapon_pivot: Marker2D = $WeaponPivot
@onready var health_component: HealthComponent = $HealthComponent

#region Core Lifecycle
func _ready() -> void:
	assert(sprite != null, "PlayerController requires Sprite2D")
	assert(state_machine != null, "PlayerController requires StateMachine")
	assert(weapon_pivot != null, "PlayerController requires WeaponPivot")
	assert(health_component != null, "PlayerController requires HealthComponent")
	assert(equipped_weapon_data != null, "PlayerController requires equipped_weapon_data")

	equip_weapon_data(equipped_weapon_data)
	add_to_group("player")
	state_machine.start()


func _unhandled_input(event_: InputEvent) -> void:
	if controls_locked:
		return

	if event_.is_action_pressed("attack"):
		_start_attack()
#endregion

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


func get_health_component() -> HealthComponent:
	return health_component


func get_equipped_weapon() -> WeaponInstance:
	return equipped_weapon


func get_equipped_weapon_controller() -> WeaponController:
	return equipped_weapon_controller


func get_equipped_weapon_id() -> StringName:
	assert(equipped_weapon != null, "PlayerController equipped_weapon must be initialized")
	return equipped_weapon.weapon_id


func is_facing_left() -> bool:
	return facing_left


func get_attack_direction() -> Vector2:
	return Vector2.LEFT if facing_left else Vector2.RIGHT


func equip_weapon_data(weapon_data_: WeaponData) -> void:
	assert(weapon_data_ != null, "PlayerController cannot equip null WeaponData")
	assert(weapon_data_.weapon_scene != null, "PlayerController requires WeaponData.weapon_scene")

	_clear_equipped_weapon_controller()

	equipped_weapon_data = weapon_data_
	equipped_weapon = WeaponInstance.create_from_data(weapon_data_)
	equipped_weapon_controller = _instantiate_weapon_controller(weapon_data_)
	equipped_weapon_controller.setup(self, equipped_weapon)
	equipped_weapon_controller.on_equipped()
#endregion

#region Helpers
func _start_attack() -> void:
	assert(equipped_weapon_controller != null, "PlayerController equipped_weapon_controller must be initialized")
	equipped_weapon_controller.try_primary_attack()


func _instantiate_weapon_controller(weapon_data_: WeaponData) -> WeaponController:
	var weapon_controller_ := weapon_data_.weapon_scene.instantiate() as WeaponController
	assert(weapon_controller_ != null, "WeaponData.weapon_scene must instantiate WeaponController")

	weapon_pivot.add_child(weapon_controller_)
	return weapon_controller_


func _clear_equipped_weapon_controller() -> void:
	if equipped_weapon_controller == null:
		return

	var weapon_controller_parent_ := equipped_weapon_controller.get_parent()
	if weapon_controller_parent_ != null:
		weapon_controller_parent_.remove_child(equipped_weapon_controller)

	equipped_weapon_controller.on_unequipped()
	equipped_weapon_controller.queue_free()
	equipped_weapon_controller = null


func _update_facing(input_vector_: Vector2) -> void:
	if input_vector_.x < 0.0:
		facing_left = true
	elif input_vector_.x > 0.0:
		facing_left = false
	# Keep the previous facing when input_vector_.x = 0.0

	sprite.flip_h = facing_left
	weapon_pivot.scale.x = -1.0 if facing_left else 1.0
#endregion
