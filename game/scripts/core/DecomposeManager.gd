extends Node

const DEFAULT_WEAPON_DATA = preload("res://game/data/weapons/wpn_unarmed.tres")
const InventoryResource = preload("res://game/scripts/inventory/Inventory.gd")
const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")

signal weapon_decomposed(weapon_id: StringName, rewards: Dictionary)

const STAR_BASE_GOLD := {
	0: 50,
	1: 100,
	2: 200,
	3: 400,
	4: 800,
	5: 1500
}

const AFFIX_GOLD_BONUS: int = 50

# Staff material mapping is inferred from the current material set so magical weapons
# feed the same upgrade economy as late-game rune and staff investment.
const WEAPON_TYPE_MATERIAL_IDS := {
	&"sword": &"mat_iron_ore",
	&"staff": &"mat_soul_shard",
	&"bow": &"mat_bowstring"
}

#region Public
func get_decompose_reward_preview(weapon_: WeaponInstanceResource) -> Dictionary:
	if weapon_ == null or weapon_.weapon_data == null:
		return {}

	var star_level_: int = clampi(weapon_.star_level, 0, 5)
	var preview_ := {
		"gold": int(STAR_BASE_GOLD.get(star_level_, 50)) + weapon_.affixes.size() * AFFIX_GOLD_BONUS,
		"items": [],
		"chance_items": []
	}

	var weapon_material_ := _get_weapon_material_item(weapon_)
	if star_level_ >= 1 and weapon_material_ != null:
		_append_reward_item(preview_["items"], weapon_material_, star_level_)

	match star_level_:
		2:
			_append_chance_reward_item(preview_["chance_items"], _resolve_item_data(&"mat_soul_shard"), 1, 0.20)
		3:
			_append_reward_item(preview_["items"], _resolve_item_data(&"mat_crystal"), 1)
		4:
			_append_reward_item(preview_["items"], _resolve_item_data(&"mat_crystal"), 2)
			_append_chance_reward_item(preview_["chance_items"], _resolve_item_data(&"mat_essence"), 1, 0.50)
		5:
			_append_reward_item(preview_["items"], _resolve_item_data(&"mat_crystal"), 3)
			_append_reward_item(preview_["items"], _resolve_item_data(&"mat_essence"), 1)
			preview_["chance_items"].append({
				"kind": &"random_rune",
				"label": "隨機符文石",
				"amount": 1,
				"chance": 0.10
			})

	return preview_


func calculate_decompose_rewards(weapon_: WeaponInstanceResource) -> Dictionary:
	var preview_ := get_decompose_reward_preview(weapon_)
	if preview_.is_empty():
		return {}

	var rewards_ := {
		"gold": int(preview_.get("gold", 0)),
		"items": _duplicate_reward_entries(preview_.get("items", []))
	}

	var rng_ := RandomNumberGenerator.new()
	rng_.randomize()

	for chance_entry_ in preview_.get("chance_items", []):
		if typeof(chance_entry_) != TYPE_DICTIONARY:
			continue
		if rng_.randf() > float(chance_entry_.get("chance", 0.0)):
			continue

		var item_data_ := chance_entry_.get("item_data", null) as ItemDataResource
		if item_data_ != null:
			_append_reward_item(rewards_["items"], item_data_, int(chance_entry_.get("amount", 1)))
			continue

		if StringName(chance_entry_.get("kind", &"")) == &"random_rune":
			var rune_data_ = _roll_random_rune()
			if rune_data_ != null:
				_append_reward_item(rewards_["items"], rune_data_, int(chance_entry_.get("amount", 1)))

	return rewards_


func get_decompose_failure_reason(weapon_: WeaponInstanceResource, inventory_: InventoryResource) -> String:
	if weapon_ == null:
		return "目前沒有可分解的武器。"
	if weapon_.weapon_data == null:
		return "武器資料遺失。"
	if weapon_.weapon_id == &"wpn_unarmed" or weapon_.weapon_data.weapon_type == &"unarmed":
		return "空手武器不可分解。"
	if inventory_ == null:
		return "找不到玩家背包。"
	if _get_player_from_inventory(inventory_) == null:
		return "找不到玩家。"

	var preview_ := get_decompose_reward_preview(weapon_)
	if preview_.is_empty():
		return "找不到分解獎勵設定。"

	var reward_items_: Array = []
	reward_items_.append_array(preview_.get("items", []))
	reward_items_.append_array(preview_.get("chance_items", []))

	var freed_slot_count_: int = 1 if inventory_.contains_weapon(weapon_) else 0
	if not _can_fit_reward_items(reward_items_, inventory_, freed_slot_count_):
		return "背包空間不足。"

	return ""


func can_decompose(weapon_: WeaponInstanceResource, inventory_: InventoryResource) -> bool:
	return get_decompose_failure_reason(weapon_, inventory_).is_empty()


func decompose_weapon(weapon_: WeaponInstanceResource, inventory_: InventoryResource) -> Dictionary:
	var failure_reason_: String = get_decompose_failure_reason(weapon_, inventory_)
	if not failure_reason_.is_empty():
		return {
			"success": false,
			"reason": failure_reason_,
			"gold": 0,
			"items": []
		}

	var player_ = _get_player_from_inventory(inventory_)
	var rewards_ := calculate_decompose_rewards(weapon_)
	rewards_["success"] = true
	rewards_["reason"] = ""

	if inventory_.contains_weapon(weapon_):
		var removed_ok_: bool = inventory_.remove_weapon(weapon_)
		assert(removed_ok_, "DecomposeManager validated weapon presence before removing it")

	if player_ != null and player_.get_equipped_weapon() == weapon_:
		player_.equip_weapon_data(DEFAULT_WEAPON_DATA)

	for item_entry_ in rewards_.get("items", []):
		if typeof(item_entry_) != TYPE_DICTIONARY:
			continue
		var item_data_ := item_entry_.get("item_data", null) as ItemDataResource
		var amount_: int = int(item_entry_.get("amount", 0))
		if item_data_ == null or amount_ <= 0:
			continue

		var remaining_amount_: int = inventory_.add_item(item_data_, amount_)
		assert(remaining_amount_ == 0, "DecomposeManager validated reward capacity before adding items")

	if player_ != null:
		player_.add_gold(int(rewards_.get("gold", 0)))

	weapon_decomposed.emit(weapon_.weapon_id, rewards_)
	return rewards_
#endregion

#region Helpers
func _append_reward_item(entries_: Array, item_data_: ItemDataResource, amount_: int) -> void:
	if item_data_ == null or amount_ <= 0:
		return

	for entry_ in entries_:
		if typeof(entry_) != TYPE_DICTIONARY:
			continue
		var entry_item_data_ := entry_.get("item_data", null) as ItemDataResource
		if entry_item_data_ == null or entry_item_data_.item_id != item_data_.item_id:
			continue
		entry_["amount"] = int(entry_.get("amount", 0)) + amount_
		return

	entries_.append({
		"item_data": item_data_,
		"amount": amount_
	})


func _append_chance_reward_item(entries_: Array, item_data_: ItemDataResource, amount_: int, chance_: float) -> void:
	if item_data_ == null or amount_ <= 0 or chance_ <= 0.0:
		return

	entries_.append({
		"item_data": item_data_,
		"amount": amount_,
		"chance": chance_
	})


func _can_fit_reward_items(reward_items_: Array, inventory_: InventoryResource, freed_slot_count_: int) -> bool:
	if inventory_ == null:
		return false

	var capacities_by_item_id_: Dictionary = {}
	for slot_ in inventory_.slots:
		if slot_.weapon_instance != null or slot_.item_data == null:
			continue
		var item_id_: StringName = slot_.item_data.item_id
		var remaining_capacity_: int = maxi(slot_.item_data.max_stack - slot_.amount, 0)
		capacities_by_item_id_[item_id_] = int(capacities_by_item_id_.get(item_id_, 0)) + remaining_capacity_

	var remaining_empty_slots_: int = inventory_.get_empty_slot_count() + maxi(freed_slot_count_, 0)
	for reward_entry_ in reward_items_:
		if typeof(reward_entry_) != TYPE_DICTIONARY:
			continue
		if StringName(reward_entry_.get("kind", &"")) == &"random_rune":
			var max_stack_: int = 99
			var required_amount_: int = int(reward_entry_.get("amount", 0))
			if required_amount_ <= 0:
				continue
			while required_amount_ > 0:
				if remaining_empty_slots_ <= 0:
					return false
				remaining_empty_slots_ -= 1
				required_amount_ -= max_stack_
			continue

		var item_data_ := reward_entry_.get("item_data", null) as ItemDataResource
		var remaining_amount_: int = int(reward_entry_.get("amount", 0))
		if item_data_ == null or remaining_amount_ <= 0:
			continue

		var item_id_ := item_data_.item_id
		var stack_capacity_: int = int(capacities_by_item_id_.get(item_id_, 0))
		if stack_capacity_ > 0:
			var consumed_capacity_: int = mini(stack_capacity_, remaining_amount_)
			stack_capacity_ -= consumed_capacity_
			remaining_amount_ -= consumed_capacity_
			capacities_by_item_id_[item_id_] = stack_capacity_
		if remaining_amount_ <= 0:
			continue

		while remaining_amount_ > 0:
			if remaining_empty_slots_ <= 0:
				return false
			remaining_empty_slots_ -= 1
			remaining_amount_ -= item_data_.max_stack
		capacities_by_item_id_[item_id_] = int(capacities_by_item_id_.get(item_id_, 0)) + maxi(-remaining_amount_, 0)

	return true


func _duplicate_reward_entries(entries_: Array) -> Array[Dictionary]:
	var duplicated_entries_: Array[Dictionary] = []
	for entry_ in entries_:
		if typeof(entry_) != TYPE_DICTIONARY:
			continue
		duplicated_entries_.append(entry_.duplicate(true))
	return duplicated_entries_


func _get_weapon_material_item(weapon_: WeaponInstanceResource) -> ItemDataResource:
	if weapon_ == null or weapon_.weapon_data == null:
		return null

	var material_item_id_: StringName = WEAPON_TYPE_MATERIAL_IDS.get(weapon_.weapon_data.weapon_type, &"mat_iron_ore")
	return _resolve_item_data(material_item_id_)


func _resolve_item_data(item_id_: StringName) -> ItemDataResource:
	var save_manager_ = _get_save_manager()
	if save_manager_ == null:
		return null
	return save_manager_.resolve_item_data(item_id_) as ItemDataResource


func _roll_random_rune():
	var rune_manager_ = _get_rune_manager()
	if rune_manager_ == null or rune_manager_.available_runes.is_empty():
		return null

	var rng_ := RandomNumberGenerator.new()
	rng_.randomize()
	return rune_manager_.available_runes[rng_.randi_range(0, rune_manager_.available_runes.size() - 1)]


func _get_player_from_inventory(inventory_: InventoryResource) -> Node:
	return inventory_.get_parent() if inventory_ != null else null


func _get_save_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("SaveManager")


func _get_rune_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("RuneManager")
#endregion
