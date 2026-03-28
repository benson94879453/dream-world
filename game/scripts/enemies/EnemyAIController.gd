class_name EnemyAIController
extends CharacterBody2D

const DropComponentNode = preload("res://game/scripts/components/DropComponent.gd")
const EnemyInstanceResource = preload("res://game/scripts/data/EnemyInstance.gd")

enum AttackType {
	MELEE,
	RANGED
}

@export var enemy_data: EnemyData = null
@export var player_detection_ray_path: NodePath = NodePath("PlayerDetectionRay")
@export var attack_type: AttackType = AttackType.MELEE
@export var projectile_scene: PackedScene = null
@export var projectile_spawn_offset: Vector2 = Vector2(0.0, -10.0)
@export var idle_animation_fps: float = 4.0
@export var move_animation_fps: float = 7.0
@export var attack_animation_fps: float = 10.0
@export var charge_animation_row: int = 3
@export var idle_animation_row: int = 0
@export var move_animation_row: int = 1
@export var attack_animation_row: int = 2
@export var dead_animation_row: int = 5
@export var dead_animation_column: int = 0
@export var animation_frame_count: int = 4
@export var hitbox_forward_offset: float = 14.0

var enemy_instance: EnemyInstance = null
var move_speed: float = 0.0
var chase_speed: float = 0.0
var detection_radius: float = 0.0
var attack_range: float = 0.0
var attack_cooldown: float = 0.0
var dash_attack_range: float = 0.0
var dash_cooldown: float = 0.0
var charge_duration: float = 0.0
var charge_animation_fps: float = 0.0
var dash_speed: float = 0.0
var dash_duration: float = 0.0
var facing_left: bool = false
var has_died: bool = false
var animation_time: float = 0.0
var current_animation_name: StringName = &""
var tracked_player: PlayerController = null
var next_attack_time_msec: int = 0
var dash_cooldown_timer: float = 0.0

@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var state_machine: EnemyStateMachine = $StateMachine
@onready var player_detection_ray: RayCast2D = get_node_or_null(player_detection_ray_path) as RayCast2D
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/DetectionCollision
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = get_node_or_null("Hitbox") as Hitbox
@onready var dash_hitbox: Hitbox = get_node_or_null("DashHitbox") as Hitbox
@onready var feedback_receiver: FeedbackReceiver = $FeedbackReceiver
@onready var drop_component: DropComponentNode = $DropComponent

#region Core Lifecycle
func _ready() -> void:
	assert(enemy_data != null, "EnemyAIController requires enemy_data")
	assert(sprite != null, "EnemyAIController requires Sprite2D")
	assert(state_machine != null, "EnemyAIController requires StateMachine")
	assert(detection_area != null, "EnemyAIController requires DetectionArea")
	assert(detection_shape != null, "EnemyAIController requires DetectionCollision")
	assert(health_component != null, "EnemyAIController requires HealthComponent")
	assert(hurtbox != null, "EnemyAIController requires Hurtbox")
	assert(feedback_receiver != null, "EnemyAIController requires FeedbackReceiver")
	assert(drop_component != null, "EnemyAIController requires DropComponent")
	if _supports_charge_dash_behavior():
		assert(dash_hitbox != null, "Charge/Dash EnemyAIController requires DashHitbox")
	elif attack_type == AttackType.MELEE:
		assert(hitbox != null, "Melee EnemyAIController requires Hitbox")
	else:
		assert(projectile_scene != null, "Ranged EnemyAIController requires projectile_scene")

	add_to_group("enemy_ai")
	add_to_group("debug_enemy")

	_initialize_from_enemy_data()
	if _supports_charge_dash_behavior():
		assert(charge_duration > 0.5, "Charge/Dash EnemyAIController charge_duration must be greater than 0.5")
		assert(dash_duration > 0.0, "Charge/Dash EnemyAIController dash_duration must be greater than 0")
		assert(dash_speed > 0.0, "Charge/Dash EnemyAIController dash_speed must be greater than 0")
	_configure_detection_area()
	_configure_hitbox()

	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)

	state_machine.start()


func _physics_process(delta_: float) -> void:
	if dash_cooldown_timer <= 0.0:
		return

	dash_cooldown_timer = maxf(dash_cooldown_timer - delta_, 0.0)
#endregion

#region Public
func can_see_player() -> bool:
	if has_died:
		return false

	var player_: PlayerController = _resolve_player_target()
	if player_ == null:
		return false

	if detection_area.has_method("overlaps_body") and not detection_area.overlaps_body(player_):
		return false

	if player_detection_ray == null:
		return true

	player_detection_ray.target_position = to_local(player_.global_position)
	player_detection_ray.force_raycast_update()
	if not player_detection_ray.is_colliding():
		return true

	var collider_ := player_detection_ray.get_collider() as Node
	if collider_ == null:
		return false

	return collider_ == player_ or player_.is_ancestor_of(collider_)


func get_player_position() -> Vector2:
	var player_: PlayerController = _resolve_player_target()
	assert(player_ != null, "EnemyAIController requires a tracked player before position lookup")
	return player_.global_position


func move_character(direction_: Vector2, speed_: float) -> void:
	velocity = direction_ * speed_
	move_and_slide()


func stop_movement() -> void:
	velocity = Vector2.ZERO
	move_and_slide()


func face_direction(direction_: Vector2) -> void:
	if direction_.x < 0.0:
		facing_left = true
	elif direction_.x > 0.0:
		facing_left = false

	sprite.flip_h = facing_left
	_update_hitbox_facing(hitbox)
	_update_hitbox_facing(dash_hitbox)


func perform_attack() -> void:
	assert(attack_type == AttackType.MELEE, "EnemyAIController.perform_attack is only valid for melee enemies")
	assert(hitbox != null, "EnemyAIController requires Hitbox before attack")
	if has_died:
		return

	var player_: PlayerController = _resolve_player_target()
	if player_ != null:
		face_direction((player_.global_position - global_position).normalized())

	hitbox.activate()


func perform_ranged_attack() -> void:
	assert(attack_type == AttackType.RANGED, "EnemyAIController.perform_ranged_attack is only valid for ranged enemies")
	assert(projectile_scene != null, "Ranged EnemyAIController requires projectile_scene")

	if has_died:
		return

	var player_: PlayerController = _resolve_player_target()
	if player_ == null:
		return

	var direction_: Vector2 = (player_.global_position - global_position).normalized()
	face_direction(direction_)

	var projectile_ := projectile_scene.instantiate() as EnemyProjectile
	assert(projectile_ != null, "projectile_scene must instantiate EnemyProjectile")
	assert(get_tree().current_scene != null, "EnemyAIController requires current_scene for projectile spawn")

	var spawn_offset_: Vector2 = projectile_spawn_offset
	spawn_offset_.x *= -1.0 if facing_left else 1.0
	projectile_.setup(direction_, self)
	get_tree().current_scene.add_child(projectile_)
	projectile_.global_position = global_position + spawn_offset_


func can_attack() -> bool:
	return Time.get_ticks_msec() >= next_attack_time_msec


func mark_attack_started() -> void:
	next_attack_time_msec = Time.get_ticks_msec() + ceili(attack_cooldown * 1000.0)


func die() -> void:
	if has_died:
		return

	has_died = true
	velocity = Vector2.ZERO
	if hitbox != null:
		hitbox.deactivate()
	if dash_hitbox != null:
		dash_hitbox.deactivate()
	hurtbox.monitoring = false
	hurtbox.monitorable = false
	drop_component.on_death()
	reset_charge_visual()
	play_dead_animation()


func is_dead() -> bool:
	return has_died or health_component.is_dead()


func play_idle_animation(delta_: float) -> void:
	_play_loop_animation(&"idle", delta_, idle_animation_row, animation_frame_count, idle_animation_fps)


func play_move_animation(delta_: float) -> void:
	_play_loop_animation(&"move", delta_, move_animation_row, animation_frame_count, move_animation_fps)


func play_attack_animation(delta_: float) -> void:
	_play_loop_animation(&"attack", delta_, attack_animation_row, animation_frame_count, attack_animation_fps)


func play_charge_animation(delta_: float) -> void:
	if current_animation_name != &"charge":
		current_animation_name = &"charge"
		animation_time = 0.0
	else:
		animation_time += delta_ * charge_animation_fps

	var safe_frame_count_: int = maxi(animation_frame_count, 1)
	var frame_column_: int = int(animation_time) % safe_frame_count_
	sprite.frame_coords = Vector2i(frame_column_, charge_animation_row)

	var flash_phase_: float = sin(animation_time * PI * 2.0)
	sprite.modulate = Color(1.35, 0.9, 0.9, 1.0) if flash_phase_ > 0.0 else Color.WHITE


func reset_charge_visual() -> void:
	sprite.modulate = Color.WHITE


func play_dead_animation() -> void:
	current_animation_name = &"dead"
	animation_time = 0.0
	sprite.modulate = Color.WHITE
	sprite.frame_coords = Vector2i(dead_animation_column, dead_animation_row)


func get_current_state_name() -> StringName:
	if state_machine == null or state_machine.current_state == null:
		return &""
	return state_machine.current_state.name


func get_health_component() -> HealthComponent:
	return health_component


func get_debug_distance_to_player() -> float:
	var player_: PlayerController = _resolve_player_target()
	if player_ == null:
		return -1.0
	return global_position.distance_to(player_.global_position)


func get_debug_can_see_player() -> bool:
	return can_see_player()


func get_debug_dash_cooldown() -> float:
	return dash_cooldown_timer


func get_enemy_id() -> StringName:
	if enemy_data == null:
		return &""
	return enemy_data.enemy_id


func get_combat_movement_state_name() -> StringName:
	var preferred_state_name_: StringName = &"KeepDistance" if attack_type == AttackType.RANGED else &"Chase"
	var preferred_state_ := state_machine.get_node_or_null(NodePath(str(preferred_state_name_))) as EnemyState
	if preferred_state_ != null:
		return preferred_state_name_

	var fallback_state_ := state_machine.get_node_or_null(NodePath("Chase")) as EnemyState
	assert(fallback_state_ != null, "EnemyAIController requires a combat movement state")
	return &"Chase"


func can_dash_attack() -> bool:
	return dash_cooldown_timer <= 0.0


func has_state(state_name_: StringName) -> bool:
	var state_ := state_machine.get_node_or_null(NodePath(str(state_name_))) as EnemyState
	return state_ != null


func should_start_charge(distance_to_player_: float) -> bool:
	return _supports_charge_dash_behavior() and can_dash_attack() and distance_to_player_ <= dash_attack_range


func start_dash_attack() -> void:
	if dash_hitbox == null:
		return

	dash_hitbox.activate()


func end_dash_attack() -> void:
	if dash_hitbox == null:
		return

	dash_hitbox.deactivate()


func start_dash_cooldown() -> void:
	dash_cooldown_timer = dash_cooldown
#endregion

#region Helpers
func _initialize_from_enemy_data() -> void:
	assert(enemy_data.enemy_scene != null, "EnemyAIController requires EnemyData.enemy_scene")

	enemy_instance = EnemyInstanceResource.create_from_data(enemy_data)
	move_speed = enemy_data.move_speed
	chase_speed = enemy_data.chase_speed
	detection_radius = enemy_data.detection_radius
	attack_range = enemy_data.attack_range
	attack_cooldown = enemy_data.attack_cooldown
	dash_attack_range = enemy_data.dash_attack_range
	dash_cooldown = enemy_data.dash_cooldown
	charge_duration = enemy_data.charge_duration
	charge_animation_fps = enemy_data.charge_animation_fps
	dash_speed = enemy_data.dash_speed
	dash_duration = enemy_data.dash_duration

	health_component.max_hp = float(enemy_data.max_hp)
	health_component.current_hp = float(enemy_data.max_hp)
	drop_component.loot_table = enemy_data.loot_table

	enemy_instance.current_hp = health_component.current_hp


func _configure_detection_area() -> void:
	var circle_shape_ := detection_shape.shape as CircleShape2D
	assert(circle_shape_ != null, "EnemyAIController DetectionCollision must use CircleShape2D")

	circle_shape_.radius = detection_radius


func _configure_hitbox() -> void:
	_configure_single_hitbox(hitbox)
	_configure_single_hitbox(dash_hitbox)


func _configure_single_hitbox(hitbox_: Hitbox) -> void:
	if hitbox_ == null:
		return

	hitbox_.attacker_faction = &"enemy"
	hitbox_.source_root = self
	if hitbox_ == dash_hitbox:
		hitbox_.active_duration = dash_duration
	_update_hitbox_facing(hitbox_)


func _resolve_player_target() -> PlayerController:
	if tracked_player != null and is_instance_valid(tracked_player):
		return tracked_player

	var player_ := get_tree().get_first_node_in_group("player") as PlayerController
	if player_ == null:
		tracked_player = null
		return null

	tracked_player = player_
	return tracked_player


func _play_loop_animation(
	animation_name_: StringName,
	delta_: float,
	row_: int,
	frame_count_: int,
	fps_: float
) -> void:
	if current_animation_name != animation_name_:
		current_animation_name = animation_name_
		animation_time = 0.0
	else:
		animation_time += delta_ * fps_

	var safe_frame_count_: int = maxi(frame_count_, 1)
	var frame_column_: int = int(animation_time) % safe_frame_count_
	sprite.frame_coords = Vector2i(frame_column_, row_)


func _update_hitbox_facing(hitbox_: Hitbox) -> void:
	if hitbox_ == null:
		return

	var hitbox_position_: Vector2 = hitbox_.position
	hitbox_position_.x = -absf(hitbox_forward_offset) if facing_left else absf(hitbox_forward_offset)
	hitbox_.position = hitbox_position_


func _supports_charge_dash_behavior() -> bool:
	var charge_state_ := state_machine.get_node_or_null(NodePath("Charge")) as EnemyState
	var dash_state_ := state_machine.get_node_or_null(NodePath("Dash")) as EnemyState
	return charge_state_ != null and dash_state_ != null


func _on_detection_body_entered(body_: Node) -> void:
	var player_ := body_ as PlayerController
	if player_ == null:
		return

	tracked_player = player_


func _on_detection_body_exited(body_: Node) -> void:
	if body_ != tracked_player:
		return

	tracked_player = null


func _on_health_changed(current_hp_: float, _max_hp_: float) -> void:
	if enemy_instance == null:
		return

	enemy_instance.current_hp = current_hp_


func _on_died() -> void:
	state_machine.transition_to(&"Dead")
#endregion
