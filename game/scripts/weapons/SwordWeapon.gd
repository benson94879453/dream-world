class_name SwordWeapon
extends WeaponController

const PHASE_IDLE: StringName = &"idle"
const PHASE_STARTUP: StringName = &"startup"
const PHASE_ACTIVE: StringName = &"active"
const PHASE_RECOVERY: StringName = &"recovery"

@export var attack_hitbox_path: NodePath = NodePath("AttackHitbox")
@export var attack_hitbox_collision_path: NodePath = NodePath("AttackHitbox/AttackHitboxCollision")
@export var attack_cooldown_timer_path: NodePath = NodePath("AttackCooldownTimer")

var attack_hitbox: Hitbox = null
var attack_hitbox_collision: CollisionShape2D = null
var attack_cooldown_timer: Timer = null
var attack_phase_timer: Timer = null
var current_phase: StringName = PHASE_IDLE
var default_active_duration: float = 0.0

#region Public
func try_primary_attack() -> bool:
	assert(attack_hitbox != null, "SwordWeapon attack_hitbox must be initialized")
	assert(attack_cooldown_timer != null, "SwordWeapon attack_cooldown_timer must be initialized")
	assert(attack_phase_timer != null, "SwordWeapon attack_phase_timer must be initialized")

	if current_phase != PHASE_IDLE:
		return false
	if not attack_cooldown_timer.is_stopped():
		return false

	_begin_attack()
	return true


func can_combo() -> bool:
	if current_phase == PHASE_ACTIVE:
		return true

	if current_phase != PHASE_RECOVERY or attack_phase_timer == null:
		return false

	var recovery_seconds_: float = _get_recovery_seconds()
	if recovery_seconds_ <= 0.0:
		return false

	return attack_phase_timer.time_left >= recovery_seconds_ * 0.5


func get_current_phase() -> StringName:
	return current_phase


func cancel_attack() -> void:
	_cancel_attack()


func on_unequipped() -> void:
	_cancel_attack()
	if startup_audio_player != null:
		startup_audio_player.stop()
#endregion

#region Helpers
func _setup_weapon() -> void:
	attack_hitbox = get_node_or_null(attack_hitbox_path) as Hitbox
	attack_hitbox_collision = get_node_or_null(attack_hitbox_collision_path) as CollisionShape2D
	attack_cooldown_timer = get_node_or_null(attack_cooldown_timer_path) as Timer

	assert(attack_hitbox != null, "SwordWeapon attack_hitbox_path must point to Hitbox")
	assert(attack_hitbox_collision != null, "SwordWeapon attack_hitbox_collision_path must point to CollisionShape2D")
	assert(attack_cooldown_timer != null, "SwordWeapon attack_cooldown_timer_path must point to Timer")

	var hitbox_shape_ := attack_hitbox_collision.shape as RectangleShape2D
	assert(hitbox_shape_ != null, "SwordWeapon attack hitbox shape must be RectangleShape2D")

	attack_phase_timer = Timer.new()
	attack_phase_timer.name = "AttackPhaseTimer"
	attack_phase_timer.one_shot = true
	add_child(attack_phase_timer)
	attack_phase_timer.timeout.connect(_on_attack_phase_timer_timeout)
	attack_hitbox.hit_landed.connect(_on_attack_hitbox_hit)

	attack_hitbox.source_root = owner_actor
	default_active_duration = attack_hitbox.active_duration
	hitbox_shape_.size.x = 18.0 * maxf(weapon_instance.get_attack_range(), 0.25)
	attack_hitbox_collision.position.x = hitbox_shape_.size.x * 0.5
	_refresh_attack_profile()
	attack_hitbox.deactivate()


func _begin_attack() -> void:
	_refresh_attack_profile()
	_refresh_attack_hitbox_state()
	attack_cooldown_timer.wait_time = _get_attack_cooldown_seconds()
	attack_cooldown_timer.start()

	var attack_profile_ = _get_attack_profile()
	if attack_profile_ != null:
		_play_attack_animation(attack_profile_.animation_name)
		_play_audio_stream(attack_profile_.startup_audio)

	_enter_phase(PHASE_STARTUP)


func _refresh_attack_profile() -> void:
	var attack_profile_ = _get_attack_profile()
	attack_hitbox.hit_audio = attack_profile_.hit_audio if attack_profile_ != null else null
	attack_hitbox.hit_effect_scene = attack_profile_.hit_effect_scene if attack_profile_ != null else null


func _enter_phase(phase_: StringName) -> void:
	current_phase = phase_
	print("[SwordWeapon] Phase: %s" % String(phase_))

	match phase_:
		PHASE_STARTUP:
			_start_phase_timer(_get_startup_seconds())
		PHASE_ACTIVE:
			attack_hitbox.active_duration = _get_active_seconds()
			_spawn_muzzle_flash()
			if attack_hitbox.active_duration > 0.0:
				attack_hitbox.activate()
			_start_phase_timer(attack_hitbox.active_duration)
		PHASE_RECOVERY:
			attack_hitbox.deactivate()
			_start_phase_timer(_get_recovery_seconds())
		_:
			current_phase = PHASE_IDLE


func _start_phase_timer(duration_seconds_: float) -> void:
	attack_phase_timer.stop()
	if duration_seconds_ <= 0.0:
		_on_attack_phase_timer_timeout()
		return

	attack_phase_timer.wait_time = duration_seconds_
	attack_phase_timer.start()


func _on_attack_phase_timer_timeout() -> void:
	match current_phase:
		PHASE_STARTUP:
			_enter_phase(PHASE_ACTIVE)
		PHASE_ACTIVE:
			_enter_phase(PHASE_RECOVERY)
		PHASE_RECOVERY:
			if _should_trigger_endless_blade():
				attack_cooldown_timer.stop()
				print("[Rune][Sword] Endless Blade cooldown refunded")
			current_phase = PHASE_IDLE


func _cancel_attack() -> void:
	current_phase = PHASE_IDLE

	if attack_phase_timer != null:
		attack_phase_timer.stop()
	if attack_cooldown_timer != null:
		attack_cooldown_timer.stop()
	if attack_hitbox != null:
		attack_hitbox.deactivate()


func _get_startup_seconds() -> float:
	var attack_profile_ = _get_attack_profile()
	if attack_profile_ == null:
		return 0.0
	return _get_attack_phase_duration_seconds(attack_profile_.startup_frames)


func _get_active_seconds() -> float:
	var attack_profile_ = _get_attack_profile()
	if attack_profile_ == null:
		return default_active_duration
	return _get_attack_phase_duration_seconds(attack_profile_.active_frames)


func _get_recovery_seconds() -> float:
	var attack_profile_ = _get_attack_profile()
	if attack_profile_ == null:
		return 0.0
	return _get_attack_phase_duration_seconds(attack_profile_.recovery_frames)


func _spawn_muzzle_flash() -> void:
	var attack_profile_ = _get_attack_profile()
	if attack_profile_ == null:
		return

	_spawn_presentation_scene(attack_profile_.muzzle_flash_scene, attack_hitbox_collision.global_position)


func _refresh_attack_hitbox_state() -> void:
	attack_hitbox.base_damage = weapon_instance.get_base_attack()
	attack_hitbox.weapon_instance = weapon_instance
	attack_hitbox.attack_tags = _get_attack_tags([&"melee", weapon_data.weapon_type])


func _should_trigger_endless_blade() -> bool:
	if not _has_active_rune_effect(&"cooldown_refund_on_attack"):
		return false
	var should_trigger_ := _roll_proc(_get_total_weapon_modifier(&"cooldown_refund_chance_pct"))
	_record_endless_blade_test_result(should_trigger_)
	return should_trigger_


func _on_attack_hitbox_hit(hurtbox_: Hurtbox, attack_context_: AttackContext, _applied_damage_: float) -> void:
	if hurtbox_ == null or attack_context_ == null:
		return
	if not _should_trigger_double_strike(attack_context_):
		return

	print("[Rune][Sword] Double Strike triggered")
	_trigger_double_strike(hurtbox_, attack_context_.duplicate_context())


func _should_trigger_double_strike(attack_context_: AttackContext) -> bool:
	if attack_context_ == null or not attack_context_.tags.has(&"melee"):
		return false
	if not _has_active_rune_effect(&"double_strike_on_melee_hit"):
		return false
	var should_trigger_ := _roll_proc(_get_total_weapon_modifier(&"double_strike_chance_pct"))
	_record_double_strike_test_result(should_trigger_)
	return should_trigger_


func _trigger_double_strike(hurtbox_: Hurtbox, attack_context_: AttackContext) -> void:
	attack_context_.can_trigger_on_hit = false
	_resolve_double_strike_hit(hurtbox_, attack_context_)


func _resolve_double_strike_hit(hurtbox_: Hurtbox, attack_context_: AttackContext) -> void:
	await get_tree().create_timer(0.05).timeout
	if hurtbox_ == null or attack_context_ == null:
		return
	if not is_instance_valid(hurtbox_) or not is_inside_tree():
		return

	hurtbox_.receive_hit(attack_context_)


func _record_endless_blade_test_result(triggered_: bool) -> void:
	var rune_test_manager_ = _get_rune_test_manager()
	if rune_test_manager_ == null or not rune_test_manager_.is_test_mode_enabled():
		return

	rune_test_manager_.record_endless_blade_result(triggered_)


func _record_double_strike_test_result(triggered_: bool) -> void:
	var rune_test_manager_ = _get_rune_test_manager()
	if rune_test_manager_ == null or not rune_test_manager_.is_test_mode_enabled():
		return

	rune_test_manager_.record_double_strike_result(triggered_)
#endregion
