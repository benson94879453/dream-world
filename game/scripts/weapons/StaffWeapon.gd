class_name StaffWeapon
extends WeaponController

@export var spell_spawn_point_path: NodePath = NodePath("ProjectileSpawnPoint")
@export var attack_cooldown_timer_path: NodePath = NodePath("AttackCooldownTimer")

var spell_spawn_point: Marker2D = null
var attack_cooldown_timer: Timer = null

#region Public
func try_primary_attack() -> bool:
	assert(spell_spawn_point != null, "StaffWeapon spell_spawn_point must be initialized")
	assert(attack_cooldown_timer != null, "StaffWeapon attack_cooldown_timer must be initialized")

	if not attack_cooldown_timer.is_stopped():
		return false

	_spawn_spell_actor()
	attack_cooldown_timer.start()
	return true
#endregion

#region Helpers
func _setup_weapon() -> void:
	spell_spawn_point = get_node_or_null(spell_spawn_point_path) as Marker2D
	attack_cooldown_timer = get_node_or_null(attack_cooldown_timer_path) as Timer

	assert(weapon_data.attack_actor_scene != null, "StaffWeapon requires WeaponData.attack_actor_scene")
	assert(spell_spawn_point != null, "StaffWeapon spell_spawn_point_path must point to Marker2D")
	assert(attack_cooldown_timer != null, "StaffWeapon attack_cooldown_timer_path must point to Timer")

	attack_cooldown_timer.wait_time = weapon_instance.get_attack_cooldown()


func _spawn_spell_actor() -> void:
	assert(owner_actor != null, "StaffWeapon owner_actor must be initialized")

	var spell_parent_ := owner_actor.get_parent()
	assert(spell_parent_ != null, "StaffWeapon owner_actor must have a parent to spawn spell actors")

	var spell_actor_ := weapon_data.attack_actor_scene.instantiate() as SpellActor
	assert(spell_actor_ != null, "WeaponData.attack_actor_scene must instantiate SpellActor")

	spell_parent_.add_child(spell_actor_)
	spell_actor_.global_position = spell_spawn_point.global_position
	spell_actor_.setup(owner_actor, weapon_instance, _get_attack_direction())
#endregion
