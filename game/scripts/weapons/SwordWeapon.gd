class_name SwordWeapon
extends WeaponController

@export var attack_hitbox_path: NodePath = NodePath("AttackHitbox")
@export var attack_hitbox_collision_path: NodePath = NodePath("AttackHitbox/AttackHitboxCollision")
@export var attack_cooldown_timer_path: NodePath = NodePath("AttackCooldownTimer")

var attack_hitbox: Hitbox = null
var attack_hitbox_collision: CollisionShape2D = null
var attack_cooldown_timer: Timer = null

#region Public
func try_primary_attack() -> bool:
	assert(attack_hitbox != null, "SwordWeapon attack_hitbox must be initialized")
	assert(attack_cooldown_timer != null, "SwordWeapon attack_cooldown_timer must be initialized")

	if not attack_cooldown_timer.is_stopped():
		return false

	attack_hitbox.activate()
	attack_cooldown_timer.start()
	return true
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

	attack_hitbox.source_root = owner_actor
	attack_hitbox.base_damage = weapon_instance.get_base_attack()
	attack_hitbox.attack_tags = [&"melee", weapon_data.weapon_type]

	attack_cooldown_timer.wait_time = weapon_instance.get_attack_cooldown()
	hitbox_shape_.size.x = 18.0 * maxf(weapon_instance.get_attack_range(), 0.25)
	attack_hitbox_collision.position.x = hitbox_shape_.size.x * 0.5
#endregion
