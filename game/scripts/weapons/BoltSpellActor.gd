class_name BoltSpellActor
extends SpellActor

@export var speed: float = 240.0
@export var seconds_per_range_unit: float = 0.2
@export var hitbox_path: NodePath = NodePath("Hitbox")

var lifetime_remaining: float = 0.0
var hitbox: Hitbox = null

#region Core Lifecycle
func _ready() -> void:
	hitbox = get_node_or_null(hitbox_path) as Hitbox
	assert(hitbox != null, "BoltSpellActor hitbox_path must point to Hitbox")


func _physics_process(delta_: float) -> void:
	if lifetime_remaining <= 0.0:
		return

	global_position += direction * speed * delta_
	lifetime_remaining = maxf(lifetime_remaining - delta_, 0.0)
	if lifetime_remaining > 0.0:
		return

	queue_free()
#endregion

#region Helpers
func _setup_spell_actor() -> void:
	if hitbox == null:
		hitbox = get_node_or_null(hitbox_path) as Hitbox
	assert(hitbox != null, "BoltSpellActor hitbox_path must point to Hitbox")

	lifetime_remaining = maxf(weapon_instance.get_attack_range(), 0.25) * seconds_per_range_unit
	hitbox.source_root = owner_actor
	hitbox.base_damage = weapon_instance.get_base_attack()
	hitbox.attack_tags = [&"spell", &"projectile", weapon_data.weapon_type]
	hitbox.active_duration = lifetime_remaining
	hitbox.activate()
#endregion
