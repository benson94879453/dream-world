class_name WeaponController
extends Node2D

@export var weapon_sprite_path: NodePath = NodePath("WeaponSprite")
@export var use_weapon_sprite_offset_override: bool = false
@export var weapon_sprite_offset_override: Vector2 = Vector2.ZERO

var owner_actor: PlayerController = null
var weapon_instance: WeaponInstance = null
var weapon_data: WeaponData = null
var weapon_sprite: Sprite2D = null

#region Public
func setup(owner_: PlayerController, weapon_instance_: WeaponInstance) -> void:
	assert(owner_actor == null, "WeaponController does not support double setup")
	assert(owner_ != null, "WeaponController requires owner")
	assert(weapon_instance_ != null, "WeaponController requires WeaponInstance")
	assert(weapon_instance_.weapon_data != null, "WeaponController requires WeaponData")

	owner_actor = owner_
	weapon_instance = weapon_instance_
	weapon_data = weapon_instance_.weapon_data
	weapon_sprite = get_node_or_null(weapon_sprite_path) as Sprite2D

	assert(weapon_sprite != null, "WeaponController weapon_sprite_path must point to Sprite2D")

	_apply_common_setup()
	_setup_weapon()


func try_primary_attack() -> bool:
	return false


func on_equipped() -> void:
	pass


func on_unequipped() -> void:
	pass
#endregion

#region Helpers
func _apply_common_setup() -> void:
	weapon_sprite.texture = weapon_data.weapon_sprite_texture
	weapon_sprite.visible = weapon_sprite.texture != null
	weapon_sprite.position = _resolve_weapon_sprite_offset()


func _setup_weapon() -> void:
	pass


func _get_attack_direction() -> Vector2:
	assert(owner_actor != null, "WeaponController owner_actor must be initialized")
	return owner_actor.get_attack_direction()


func _resolve_weapon_sprite_offset() -> Vector2:
	if use_weapon_sprite_offset_override:
		return weapon_sprite_offset_override

	if weapon_data.weapon_sprite_texture == null:
		return Vector2.ZERO

	var texture_size_: Vector2 = weapon_data.weapon_sprite_texture.get_size()
	return Vector2(texture_size_.x * 0.5, texture_size_.y * -0.5)
#endregion
