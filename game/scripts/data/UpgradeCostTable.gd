class_name UpgradeCostTable
extends Resource

const UpgradeCostEntryResource = preload("res://game/scripts/data/UpgradeCostEntry.gd")

@export var entries: Array[UpgradeCostEntryResource] = []


func get_costs_for_star_level(star_level_: int) -> Array[Dictionary]:
	for entry_ in entries:
		if entry_ == null:
			continue
		if entry_.star_level == star_level_:
			return entry_.get_costs()

	return []
