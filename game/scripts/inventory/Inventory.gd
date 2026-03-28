class_name Inventory
extends Node

const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const InventorySlotResource = preload("res://game/scripts/inventory/InventorySlot.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")

signal slot_changed(slot_index: int)
signal item_added(item_data: ItemDataResource, amount: int)
signal item_removed(item_data: ItemDataResource, amount: int)

@export var max_slots: int = 20

var slots: Array[InventorySlotResource] = []

#region Core Lifecycle
func _ready() -> void:
	_initialize_slots()
#endregion

#region Public
func add_item(item_data_: ItemDataResource, amount_: int) -> int:
	if item_data_ == null or amount_ <= 0:
		return amount_

	if item_data_.item_type == ItemData.ItemType.WEAPON:
		return amount_

	var remaining_amount_ := amount_
	var added_amount_ := 0

	while remaining_amount_ > 0:
		var slot_index_ := _find_slot_for_item(item_data_)
		if slot_index_ == -1:
			break

		var slot_: InventorySlotResource = slots[slot_index_]
		var accepted_amount_: int = slot_.add_item(item_data_, remaining_amount_)
		if accepted_amount_ <= 0:
			break

		remaining_amount_ -= accepted_amount_
		added_amount_ += accepted_amount_
		slot_changed.emit(slot_index_)

	if added_amount_ > 0:
		item_added.emit(item_data_, added_amount_)

	return remaining_amount_


func remove_item(item_data_: ItemDataResource, amount_: int) -> int:
	if item_data_ == null or amount_ <= 0:
		return 0

	var remaining_amount_ := amount_
	var removed_amount_ := 0

	for slot_index_ in range(slots.size()):
		if remaining_amount_ <= 0:
			break

		var slot_: InventorySlotResource = slots[slot_index_]
		if slot_.weapon_instance != null or slot_.item_data == null:
			continue

		if slot_.item_data.item_id != item_data_.item_id:
			continue

		var taken_amount_: int = slot_.remove_item(remaining_amount_)
		if taken_amount_ <= 0:
			continue

		remaining_amount_ -= taken_amount_
		removed_amount_ += taken_amount_
		slot_changed.emit(slot_index_)

	if removed_amount_ > 0:
		item_removed.emit(item_data_, removed_amount_)

	return removed_amount_


func add_weapon(weapon_instance_: WeaponInstanceResource) -> bool:
	if weapon_instance_ == null:
		return false

	if _find_weapon_slot(weapon_instance_) != -1:
		return false

	for slot_index_ in range(slots.size()):
		var slot_: InventorySlotResource = slots[slot_index_]
		if not slot_.is_empty():
			continue

		slot_.clear()
		slot_.weapon_instance = weapon_instance_
		slot_changed.emit(slot_index_)
		return true

	return false


func remove_weapon(weapon_instance_: WeaponInstanceResource) -> bool:
	var slot_index_ := _find_weapon_slot(weapon_instance_)
	if slot_index_ == -1:
		return false

	slots[slot_index_].clear()
	slot_changed.emit(slot_index_)
	return true


func contains_weapon(weapon_instance_: WeaponInstanceResource) -> bool:
	return _find_weapon_slot(weapon_instance_) != -1


func get_item_count(item_data_: ItemDataResource) -> int:
	if item_data_ == null:
		return 0

	var total_amount_ := 0
	for slot_ in slots:
		if slot_.weapon_instance != null or slot_.item_data == null:
			continue

		if slot_.item_data.item_id == item_data_.item_id:
			total_amount_ += slot_.amount

	return total_amount_


func has_items(item_data_: ItemDataResource, amount_: int) -> bool:
	if amount_ <= 0:
		return true
	return get_item_count(item_data_) >= amount_


func can_add_item(item_data_: ItemDataResource, amount_: int) -> bool:
	if item_data_ == null or amount_ <= 0:
		return false

	if item_data_.item_type == ItemData.ItemType.WEAPON:
		return false

	var remaining_amount_: int = amount_
	for slot_ in slots:
		if slot_.weapon_instance != null:
			continue

		if slot_.item_data == null:
			remaining_amount_ -= item_data_.max_stack
		elif slot_.item_data.item_id == item_data_.item_id:
			remaining_amount_ -= maxi(item_data_.max_stack - slot_.amount, 0)

		if remaining_amount_ <= 0:
			return true

	return false


func get_all_weapons() -> Array[WeaponInstanceResource]:
	var weapons_: Array[WeaponInstanceResource] = []

	for slot_ in slots:
		if slot_.weapon_instance != null:
			weapons_.append(slot_.weapon_instance)

	return weapons_


func get_slot(slot_index_: int) -> InventorySlotResource:
	if not _is_valid_slot_index(slot_index_):
		return null
	return slots[slot_index_]


func swap_slots(from_index_: int, to_index_: int) -> bool:
	if from_index_ == to_index_:
		return _is_valid_slot_index(from_index_)

	if not _is_valid_slot_index(from_index_) or not _is_valid_slot_index(to_index_):
		return false

	var from_slot_: InventorySlotResource = slots[from_index_]
	var to_slot_: InventorySlotResource = slots[to_index_]
	slots[from_index_] = to_slot_
	slots[to_index_] = from_slot_
	slot_changed.emit(from_index_)
	slot_changed.emit(to_index_)
	return true


func get_empty_slot_count() -> int:
	var empty_slot_count_ := 0

	for slot_ in slots:
		if slot_.is_empty():
			empty_slot_count_ += 1

	return empty_slot_count_


func get_used_slot_count() -> int:
	return slots.size() - get_empty_slot_count()


func clear() -> void:
	var slot_count_ := slots.size()
	_initialize_slots()

	for slot_index_ in range(slot_count_):
		slot_changed.emit(slot_index_)


func to_save_dict() -> Dictionary:
	var stackables_: Array[Dictionary] = []
	var weapons_: Array[Dictionary] = []

	for slot_ in slots:
		if slot_.weapon_instance != null:
			weapons_.append(slot_.weapon_instance.to_save_dict())
			continue

		if slot_.item_data == null or slot_.amount <= 0:
			continue

		stackables_.append({
			"item_id": String(slot_.item_data.item_id),
			"amount": slot_.amount
		})

	return {
		"stackables": stackables_,
		"weapons": weapons_
	}


func from_save_dict(data_: Dictionary) -> bool:
	clear()

	var save_manager_ = _get_save_manager()
	if save_manager_ == null:
		push_warning("[Inventory] SaveManager is unavailable during load")
		return false

	for stackable_entry_ in data_.get("stackables", []):
		if typeof(stackable_entry_) != TYPE_DICTIONARY:
			continue

		var item_id_ := StringName(String(stackable_entry_.get("item_id", "")))
		var amount_ := int(stackable_entry_.get("amount", 0))
		var item_data_ = save_manager_.resolve_item_data(item_id_) as ItemDataResource
		if item_data_ == null or amount_ <= 0:
			continue

		add_item(item_data_, amount_)

	for weapon_entry_ in data_.get("weapons", []):
		if typeof(weapon_entry_) != TYPE_DICTIONARY:
			continue

		var weapon_id_ := StringName(String(weapon_entry_.get("weapon_id", "")))
		var weapon_data_ = save_manager_.resolve_weapon_data(weapon_id_)
		if weapon_data_ == null:
			continue

		var weapon_instance_ := WeaponInstanceResource.create_from_save_dict(weapon_data_, weapon_entry_)
		add_weapon(weapon_instance_)

	return true


func get_equipped_weapon_uid() -> String:
	var owner_player_ = _get_owner_player()
	if owner_player_ == null:
		return ""

	var equipped_weapon_ = owner_player_.get_equipped_weapon()
	if equipped_weapon_ == null:
		return ""

	return equipped_weapon_.instance_uid


func equip_weapon_by_uid(uid_: String) -> bool:
	if uid_.is_empty():
		return false

	var owner_player_ = _get_owner_player()
	if owner_player_ == null:
		return false

	for slot_ in slots:
		if slot_.weapon_instance == null:
			continue

		if slot_.weapon_instance.instance_uid != uid_:
			continue

		owner_player_.equip_weapon_instance(slot_.weapon_instance)
		return true

	return false


func debug_print_contents() -> void:
	print("[Inventory] Slots: %d / %d used" % [slots.size() - get_empty_slot_count(), slots.size()])

	for slot_index_ in range(slots.size()):
		var slot_: InventorySlotResource = slots[slot_index_]
		if slot_.weapon_instance != null:
			var weapon_name_ := String(slot_.weapon_instance.weapon_id)
			if slot_.weapon_instance.weapon_data != null:
				weapon_name_ = slot_.weapon_instance.weapon_data.display_name
			print("[Inventory][%d] Weapon: %s (%s)" % [slot_index_, weapon_name_, slot_.weapon_instance.instance_uid])
			continue

		if slot_.item_data != null:
			print("[Inventory][%d] Item: %s x%d" % [slot_index_, slot_.item_data.display_name, slot_.amount])
			continue

		print("[Inventory][%d] Empty" % slot_index_)
#endregion

#region Helpers
func _initialize_slots() -> void:
	slots.clear()

	var slot_count_ := maxi(max_slots, 0)
	for _slot_index_ in range(slot_count_):
		slots.append(InventorySlotResource.new())


func _find_slot_for_item(item_data_: ItemDataResource) -> int:
	if item_data_ == null or item_data_.item_type == ItemData.ItemType.WEAPON:
		return -1

	for slot_index_ in range(slots.size()):
		var slot_: InventorySlotResource = slots[slot_index_]
		if slot_.weapon_instance != null or slot_.item_data == null:
			continue

		if slot_.item_data.item_id == item_data_.item_id and slot_.can_accept(item_data_):
			return slot_index_

	for slot_index_ in range(slots.size()):
		if slots[slot_index_].is_empty():
			return slot_index_

	return -1


func _find_weapon_slot(weapon_instance_: WeaponInstanceResource) -> int:
	if weapon_instance_ == null:
		return -1

	for slot_index_ in range(slots.size()):
		var slot_: InventorySlotResource = slots[slot_index_]
		if slot_.weapon_instance == null:
			continue

		if slot_.weapon_instance == weapon_instance_:
			return slot_index_

		if slot_.weapon_instance.instance_uid == weapon_instance_.instance_uid:
			return slot_index_

	return -1


func _is_valid_slot_index(slot_index_: int) -> bool:
	return slot_index_ >= 0 and slot_index_ < slots.size()


func _get_owner_player() -> Node:
	return get_parent()


func _get_save_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("SaveManager")
#endregion
