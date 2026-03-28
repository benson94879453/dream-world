class_name HotbarManager
extends Node

const InventoryResource = preload("res://game/scripts/inventory/Inventory.gd")
const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")

signal binding_changed(hotbar_index: int, inventory_index: int)
signal hotbar_used(hotbar_index: int, result: StringName)

const HOTBAR_SIZE: int = 5
const DEFAULT_HEAL_AMOUNT: float = 25.0

var hotbar_inventory_indices: Array[int] = [-1, -1, -1, -1, -1]

#region Public
func bind_slot(hotbar_index_: int, inventory_index_: int) -> bool:
	if not _is_valid_hotbar_index(hotbar_index_):
		return false
	if inventory_index_ < -1:
		return false

	hotbar_inventory_indices[hotbar_index_] = inventory_index_
	binding_changed.emit(hotbar_index_, inventory_index_)
	return true


func clear_slot(hotbar_index_: int) -> bool:
	return bind_slot(hotbar_index_, -1)


func swap_slots(from_index_: int, to_index_: int) -> bool:
	if not _is_valid_hotbar_index(from_index_) or not _is_valid_hotbar_index(to_index_):
		return false
	if from_index_ == to_index_:
		return true

	var from_inventory_index_: int = hotbar_inventory_indices[from_index_]
	hotbar_inventory_indices[from_index_] = hotbar_inventory_indices[to_index_]
	hotbar_inventory_indices[to_index_] = from_inventory_index_
	binding_changed.emit(from_index_, hotbar_inventory_indices[from_index_])
	binding_changed.emit(to_index_, hotbar_inventory_indices[to_index_])
	return true


func get_bound_inventory_index(hotbar_index_: int) -> int:
	if not _is_valid_hotbar_index(hotbar_index_):
		return -1
	return hotbar_inventory_indices[hotbar_index_]


func get_bound_slot(inventory_: InventoryResource, hotbar_index_: int):
	if inventory_ == null:
		return null

	var inventory_index_: int = get_bound_inventory_index(hotbar_index_)
	if inventory_index_ < 0:
		return null

	return inventory_.get_slot(inventory_index_)


func get_slot_display_name(inventory_: InventoryResource, hotbar_index_: int) -> String:
	var slot_ = get_bound_slot(inventory_, hotbar_index_)
	if slot_ == null or slot_.is_empty():
		return "Empty"
	if slot_.weapon_instance != null and slot_.weapon_instance.weapon_data != null:
		return slot_.weapon_instance.weapon_data.display_name
	if slot_.item_data != null:
		return slot_.item_data.display_name
	return "Empty"


func use_hotbar_slot(player_: PlayerController, hotbar_index_: int) -> bool:
	if player_ == null or not _is_valid_hotbar_index(hotbar_index_):
		return false

	var inventory_ := player_.get_inventory()
	if inventory_ == null:
		return false

	var inventory_index_: int = get_bound_inventory_index(hotbar_index_)
	if inventory_index_ < 0:
		return false

	var slot_ = inventory_.get_slot(inventory_index_)
	if slot_ == null or slot_.is_empty():
		return false

	if slot_.weapon_instance != null:
		player_.equip_weapon_instance(slot_.weapon_instance)
		hotbar_used.emit(hotbar_index_, &"weapon")
		print("[Hotbar] Equipped weapon from slot %d: %s" % [inventory_index_, get_slot_display_name(inventory_, hotbar_index_)])
		return true

	var item_data_: ItemDataResource = slot_.item_data
	if item_data_ == null:
		return false

	if item_data_.item_type != ItemData.ItemType.CONSUMABLE and not item_data_.is_consumable:
		return false

	var removed_amount_: int = inventory_.remove_item(item_data_, 1)
	if removed_amount_ <= 0:
		return false

	var healed_amount_: float = 0.0
	var health_component_: HealthComponent = player_.get_health_component()
	if health_component_ != null:
		healed_amount_ = health_component_.heal(DEFAULT_HEAL_AMOUNT)

	hotbar_used.emit(hotbar_index_, &"consumable")
	print("[Hotbar] Consumed %s from slot %d (heal=%.1f)" % [item_data_.display_name, inventory_index_, healed_amount_])
	return true
#endregion

#region Helpers
func _is_valid_hotbar_index(hotbar_index_: int) -> bool:
	return hotbar_index_ >= 0 and hotbar_index_ < HOTBAR_SIZE
#endregion
