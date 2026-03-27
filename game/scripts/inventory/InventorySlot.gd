class_name InventorySlot
extends RefCounted

const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")

var item_data: ItemDataResource = null
var amount: int = 0
var weapon_instance: WeaponInstanceResource = null

#region Public
func is_empty() -> bool:
	return item_data == null and weapon_instance == null and amount <= 0


func can_accept(item_data_: ItemDataResource, amount_: int = 1) -> bool:
	if item_data_ == null or amount_ <= 0:
		return false

	if item_data_.item_type == ItemData.ItemType.WEAPON:
		return false

	if weapon_instance != null:
		return false

	if is_empty():
		return true

	if item_data == null or item_data.item_id != item_data_.item_id:
		return false

	return amount < _get_stack_limit(item_data_)


func add_item(item_data_: ItemDataResource, amount_: int) -> int:
	if item_data_ == null or amount_ <= 0:
		return 0

	if item_data_.item_type == ItemData.ItemType.WEAPON:
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
#endregion

#region Helpers
func _get_stack_limit(item_data_: ItemDataResource) -> int:
	if item_data_ == null:
		return 1
	return maxi(item_data_.max_stack, 1)
#endregion
