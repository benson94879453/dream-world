extends Node

const AffixInstanceResource = preload("res://game/scripts/data/AffixInstance.gd")
const AffixTableResource = preload("res://game/scripts/data/AffixTable.gd")
const InventoryResource = preload("res://game/scripts/inventory/Inventory.gd")
const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const UpgradeCostTableResource = preload("res://game/scripts/data/UpgradeCostTable.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")

const AFFIX_TABLE_PATH: String = "res://game/data/affixes/affix_table_basic.tres"
const UPGRADE_COSTS_PATH: String = "res://game/data/upgrades/upgrade_costs.tres"

signal upgrade_succeeded(weapon: WeaponInstanceResource, new_affix: AffixInstanceResource)
signal upgrade_failed(weapon: WeaponInstanceResource, reason: String)

var affix_table: AffixTableResource = null
var upgrade_cost_table: UpgradeCostTableResource = null

#region Core Lifecycle
func _ready() -> void:
	_refresh_tables()
#endregion

#region Public
func can_upgrade_weapon(weapon_: WeaponInstanceResource, inventory_: InventoryResource) -> bool:
	return get_upgrade_failure_reason(weapon_, inventory_).is_empty()


func get_upgrade_failure_reason(weapon_: WeaponInstanceResource, inventory_: InventoryResource) -> String:
	if weapon_ == null:
		return "目前沒有可升級的武器。"
	if weapon_.weapon_data == null:
		return "武器資料遺失。"

	if inventory_ == null:
		return "找不到玩家背包。"

	if not weapon_.can_upgrade():
		return "武器已達最高星級。"

	var save_manager_ = _get_save_manager()
	if save_manager_ == null:
		return "SaveManager 尚未就緒。"
	if affix_table == null:
		_refresh_tables()
	if affix_table == null:
		return "找不到詞綴設定。"

	var upgrade_costs_ := get_upgrade_costs(weapon_)
	if upgrade_costs_.is_empty():
		return "找不到升級材料設定。"

	for cost_entry_ in upgrade_costs_:
		var item_id_ := StringName(String(cost_entry_.get("item_id", "")))
		var amount_ := int(cost_entry_.get("amount", 0))
		var item_data_ := save_manager_.resolve_item_data(item_id_) as ItemDataResource
		if item_data_ == null:
			return "缺少材料資料：%s" % String(item_id_)
		if inventory_.get_item_count(item_data_) < amount_:
			return "材料不足。"

	return ""


func upgrade_weapon(weapon_: WeaponInstanceResource, inventory_: InventoryResource) -> bool:
	var failure_reason_ := get_upgrade_failure_reason(weapon_, inventory_)
	if not failure_reason_.is_empty():
		upgrade_failed.emit(weapon_, failure_reason_)
		return false

	var save_manager_ = _get_save_manager()
	assert(save_manager_ != null, "UpgradeManager requires SaveManager")

	for cost_entry_ in get_upgrade_costs(weapon_):
		var item_id_ := StringName(String(cost_entry_.get("item_id", "")))
		var amount_ := int(cost_entry_.get("amount", 0))
		var item_data_ := save_manager_.resolve_item_data(item_id_) as ItemDataResource
		assert(item_data_ != null, "UpgradeManager cost item data must resolve")

		var removed_amount_ := inventory_.remove_item(item_data_, amount_)
		assert(removed_amount_ == amount_, "UpgradeManager must remove the full upgrade cost")

	weapon_.star_level += 1

	var affix_data_ = affix_table.roll_affix(weapon_.weapon_data.weapon_type, weapon_.get_affix_ids()) if affix_table != null else null
	var affix_instance_: AffixInstanceResource = null
	if affix_data_ != null:
		affix_instance_ = AffixInstanceResource.create_from_data(affix_data_)
		weapon_.affixes.append(affix_instance_)

	upgrade_succeeded.emit(weapon_, affix_instance_)
	return true


func get_upgrade_preview(weapon_: WeaponInstanceResource) -> Dictionary:
	if weapon_ == null or weapon_.weapon_data == null:
		return {}

	var next_star_level_ := mini(weapon_.star_level + 1, 5)
	return {
		"weapon_name": weapon_.weapon_data.display_name,
		"current_star_level": weapon_.star_level,
		"next_star_level": next_star_level_,
		"current_attack": weapon_.get_base_attack(),
		"next_attack": _calculate_attack_with_star_level(weapon_, next_star_level_),
		"current_attack_bonus_pct": weapon_.get_total_attack_bonus(),
		"next_attack_bonus_pct": _calculate_attack_bonus_with_star_level(weapon_, next_star_level_),
		"current_rune_slots": weapon_.get_max_rune_slots(),
		"next_rune_slots": next_star_level_,
		"costs": get_upgrade_costs(weapon_)
	}


func get_upgrade_costs(weapon_: WeaponInstanceResource) -> Array[Dictionary]:
	if weapon_ == null:
		return []

	if upgrade_cost_table == null:
		_refresh_tables()

	if upgrade_cost_table == null:
		return []

	return upgrade_cost_table.get_costs_for_star_level(weapon_.star_level + 1)
#endregion

#region Helpers
func _refresh_tables() -> void:
	affix_table = load(AFFIX_TABLE_PATH) as AffixTableResource
	upgrade_cost_table = load(UPGRADE_COSTS_PATH) as UpgradeCostTableResource


func _calculate_attack_with_star_level(weapon_: WeaponInstanceResource, star_level_: int) -> float:
	if weapon_ == null or weapon_.weapon_data == null:
		return 0.0

	var attack_bonus_ := _calculate_attack_bonus_with_star_level(weapon_, star_level_)
	return (weapon_.weapon_data.base_atk + weapon_.enhance_level) * (1.0 + attack_bonus_)


func _calculate_attack_bonus_with_star_level(weapon_: WeaponInstanceResource, star_level_: int) -> float:
	if weapon_ == null:
		return 0.0

	return float(clampi(star_level_, 0, 5)) * 0.05 + weapon_.get_total_stat_modifier(&"attack_bonus_pct")


func _get_save_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("SaveManager")
#endregion
