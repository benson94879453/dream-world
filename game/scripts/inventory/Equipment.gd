class_name Equipment
extends Node

const GearInstanceResource = preload("res://game/scripts/data/GearInstance.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")

enum EquipmentSlot {
	WEAPON_MAIN,
	HELMET,
	CHESTPLATE,
	LEGGINGS,
	BOOTS
}

const SLOT_KEY_BY_ENUM := {
	EquipmentSlot.WEAPON_MAIN: &"weapon_main",
	EquipmentSlot.HELMET: &"helmet",
	EquipmentSlot.CHESTPLATE: &"chestplate",
	EquipmentSlot.LEGGINGS: &"leggings",
	EquipmentSlot.BOOTS: &"boots"
}

signal weapon_changed(old_weapon: WeaponInstanceResource, new_weapon: WeaponInstanceResource)
signal gear_changed(slot: int, old_gear: GearInstanceResource, new_gear: GearInstanceResource)
signal equipment_changed()

var equipped_weapon: WeaponInstanceResource = null
var equipped_helmet: GearInstanceResource = null
var equipped_chestplate: GearInstanceResource = null
var equipped_leggings: GearInstanceResource = null
var equipped_boots: GearInstanceResource = null

#region Public
func equip_weapon(weapon_instance_: WeaponInstanceResource) -> WeaponInstanceResource:
	if weapon_instance_ == null:
		return null

	var old_weapon_ := equipped_weapon
	equipped_weapon = weapon_instance_
	weapon_changed.emit(old_weapon_, equipped_weapon)
	equipment_changed.emit()
	return old_weapon_


func equip_gear(gear_instance_: GearInstanceResource) -> GearInstanceResource:
	if gear_instance_ == null or gear_instance_.gear_data == null:
		return null

	var slot_: int = _get_slot_enum_for_gear(gear_instance_)
	if slot_ == -1:
		return null

	var old_gear_: GearInstanceResource = _get_gear_in_slot(slot_)
	_set_gear_in_slot(slot_, gear_instance_)
	gear_changed.emit(slot_, old_gear_, gear_instance_)
	equipment_changed.emit()
	return old_gear_


func unequip_slot(slot_: EquipmentSlot) -> Variant:
	match slot_:
		EquipmentSlot.WEAPON_MAIN:
			var old_weapon_ := equipped_weapon
			if old_weapon_ == null:
				return null
			equipped_weapon = null
			weapon_changed.emit(old_weapon_, null)
			equipment_changed.emit()
			return old_weapon_
		EquipmentSlot.HELMET, EquipmentSlot.CHESTPLATE, EquipmentSlot.LEGGINGS, EquipmentSlot.BOOTS:
			var old_gear_: GearInstanceResource = _get_gear_in_slot(slot_)
			if old_gear_ == null:
				return null
			_set_gear_in_slot(slot_, null)
			gear_changed.emit(slot_, old_gear_, null)
			equipment_changed.emit()
			return old_gear_
		_:
			return null


func get_equipped_in_slot(slot_: EquipmentSlot) -> Variant:
	match slot_:
		EquipmentSlot.WEAPON_MAIN:
			return equipped_weapon
		EquipmentSlot.HELMET, EquipmentSlot.CHESTPLATE, EquipmentSlot.LEGGINGS, EquipmentSlot.BOOTS:
			return _get_gear_in_slot(slot_)
		_:
			return null


func is_slot_equipped(slot_: EquipmentSlot) -> bool:
	return get_equipped_in_slot(slot_) != null


func get_total_defense() -> float:
	var total_defense_: float = 0.0

	for gear_instance_ in _get_all_equipped_gears():
		if gear_instance_ == null:
			continue
		total_defense_ += gear_instance_.get_total_defense()

	return total_defense_


func get_total_stat_modifiers() -> Dictionary:
	var total_modifiers_: Dictionary = {}

	for gear_instance_ in _get_all_equipped_gears():
		if gear_instance_ == null or gear_instance_.gear_data == null:
			continue

		for modifier_key_ in gear_instance_.gear_data.stat_modifiers:
			var normalized_key_: StringName = StringName(String(modifier_key_))
			var current_value_: float = float(total_modifiers_.get(normalized_key_, 0.0))
			var add_value_: float = float(gear_instance_.gear_data.stat_modifiers.get(modifier_key_, 0.0))
			total_modifiers_[normalized_key_] = current_value_ + add_value_

	return total_modifiers_


func get_stat_modifier(stat_key_: StringName) -> float:
	if stat_key_.is_empty():
		return 0.0
	return float(get_total_stat_modifiers().get(stat_key_, 0.0))


func to_save_dict() -> Dictionary:
	var save_data_: Dictionary = {
		"weapon_main": null,
		"helmet": null,
		"chestplate": null,
		"leggings": null,
		"boots": null
	}

	if equipped_weapon != null:
		save_data_["weapon_main"] = equipped_weapon.to_save_dict()
	if equipped_helmet != null:
		save_data_["helmet"] = equipped_helmet.to_save_dict()
	if equipped_chestplate != null:
		save_data_["chestplate"] = equipped_chestplate.to_save_dict()
	if equipped_leggings != null:
		save_data_["leggings"] = equipped_leggings.to_save_dict()
	if equipped_boots != null:
		save_data_["boots"] = equipped_boots.to_save_dict()

	return save_data_


func from_save_dict(data_: Dictionary) -> bool:
	if typeof(data_) != TYPE_DICTIONARY:
		return false

	clear()

	var save_manager_: Node = _get_save_manager()
	if save_manager_ == null:
		push_warning("[Equipment] SaveManager is unavailable during load")
		return false

	_load_weapon_from_save(save_manager_, data_.get("weapon_main", null))
	_load_gear_from_save(save_manager_, EquipmentSlot.HELMET, data_.get("helmet", null))
	_load_gear_from_save(save_manager_, EquipmentSlot.CHESTPLATE, data_.get("chestplate", null))
	_load_gear_from_save(save_manager_, EquipmentSlot.LEGGINGS, data_.get("leggings", null))
	_load_gear_from_save(save_manager_, EquipmentSlot.BOOTS, data_.get("boots", null))
	return true


func clear() -> void:
	unequip_slot(EquipmentSlot.WEAPON_MAIN)
	unequip_slot(EquipmentSlot.HELMET)
	unequip_slot(EquipmentSlot.CHESTPLATE)
	unequip_slot(EquipmentSlot.LEGGINGS)
	unequip_slot(EquipmentSlot.BOOTS)
#endregion

#region Helpers
func _get_slot_enum_for_gear(gear_instance_: GearInstanceResource) -> int:
	if gear_instance_ == null or gear_instance_.gear_data == null:
		return -1

	match gear_instance_.gear_data.get_equipment_slot_id():
		&"helmet":
			return EquipmentSlot.HELMET
		&"chestplate":
			return EquipmentSlot.CHESTPLATE
		&"leggings":
			return EquipmentSlot.LEGGINGS
		&"boots":
			return EquipmentSlot.BOOTS
		_:
			return -1


func _get_gear_in_slot(slot_: EquipmentSlot) -> GearInstanceResource:
	match slot_:
		EquipmentSlot.HELMET:
			return equipped_helmet
		EquipmentSlot.CHESTPLATE:
			return equipped_chestplate
		EquipmentSlot.LEGGINGS:
			return equipped_leggings
		EquipmentSlot.BOOTS:
			return equipped_boots
		_:
			return null


func _set_gear_in_slot(slot_: EquipmentSlot, gear_instance_: GearInstanceResource) -> void:
	match slot_:
		EquipmentSlot.HELMET:
			equipped_helmet = gear_instance_
		EquipmentSlot.CHESTPLATE:
			equipped_chestplate = gear_instance_
		EquipmentSlot.LEGGINGS:
			equipped_leggings = gear_instance_
		EquipmentSlot.BOOTS:
			equipped_boots = gear_instance_


func _get_all_equipped_gears() -> Array[GearInstanceResource]:
	return [
		equipped_helmet,
		equipped_chestplate,
		equipped_leggings,
		equipped_boots
	]


func _load_weapon_from_save(save_manager_: Node, weapon_data_: Variant) -> void:
	if typeof(weapon_data_) != TYPE_DICTIONARY:
		return

	var weapon_id_: StringName = StringName(String(weapon_data_.get("weapon_id", "")))
	var weapon_resource_ = save_manager_.resolve_weapon_data(weapon_id_)
	if weapon_resource_ == null:
		return

	equip_weapon(WeaponInstanceResource.create_from_save_dict(weapon_resource_, weapon_data_))


func _load_gear_from_save(save_manager_: Node, slot_: EquipmentSlot, gear_data_: Variant) -> void:
	if typeof(gear_data_) != TYPE_DICTIONARY:
		return

	var gear_id_: StringName = StringName(String(gear_data_.get("gear_id", "")))
	var gear_resource_ = save_manager_.resolve_gear_data(gear_id_)
	if gear_resource_ == null:
		return

	var gear_instance_ := GearInstanceResource.create_from_save_dict(gear_resource_, gear_data_)
	var target_slot_: int = _get_slot_enum_for_gear(gear_instance_)
	if target_slot_ != slot_:
		return

	equip_gear(gear_instance_)


func _get_save_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("SaveManager")
#endregion
