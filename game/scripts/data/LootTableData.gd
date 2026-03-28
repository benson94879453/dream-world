class_name LootTableData
extends Resource

const LootEntryResource = preload("res://game/scripts/data/LootEntryData.gd")
const RuneDataResource = preload("res://game/scripts/data/RuneData.gd")

@export var loot_entries: Array[LootEntryResource] = []
@export var min_gold: int = 0
@export var max_gold: int = 0
@export_range(0.0, 1.0, 0.01) var rune_drop_chance: float = 0.0
@export var rune_drop_pool: Array[RuneDataResource] = []

#region Public
func generate_drops() -> Array[Dictionary]:
	var rng_ := RandomNumberGenerator.new()
	rng_.randomize()

	var drops_: Array[Dictionary] = []
	var min_gold_ := maxi(min_gold, 0)
	var max_gold_ := maxi(max_gold, min_gold_)
	if max_gold_ > 0:
		drops_.append({
			"gold": rng_.randi_range(min_gold_, max_gold_)
		})

	for loot_entry_ in loot_entries:
		if loot_entry_ == null:
			continue

		if loot_entry_.drop_chance <= 0.0:
			continue

		if rng_.randf() > minf(loot_entry_.drop_chance, 1.0):
			continue

		if loot_entry_.weapon_data != null:
			drops_.append({
				"weapon_data": loot_entry_.weapon_data
			})
			continue

		if loot_entry_.item_data == null:
			continue

		var min_amount_ := maxi(loot_entry_.min_amount, 1)
		var max_amount_ := maxi(loot_entry_.max_amount, min_amount_)
		drops_.append({
			"item_data": loot_entry_.item_data,
			"amount": rng_.randi_range(min_amount_, max_amount_)
		})

	if rune_drop_chance > 0.0 and rng_.randf() <= minf(rune_drop_chance, 1.0):
		var rune_data_ := _roll_rune_drop(rng_)
		if rune_data_ != null:
			drops_.append({
				"item_data": rune_data_,
				"amount": 1
			})

	return drops_
#endregion

#region Helpers
func _roll_rune_drop(rng_: RandomNumberGenerator) -> RuneDataResource:
	var rune_pool_: Array[RuneDataResource] = []
	if not rune_drop_pool.is_empty():
		rune_pool_ = rune_drop_pool
	else:
		var rune_manager_ = _get_rune_manager()
		if rune_manager_ != null:
			rune_pool_ = rune_manager_.available_runes

	if rune_pool_.is_empty():
		return null

	return rune_pool_[rng_.randi_range(0, rune_pool_.size() - 1)]


func _get_rune_manager() -> Node:
	var main_loop_: SceneTree = Engine.get_main_loop() as SceneTree
	if main_loop_ == null or main_loop_.root == null:
		return null
	return main_loop_.root.get_node_or_null("RuneManager")
#endregion
