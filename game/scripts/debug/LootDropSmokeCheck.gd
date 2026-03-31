extends Node

const GearDataResource = preload("res://game/scripts/data/GearData.gd")
const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const LootTableResource = preload("res://game/scripts/data/LootTableData.gd")
const DEFAULT_LOOT_TABLE_PATH := "res://game/data/loot_tables/loot_dummy_basic.tres"

func _ready() -> void:
	var loot_table_path_ := DEFAULT_LOOT_TABLE_PATH
	var args_ := OS.get_cmdline_user_args()
	if not args_.is_empty():
		loot_table_path_ = String(args_[0])

	var loot_table_: LootTableResource = load(loot_table_path_) as LootTableResource
	if loot_table_ == null:
		push_error("Failed to load loot table: %s" % loot_table_path_)
		get_tree().quit(1)
		return

	for roll_index_ in range(5):
		var drops_ := loot_table_.generate_drops()
		var descriptions_: PackedStringArray = []

		for drop_ in drops_:
			if drop_.has("gold"):
				descriptions_.append("Gold x%d" % int(drop_.get("gold", 0)))
			elif drop_.has("item_data"):
				var item_data_: ItemDataResource = drop_["item_data"]
				descriptions_.append("%s x%d" % [item_data_.display_name, int(drop_.get("amount", 1))])
			elif drop_.has("gear_data"):
				var gear_data_: GearDataResource = drop_["gear_data"] as GearDataResource
				descriptions_.append("%s" % gear_data_.display_name)
			elif drop_.has("weapon_data"):
				var weapon_data_: WeaponData = drop_["weapon_data"] as WeaponData
				descriptions_.append("%s" % weapon_data_.display_name)

		print("[LootSmoke][%d] %s" % [roll_index_ + 1, ", ".join(descriptions_) if not descriptions_.is_empty() else "No drops"])

	get_tree().quit()
