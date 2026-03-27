class_name SpellActor
extends Node2D

enum SpellType {
	PROJECTILE,
	INSTANT,
	CONTINUOUS,
}

@export var spell_type: SpellType = SpellType.PROJECTILE
@export var lifetime_seconds: float = 5.0
@export var affect_self: bool = false
@export var affect_friends: bool = false
@export var affect_enemies: bool = true

var owner_actor: Node2D = null
var weapon_instance: WeaponInstance = null
var weapon_data: WeaponData = null
var direction: Vector2 = Vector2.RIGHT
var lifetime_timer: Timer = null
var has_been_activated: bool = false

#region Public
func setup(owner_: Node2D, weapon_instance_: WeaponInstance, direction_: Vector2) -> void:
	assert(owner_actor == null, "SpellActor does not support double setup")
	assert(owner_ != null, "SpellActor requires owner")
	assert(weapon_instance_ != null, "SpellActor requires WeaponInstance")
	assert(weapon_instance_.weapon_data != null, "SpellActor requires WeaponData")
	assert(not direction_.is_zero_approx(), "SpellActor requires a non-zero direction")

	owner_actor = owner_
	weapon_instance = weapon_instance_
	weapon_data = weapon_instance_.weapon_data
	direction = direction_.normalized()
	rotation = direction.angle()

	_ensure_lifetime_timer()
	_setup_spell_actor()


func activate_spell() -> void:
	if has_been_activated:
		return

	has_been_activated = true
	print("[SpellActor] Type: %s" % get_spell_type_name())
	_activate_spell()


func start_lifetime_timer() -> void:
	_ensure_lifetime_timer()
	if lifetime_timer == null or lifetime_seconds <= 0.0:
		return

	lifetime_timer.start(lifetime_seconds)


func complete_spell() -> void:
	if is_queued_for_deletion():
		return

	queue_free()


func get_spell_type_name() -> String:
	return SpellType.keys()[spell_type].to_lower()
#endregion

#region Helpers
func _ensure_lifetime_timer() -> void:
	if lifetime_timer != null:
		return

	lifetime_timer = Timer.new()
	lifetime_timer.name = "LifetimeTimer"
	lifetime_timer.one_shot = true
	add_child(lifetime_timer)
	lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)


func _setup_spell_actor() -> void:
	pass


func _activate_spell() -> void:
	pass


func _on_lifetime_timeout() -> void:
	pass


func _on_lifetime_timer_timeout() -> void:
	_on_lifetime_timeout()
	complete_spell()


func _can_affect_target(target_: Node2D) -> bool:
	if target_ == null:
		return false

	if target_ == owner_actor:
		return affect_self

	var owner_is_player_ := _is_player_aligned(owner_actor)
	var target_is_player_ := _is_player_aligned(target_)
	if owner_is_player_ == target_is_player_:
		return affect_friends

	return affect_enemies


func _is_player_aligned(target_: Node) -> bool:
	if target_ == null:
		return false
	return target_.is_in_group("player")


func _get_target_health_component(target_: Node) -> HealthComponent:
	if target_ == null or not target_.has_method("get_health_component"):
		return null
	return target_.get_health_component() as HealthComponent


func _get_target_hurtbox(target_: Node) -> Hurtbox:
	if target_ == null:
		return null
	return target_.get_node_or_null("Hurtbox") as Hurtbox
#endregion
