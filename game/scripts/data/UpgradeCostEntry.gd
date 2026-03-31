class_name UpgradeCostEntry
extends Resource

@export_range(1, 5, 1) var star_level: int = 1
@export var item_costs: Dictionary = {}


func get_costs() -> Array[Dictionary]:
	var normalized_costs_: Array[Dictionary] = []

	for item_id_ in item_costs.keys():
		var amount_: int = int(item_costs[item_id_])
		if amount_ <= 0:
			continue

		normalized_costs_.append({
			"item_id": StringName(String(item_id_)),
			"amount": amount_
		})

	return normalized_costs_
