class_name StaffWeapon
extends WeaponController

const PHASE_IDLE: StringName = &"idle"
const PHASE_STARTUP: StringName = &"startup"
const PHASE_ACTIVE: StringName = &"active"
const PHASE_RECOVERY: StringName = &"recovery"

@export var spell_spawn_point_path: NodePath = NodePath("ProjectileSpawnPoint")
@export var attack_cooldown_timer_path: NodePath = NodePath("AttackCooldownTimer")

var spell_spawn_point: Marker2D = null
var attack_cooldown_timer: Timer = null
var attack_phase_timer: Timer = null
var current_phase: StringName = PHASE_IDLE

#region Public
func try_primary_attack() -> bool:
	assert(spell_spawn_point != null, "StaffWeapon spell_spawn_point must be initialized")
	assert(attack_cooldown_timer != null, "StaffWeapon attack_cooldown_timer must be initialized")
	assert(attack_phase_timer != null, "StaffWeapon attack_phase_timer must be initialized")

	if current_phase != PHASE_IDLE:
		return false
	if not attack_cooldown_timer.is_stopped():
		return false

	_begin_attack()
	return true


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
	spell_spawn_point = get_node_or_null(spell_spawn_point_path) as Marker2D
	attack_cooldown_timer = get_node_or_null(attack_cooldown_timer_path) as Timer

	assert(weapon_data.attack_actor_scene != null, "StaffWeapon requires WeaponData.attack_actor_scene")
	assert(spell_spawn_point != null, "StaffWeapon spell_spawn_point_path must point to Marker2D")
	assert(attack_cooldown_timer != null, "StaffWeapon attack_cooldown_timer_path must point to Timer")

	attack_phase_timer = Timer.new()
	attack_phase_timer.name = "AttackPhaseTimer"
	attack_phase_timer.one_shot = true
	add_child(attack_phase_timer)
	attack_phase_timer.timeout.connect(_on_attack_phase_timer_timeout)

	attack_cooldown_timer.wait_time = _get_attack_cooldown_seconds()


func _begin_attack() -> void:
	attack_cooldown_timer.wait_time = _get_attack_cooldown_seconds()
	attack_cooldown_timer.start()

	var attack_profile_ = _get_attack_profile()
	if attack_profile_ != null:
		_play_attack_animation(attack_profile_.animation_name)
		_play_audio_stream(attack_profile_.startup_audio)

	_enter_phase(PHASE_STARTUP)


func _enter_phase(phase_: StringName) -> void:
	current_phase = phase_
	print("[StaffWeapon] Phase: %s" % String(phase_))

	match phase_:
		PHASE_STARTUP:
			_start_phase_timer(_get_startup_seconds())
		PHASE_ACTIVE:
			_spawn_spell_actor()
			_spawn_muzzle_flash()
			_start_phase_timer(_get_active_seconds())
		PHASE_RECOVERY:
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
				print("[Rune][Staff] Endless Blade cooldown refunded")
			current_phase = PHASE_IDLE


func _cancel_attack() -> void:
	current_phase = PHASE_IDLE

	if attack_phase_timer != null:
		attack_phase_timer.stop()
	if attack_cooldown_timer != null:
		attack_cooldown_timer.stop()


func _get_startup_seconds() -> float:
	var attack_profile_ = _get_attack_profile()
	if attack_profile_ == null:
		return 0.0
	return _get_attack_phase_duration_seconds(attack_profile_.startup_frames)


func _get_active_seconds() -> float:
	var attack_profile_ = _get_attack_profile()
	if attack_profile_ == null:
		return 0.0
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

	_spawn_presentation_scene(attack_profile_.muzzle_flash_scene, spell_spawn_point.global_position)


func _spawn_spell_actor() -> void:
	assert(owner_actor != null, "StaffWeapon owner_actor must be initialized")

	var spell_parent_: Node = owner_actor.get_parent()
	assert(spell_parent_ != null, "StaffWeapon owner_actor must have a parent to spawn spell actors")

	var spell_actor_ := weapon_data.attack_actor_scene.instantiate() as SpellActor
	assert(spell_actor_ != null, "WeaponData.attack_actor_scene must instantiate SpellActor")
	var spell_direction_: Vector2 = _get_spell_direction()

	spell_parent_.add_child(spell_actor_)
	spell_actor_.global_position = spell_spawn_point.global_position
	spell_actor_.setup(owner_actor, weapon_instance, spell_direction_)

	match spell_actor_.spell_type:
		SpellActor.SpellType.PROJECTILE:
			print("[StaffWeapon] SpellType: projectile")
			spell_actor_.activate_spell()
		SpellActor.SpellType.INSTANT:
			print("[StaffWeapon] SpellType: instant")
			spell_actor_.activate_spell()
		SpellActor.SpellType.CONTINUOUS:
			print("[StaffWeapon] SpellType: continuous")
			spell_actor_.activate_spell()
			spell_actor_.start_lifetime_timer()


func _should_trigger_endless_blade() -> bool:
	if not _has_active_rune_effect(&"cooldown_refund_on_attack"):
		return false
	var should_trigger_ := _roll_proc(_get_total_weapon_modifier(&"cooldown_refund_chance_pct"))
	var rune_test_manager_ = _get_rune_test_manager()
	if rune_test_manager_ != null and rune_test_manager_.is_test_mode_enabled():
		rune_test_manager_.record_endless_blade_result(should_trigger_)
	return should_trigger_


func _get_spell_direction() -> Vector2:
	assert(owner_actor != null, "StaffWeapon owner_actor must be initialized before resolving spell direction")
	assert(spell_spawn_point != null, "StaffWeapon spell_spawn_point must be initialized before resolving spell direction")

	var mouse_position_: Vector2 = owner_actor.get_global_mouse_position()
	var spell_origin_: Vector2 = spell_spawn_point.global_position
	var spell_direction_: Vector2 = mouse_position_ - spell_origin_
	if spell_direction_.is_zero_approx():
		return _get_attack_direction()

	return spell_direction_.normalized()
#endregion
