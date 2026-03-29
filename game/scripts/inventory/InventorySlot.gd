class_name InventorySlot
extends RefCounted

const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const GearInstanceResource = preload("res://game/scripts/data/GearInstance.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")

var item_data: ItemDataResource = null
var amount: int = 0
var weapon_instance: WeaponInstanceResource = null
var gear_instance: GearInstanceResource = null

#region Public
func is_empty() -> bool:
	return item_data == null and weapon_instance == null and gear_instance == null and amount <= 0


func can_accept(item_data_: ItemDataResource, amount_: int = 1) -> bool:
	if item_data_ == null or amount_ <= 0:
		return false

	if item_data_.item_type == ItemData.ItemType.WEAPON or item_data_.item_type == ItemData.ItemType.EQUIPMENT:
		return false

	if weapon_instance != null or gear_instance != null:
		return false

	if is_empty():
		return true

	if item_data == null:
		return false

	if item_data.get_stack_key() != item_data_.get_stack_key():
		return false

	return amount < _get_stack_limit(item_data_)


func add_item(item_data_: ItemDataResource, amount_: int) -> int:
	if item_data_ == null or amount_ <= 0:
		return 0

	if item_data_.item_type == ItemData.ItemType.WEAPON or item_data_.item_type == ItemData.ItemType.EQUIPMENT:
		return 0

	if not is_empty() and not can_accept(item_data_, amount_):
		return 0

	if is_empty():
		item_data = item_data_
		amount = 0

	var stack_limit_ := _get_stack_limit(item_data_)
	var addable_amount_ := mini(amount_, stack_limit_ - amount)
	if addable_amount_ <= 0:
		return 0

	amount += addable_amount_
	return addable_amount_


func set_weapon_instance(weapon_instance_: WeaponInstanceResource) -> bool:
	if weapon_instance_ == null:
		return false

	clear()
	weapon_instance = weapon_instance_
	return true


func set_gear_instance(gear_instance_: GearInstanceResource) -> bool:
	if gear_instance_ == null:
		return false

	clear()
	gear_instance = gear_instance_
	return true


func get_content_type() -> StringName:
	if weapon_instance != null:
		return &"weapon"
	if gear_instance != null:
		return &"gear"
	if item_data != null and amount > 0:
		return &"item"
	return &"empty"


func remove_item(amount_: int) -> int:
	if item_data == null or amount_ <= 0:
		return 0

	var removed_amount_ := mini(amount_, amount)
	amount -= removed_amount_

	if amount <= 0:
		clear()

	return removed_amount_


func clear() -> void:
	item_data = null
	amount = 0
	weapon_instance = null
	gear_instance = null
#endregion

#region Helpers
func _get_stack_limit(item_data_: ItemDataResource) -> int:
	if item_data_ == null:
		return 1
	return maxi(item_data_.max_stack, 1)
#endregion
