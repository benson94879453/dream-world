extends Node

const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const LootTableResource = preload("res://game/scripts/data/LootTableData.gd")

func _ready() -> void:
	var loot_table_ := load("res://game/data/loot_tables/loot_dummy_basic.tres") as LootTableResource
	if loot_table_ == null:
		push_error("Failed to load loot table")
		get_tree().quit(1)
		return

	for roll_index_ in range(5):
		var drops_ := loot_table_.generate_drops()
		var descriptions_: PackedStringArray = []

		for drop_ in drops_:
			if drop_.has("item_data"):
				var item_data_: ItemDataResource = drop_["item_data"]
				descriptions_.append("%s x%d" % [item_data_.display_name, int(drop_.get("amount", 1))])
			elif drop_.has("weapon_data"):
				var weapon_data_ := drop_["weapon_data"] as WeaponData
				descriptions_.append("%s" % weapon_data_.display_name)

		print("[LootSmoke][%d] %s" % [roll_index_ + 1, ", ".join(descriptions_) if not descriptions_.is_empty() else "No drops"])

	get_tree().quit()
