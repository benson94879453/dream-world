class_name Inventory
extends Node

const GearDataResource = preload("res://game/scripts/data/GearData.gd")
const GearInstanceResource = preload("res://game/scripts/data/GearInstance.gd")
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

	if item_data_.item_type == ItemData.ItemType.WEAPON or item_data_.item_type == ItemData.ItemType.EQUIPMENT:
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

	if item_data_.item_type == ItemData.ItemType.WEAPON or item_data_.item_type == ItemData.ItemType.EQUIPMENT:
		return 0

	var remaining_amount_ := amount_
	var removed_amount_ := 0
	var target_stack_key_ := _get_stack_key(item_data_)

	for slot_index_ in range(slots.size()):
		if remaining_amount_ <= 0:
			break

		var slot_: InventorySlotResource = slots[slot_index_]
		if slot_.weapon_instance != null or slot_.gear_instance != null or slot_.item_data == null:
			continue

		if _get_stack_key(slot_.item_data) != target_stack_key_:
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

	var slot_index_ := _find_first_empty_slot()
	if slot_index_ == -1:
		return false

	var slot_: InventorySlotResource = slots[slot_index_]
	if not slot_.set_weapon_instance(weapon_instance_):
		return false

	slot_changed.emit(slot_index_)
	return true


func remove_weapon(weapon_instance_: WeaponInstanceResource) -> bool:
	var slot_index_ := _find_weapon_slot(weapon_instance_)
	if slot_index_ == -1:
		return false

	slots[slot_index_].clear()
	slot_changed.emit(slot_index_)
	return true


func contains_weapon(weapon_instance_: WeaponInstanceResource) -> bool:
	return _find_weapon_slot(weapon_instance_) != -1


func add_gear(gear_instance_: GearInstanceResource) -> bool:
	if gear_instance_ == null:
		return false

	if _find_gear_slot(gear_instance_) != -1:
		return false

	var slot_index_ := _find_first_empty_slot()
	if slot_index_ == -1:
		return false

	var slot_: InventorySlotResource = slots[slot_index_]
	if not slot_.set_gear_instance(gear_instance_):
		return false

	slot_changed.emit(slot_index_)
	return true


func remove_gear(gear_instance_: GearInstanceResource) -> bool:
	var slot_index_ := _find_gear_slot(gear_instance_)
	if slot_index_ == -1:
		return false

	slots[slot_index_].clear()
	slot_changed.emit(slot_index_)
	return true


func contains_gear(gear_instance_: GearInstanceResource) -> bool:
	return _find_gear_slot(gear_instance_) != -1


func get_item_count(item_data_: ItemDataResource) -> int:
	if item_data_ == null:
		return 0

	var total_amount_ := 0
	var target_stack_key_ := _get_stack_key(item_data_)
	for slot_ in slots:
		if slot_.weapon_instance != null or slot_.gear_instance != null or slot_.item_data == null:
			continue

		if _get_stack_key(slot_.item_data) == target_stack_key_:
			total_amount_ += slot_.amount

	return total_amount_


func has_items(item_data_: ItemDataResource, amount_: int) -> bool:
	if amount_ <= 0:
		return true
	return get_item_count(item_data_) >= amount_


func can_add_item(item_data_: ItemDataResource, amount_: int) -> bool:
	if item_data_ == null or amount_ <= 0:
		return false

	if item_data_.item_type == ItemData.ItemType.WEAPON or item_data_.item_type == ItemData.ItemType.EQUIPMENT:
		return false

	var remaining_amount_: int = amount_
	var target_stack_key_ := _get_stack_key(item_data_)
	for slot_ in slots:
		if slot_.weapon_instance != null or slot_.gear_instance != null:
			continue

		if slot_.item_data == null:
			remaining_amount_ -= maxi(item_data_.max_stack, 1)
		elif _get_stack_key(slot_.item_data) == target_stack_key_:
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


func get_all_gears() -> Array[GearInstanceResource]:
	var gears_: Array[GearInstanceResource] = []

	for slot_ in slots:
		if slot_.gear_instance != null:
			gears_.append(slot_.gear_instance)

	return gears_


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


func quick_move_slot_to_inventory(from_slot_index_: int, target_inventory_: Inventory = null) -> bool:
	if not _is_valid_slot_index(from_slot_index_):
		return false

	if target_inventory_ == null:
		return split_stack(from_slot_index_) != -1

	if target_inventory_ == self:
		return false

	var slot_: InventorySlotResource = slots[from_slot_index_]
	match slot_.get_content_type():
		&"item":
			if slot_.item_data == null or slot_.amount <= 0:
				return false

			var moved_item_data_: ItemDataResource = slot_.item_data
			var original_amount_: int = slot_.amount
			var remaining_amount_: int = target_inventory_.add_item(moved_item_data_, original_amount_)
			var moved_amount_: int = original_amount_ - remaining_amount_
			if moved_amount_ <= 0:
				return false

			slot_.remove_item(moved_amount_)
			slot_changed.emit(from_slot_index_)
			item_removed.emit(moved_item_data_, moved_amount_)
			return true
		&"weapon":
			var weapon_instance_ := slot_.weapon_instance
			if weapon_instance_ == null or not target_inventory_.add_weapon(weapon_instance_):
				return false
			return remove_weapon(weapon_instance_)
		&"gear":
			var gear_instance_ := slot_.gear_instance
			if gear_instance_ == null or not target_inventory_.add_gear(gear_instance_):
				return false
			return remove_gear(gear_instance_)
		_:
			return false


func split_stack(slot_index_: int) -> int:
	if not _is_valid_slot_index(slot_index_):
		return -1

	var source_slot_: InventorySlotResource = slots[slot_index_]
	if source_slot_.weapon_instance != null or source_slot_.gear_instance != null:
		return -1
	if source_slot_.item_data == null or source_slot_.amount <= 1:
		return -1

	var empty_slot_index_ := _find_first_empty_slot(slot_index_)
	if empty_slot_index_ == -1:
		return -1

	var item_data_: ItemDataResource = source_slot_.item_data
	var original_amount_: int = source_slot_.amount
	var kept_amount_: int = int(floor(float(original_amount_) / 2.0))
	var moved_amount_: int = original_amount_ - kept_amount_
	if kept_amount_ <= 0 or moved_amount_ <= 0:
		return -1

	source_slot_.amount = kept_amount_

	var target_slot_: InventorySlotResource = slots[empty_slot_index_]
	var accepted_amount_: int = target_slot_.add_item(item_data_, moved_amount_)
	if accepted_amount_ != moved_amount_:
		source_slot_.amount = original_amount_
		target_slot_.clear()
		return -1

	slot_changed.emit(slot_index_)
	slot_changed.emit(empty_slot_index_)
	return empty_slot_index_


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
	var slot_entries_: Array[Dictionary] = []

	for slot_ in slots:
		match slot_.get_content_type():
			&"item":
				slot_entries_.append({
					"type": "item",
					"item_id": String(slot_.item_data.item_id),
					"amount": slot_.amount,
					"stack_key": String(_get_stack_key(slot_.item_data))
				})
			&"weapon":
				slot_entries_.append({
					"type": "weapon",
					"weapon_data": slot_.weapon_instance.to_save_dict()
				})
			&"gear":
				slot_entries_.append({
					"type": "gear",
					"gear_data": slot_.gear_instance.to_save_dict()
				})
			_:
				slot_entries_.append({
					"type": "empty"
				})

	return {
		"version": 2,
		"slots": slot_entries_
	}


func from_save_dict(data_: Dictionary) -> bool:
	if typeof(data_) != TYPE_DICTIONARY:
		return false

	var version_ := int(data_.get("version", 1))
	if version_ >= 2:
		return _load_v2(data_)
	return _load_v1(data_)


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
		match slot_.get_content_type():
			&"weapon":
				var weapon_name_ := String(slot_.weapon_instance.weapon_id)
				if slot_.weapon_instance.weapon_data != null:
					weapon_name_ = slot_.weapon_instance.weapon_data.display_name
				print("[Inventory][%d] Weapon: %s (%s)" % [slot_index_, weapon_name_, slot_.weapon_instance.instance_uid])
			&"gear":
				var gear_name_ := String(slot_.gear_instance.gear_id)
				if slot_.gear_instance.gear_data != null:
					gear_name_ = slot_.gear_instance.gear_data.display_name
				print("[Inventory][%d] Gear: %s (%s)" % [slot_index_, gear_name_, slot_.gear_instance.instance_uid])
			&"item":
				print("[Inventory][%d] Item: %s x%d" % [slot_index_, slot_.item_data.display_name, slot_.amount])
			_:
				print("[Inventory][%d] Empty" % slot_index_)
#endregion

#region Helpers
func _initialize_slots() -> void:
	slots.clear()

	var slot_count_ := maxi(max_slots, 0)
	for _slot_index_ in range(slot_count_):
		slots.append(InventorySlotResource.new())


func _load_v1(data_: Dictionary) -> bool:
	clear()

	var save_manager_ = _get_save_manager()
	if save_manager_ == null:
		push_warning("[Inventory] SaveManager is unavailable during v1 load")
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


func _load_v2(data_: Dictionary) -> bool:
	clear()

	var save_manager_ = _get_save_manager()
	if save_manager_ == null:
		push_warning("[Inventory] SaveManager is unavailable during v2 load")
		return false

	var slot_entries_ = data_.get("slots", [])
	if typeof(slot_entries_) != TYPE_ARRAY:
		push_warning("[Inventory] Invalid v2 slots payload")
		return false

	for slot_index_ in range(mini(slot_entries_.size(), slots.size())):
		var slot_entry_ = slot_entries_[slot_index_]
		if typeof(slot_entry_) != TYPE_DICTIONARY:
			continue

		var slot_: InventorySlotResource = slots[slot_index_]
		var content_type_ := StringName(String(slot_entry_.get("type", "empty")))

		match content_type_:
			&"item":
				var item_id_ := StringName(String(slot_entry_.get("item_id", "")))
				var amount_ := int(slot_entry_.get("amount", 0))
				var item_data_ = save_manager_.resolve_item_data(item_id_) as ItemDataResource
				if item_data_ == null or amount_ <= 0:
					continue
				if slot_.add_item(item_data_, amount_) > 0:
					slot_changed.emit(slot_index_)
			&"weapon":
				var weapon_entry_ = slot_entry_.get("weapon_data", slot_entry_.get("weapon", {}))
				if typeof(weapon_entry_) != TYPE_DICTIONARY:
					continue

				var weapon_id_ := StringName(String(weapon_entry_.get("weapon_id", "")))
				var weapon_data_ = save_manager_.resolve_weapon_data(weapon_id_)
				if weapon_data_ == null:
					continue

				var weapon_instance_ := WeaponInstanceResource.create_from_save_dict(weapon_data_, weapon_entry_)
				if slot_.set_weapon_instance(weapon_instance_):
					slot_changed.emit(slot_index_)
			&"gear":
				var gear_entry_ = slot_entry_.get("gear_data", slot_entry_.get("gear", {}))
				if typeof(gear_entry_) != TYPE_DICTIONARY:
					continue

				var gear_id_ := StringName(String(gear_entry_.get("gear_id", "")))
				var gear_data_ := _resolve_gear_data(gear_id_)
				if gear_data_ == null:
					continue

				var gear_instance_ := GearInstanceResource.create_from_save_dict(gear_data_, gear_entry_)
				if slot_.set_gear_instance(gear_instance_):
					slot_changed.emit(slot_index_)
			_:
				continue

	return true


func _find_slot_for_item(item_data_: ItemDataResource) -> int:
	if item_data_ == null:
		return -1

	if item_data_.item_type == ItemData.ItemType.WEAPON or item_data_.item_type == ItemData.ItemType.EQUIPMENT:
		return -1

	var target_stack_key_ := _get_stack_key(item_data_)
	for slot_index_ in range(slots.size()):
		var slot_: InventorySlotResource = slots[slot_index_]
		if slot_.weapon_instance != null or slot_.gear_instance != null or slot_.item_data == null:
			continue

		if _get_stack_key(slot_.item_data) == target_stack_key_ and slot_.can_accept(item_data_):
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


func _find_gear_slot(gear_instance_: GearInstanceResource) -> int:
	if gear_instance_ == null:
		return -1

	for slot_index_ in range(slots.size()):
		var slot_: InventorySlotResource = slots[slot_index_]
		if slot_.gear_instance == null:
			continue

		if slot_.gear_instance == gear_instance_:
			return slot_index_

		if slot_.gear_instance.instance_uid == gear_instance_.instance_uid:
			return slot_index_

	return -1


func _find_first_empty_slot(exclude_slot_index_: int = -1) -> int:
	for slot_index_ in range(slots.size()):
		if slot_index_ == exclude_slot_index_:
			continue
		if slots[slot_index_].is_empty():
			return slot_index_
	return -1


func _get_stack_key(item_data_: ItemDataResource) -> StringName:
	if item_data_ == null:
		return &""
	return item_data_.get_stack_key()


func _resolve_gear_data(gear_id_: StringName) -> GearDataResource:
	if gear_id_.is_empty():
		return null

	var save_manager_ = _get_save_manager()
	if save_manager_ == null:
		return null

	if save_manager_.has_method("resolve_gear_data"):
		return save_manager_.resolve_gear_data(gear_id_) as GearDataResource

	return save_manager_.resolve_item_data(gear_id_) as GearDataResource


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
