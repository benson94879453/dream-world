extends Node

const InventoryResource = preload("res://game/scripts/inventory/Inventory.gd")
const RuneDataResource = preload("res://game/scripts/data/RuneData.gd")
const RuneInstanceResource = preload("res://game/scripts/data/RuneInstance.gd")
const RuneSlotResource = preload("res://game/scripts/data/RuneSlot.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")

const RUNE_DATA_ROOT: String = "res://game/data/runes"
const UNEQUIP_COST_BASE: int = 100

signal rune_equipped(weapon: WeaponInstanceResource, slot_index: int, rune: RuneInstanceResource)
signal rune_unequipped(weapon: WeaponInstanceResource, slot_index: int, rune: RuneInstanceResource)

var available_runes: Array[RuneDataResource] = []
var rune_data_by_id: Dictionary = {}

#region Core Lifecycle
func _ready() -> void:
	_refresh_rune_cache()
#endregion

#region Public
func get_rune_data(rune_id_: StringName) -> RuneDataResource:
	if rune_data_by_id.is_empty():
		_refresh_rune_cache()
	return rune_data_by_id.get(rune_id_, null)


func get_available_runes_from_inventory(inventory_: InventoryResource) -> Array[Dictionary]:
	if inventory_ == null:
		return []

	var grouped_entries_: Dictionary = {}
	for slot_ in inventory_.slots:
		if slot_ == null or slot_.amount <= 0:
			continue
		if slot_.weapon_instance != null or slot_.gear_instance != null:
			continue

		var rune_data_: RuneDataResource = _resolve_rune_data_from_slot(slot_)
		if rune_data_ == null:
			continue

		var rune_id_ := rune_data_.get_runtime_rune_id()
		if not grouped_entries_.has(rune_id_):
			grouped_entries_[rune_id_] = {
				"rune_data": rune_data_,
				"amount": 0
			}

		grouped_entries_[rune_id_]["amount"] += slot_.amount

	var entries_: Array[Dictionary] = []
	for rune_id_ in grouped_entries_:
		entries_.append(grouped_entries_[rune_id_])

	entries_.sort_custom(func(left_: Dictionary, right_: Dictionary) -> bool:
		var left_rune_: RuneDataResource = left_.get("rune_data", null) as RuneDataResource
		var right_rune_: RuneDataResource = right_.get("rune_data", null) as RuneDataResource
		if left_rune_ == null or right_rune_ == null:
			return false
		return left_rune_.display_name < right_rune_.display_name
	)
	return entries_


func get_equip_failure_reason(weapon_: WeaponInstanceResource, inventory_: InventoryResource, slot_index_: int, rune_data_: RuneDataResource) -> String:
	if weapon_ == null:
		return "目前沒有可鑲嵌的武器。"
	if inventory_ == null:
		return "找不到玩家背包。"
	if rune_data_ == null:
		return "請先選擇符文。"
	if slot_index_ < 0 or slot_index_ >= weapon_.rune_slots.size():
		return "請先選擇已解鎖的符文槽。"
	if inventory_.get_item_count(rune_data_) <= 0:
		return "背包中沒有該符文。"

	var slot_ := weapon_.rune_slots[slot_index_]
	if slot_ == null:
		return "符文槽尚未初始化。"
	if not slot_.is_empty():
		return "請先拆下目前已鑲嵌的符文。"
	if not slot_.can_equip(rune_data_):
		return "該符文不符合此槽位限制。"

	return ""


func equip_rune(weapon_: WeaponInstanceResource, inventory_: InventoryResource, slot_index_: int, rune_data_: RuneDataResource) -> bool:
	var failure_reason_: String = get_equip_failure_reason(weapon_, inventory_, slot_index_, rune_data_)
	if not failure_reason_.is_empty():
		return false

	var removed_amount_: int = inventory_.remove_item(rune_data_, 1)
	assert(removed_amount_ == 1, "RuneManager equip_rune must consume exactly one rune item")

	var slot_ := weapon_.rune_slots[slot_index_]
	var rune_instance_: RuneInstanceResource = RuneInstanceResource.create_from_data(rune_data_)
	var equipped_ok_: bool = slot_.equip(rune_instance_)
	assert(equipped_ok_, "RuneManager validated slot before equip")
	rune_equipped.emit(weapon_, slot_index_, rune_instance_)
	return true


func get_unequip_failure_reason(weapon_: WeaponInstanceResource, inventory_: InventoryResource, slot_index_: int) -> String:
	if weapon_ == null:
		return "目前沒有可拆卸的武器。"
	if inventory_ == null:
		return "找不到玩家背包。"
	if slot_index_ < 0 or slot_index_ >= weapon_.rune_slots.size():
		return "請先選擇已解鎖的符文槽。"

	var slot_ := weapon_.rune_slots[slot_index_]
	if slot_ == null or slot_.is_empty():
		return "此槽位沒有已鑲嵌的符文。"

	var rune_data_: RuneDataResource = slot_.equipped_rune.rune_data
	if rune_data_ == null:
		return "符文資料遺失。"
	if not inventory_.can_add_item(rune_data_, 1):
		return "背包空間不足。"

	return ""


func unequip_rune(weapon_: WeaponInstanceResource, inventory_: InventoryResource, slot_index_: int) -> RuneInstanceResource:
	var failure_reason_: String = get_unequip_failure_reason(weapon_, inventory_, slot_index_)
	if not failure_reason_.is_empty():
		return null

	var slot_ := weapon_.rune_slots[slot_index_]
	var rune_instance_ := slot_.unequip()
	assert(rune_instance_ != null, "RuneManager validated slot before unequip")
	var remaining_amount_: int = inventory_.add_item(rune_instance_.rune_data, 1)
	assert(remaining_amount_ == 0, "RuneManager validated inventory space before unequip")

	rune_unequipped.emit(weapon_, slot_index_, rune_instance_)
	return rune_instance_


func get_unequip_failure_reason_with_gold(weapon_: WeaponInstanceResource, inventory_: InventoryResource, slot_index_: int, player_) -> String:
	var failure_reason_: String = get_unequip_failure_reason(weapon_, inventory_, slot_index_)
	if not failure_reason_.is_empty():
		return failure_reason_
	if player_ == null:
		return "找不到玩家。"

	var gold_cost_: int = get_unequip_cost(slot_index_)
	if not player_.can_spend_gold(gold_cost_):
		return "金幣不足，需要 %d 金幣。" % gold_cost_

	return ""


func unequip_rune_with_cost(weapon_: WeaponInstanceResource, inventory_: InventoryResource, slot_index_: int, player_) -> Dictionary:
	var gold_cost_: int = get_unequip_cost(slot_index_)
	var failure_reason_: String = get_unequip_failure_reason_with_gold(weapon_, inventory_, slot_index_, player_)
	if not failure_reason_.is_empty():
		return {
			"success": false,
			"reason": failure_reason_,
			"gold_cost": gold_cost_,
			"rune_instance": null
		}

	var spent_ok_: bool = player_.spend_gold(gold_cost_)
	if not spent_ok_:
		return {
			"success": false,
			"reason": "金幣不足，需要 %d 金幣。" % gold_cost_,
			"gold_cost": gold_cost_,
			"rune_instance": null
		}

	var rune_instance_: RuneInstanceResource = unequip_rune(weapon_, inventory_, slot_index_)
	if rune_instance_ == null:
		player_.add_gold(gold_cost_)
		return {
			"success": false,
			"reason": "拆卸失敗，金幣已退還。",
			"gold_cost": gold_cost_,
			"rune_instance": null
		}

	return {
		"success": true,
		"reason": "",
		"gold_cost": gold_cost_,
		"rune_instance": rune_instance_
	}


func get_unequip_cost(slot_index_: int) -> int:
	return UNEQUIP_COST_BASE * (slot_index_ + 1)
#endregion

#region Helpers
func _refresh_rune_cache() -> void:
	available_runes.clear()
	rune_data_by_id.clear()

	for rune_path_ in _collect_resource_paths(RUNE_DATA_ROOT):
		var rune_data_: RuneDataResource = load(rune_path_) as RuneDataResource
		if rune_data_ == null:
			continue

		var rune_id_ := rune_data_.get_runtime_rune_id()
		if rune_id_.is_empty():
			push_warning("[RuneManager] RuneData missing rune_id: %s" % rune_path_)
			continue

		available_runes.append(rune_data_)
		rune_data_by_id[rune_id_] = rune_data_

	available_runes.sort_custom(func(left_: RuneDataResource, right_: RuneDataResource) -> bool:
		return left_.display_name < right_.display_name
	)


func _resolve_rune_data_from_slot(slot_) -> RuneDataResource:
	if slot_ == null or slot_.item_data == null:
		return null

	var rune_data_: RuneDataResource = slot_.item_data as RuneDataResource
	if rune_data_ != null:
		return rune_data_

	var item_id_: StringName = StringName(slot_.item_data.item_id)
	if item_id_.is_empty() or not String(item_id_).begins_with("rune_"):
		return null

	return get_rune_data(item_id_)


func _collect_resource_paths(root_path_: String) -> PackedStringArray:
	var resource_paths_: PackedStringArray = []
	var directory_ := DirAccess.open(root_path_)
	if directory_ == null:
		return resource_paths_

	directory_.list_dir_begin()
	while true:
		var entry_name_ := directory_.get_next()
		if entry_name_.is_empty():
			break
		if entry_name_.begins_with("."):
			continue

		var entry_path_ := "%s/%s" % [root_path_, entry_name_]
		if directory_.current_is_dir():
			resource_paths_.append_array(_collect_resource_paths(entry_path_))
			continue

		if entry_name_.ends_with(".tres"):
			resource_paths_.append(entry_path_)

	return resource_paths_
#endregion
