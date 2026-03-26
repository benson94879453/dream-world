class_name SpellActor
extends Node2D

var owner_actor: Node2D = null
var weapon_instance: WeaponInstance = null
var weapon_data: WeaponData = null
var direction: Vector2 = Vector2.RIGHT

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

	_setup_spell_actor()
#endregion

#region Helpers
func _setup_spell_actor() -> void:
	pass
#endregion
