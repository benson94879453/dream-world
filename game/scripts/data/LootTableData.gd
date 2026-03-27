class_name LootTableData
extends Resource

const LootEntryResource = preload("res://game/scripts/data/LootEntryData.gd")

@export var loot_entries: Array[LootEntryResource] = []

#region Public
func generate_drops() -> Array[Dictionary]:
	var rng_ := RandomNumberGenerator.new()
	rng_.randomize()

	var drops_: Array[Dictionary] = []
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

	return drops_
#endregion
