class_name AffixTable
extends Resource

const AffixDataResource = preload("res://game/scripts/data/AffixData.gd")

@export var affixes: Array[AffixDataResource] = []


func roll_affix(weapon_category_: StringName, excluded_affix_ids_: Array[StringName] = []) -> AffixDataResource:
	var candidates_: Array[AffixDataResource] = []
	var total_weight_: int = 0

	for affix_ in affixes:
		if affix_ == null or affix_.affix_id.is_empty():
			continue
		if excluded_affix_ids_.has(affix_.affix_id):
			continue
		if not affix_.is_valid_for_category(weapon_category_):
			continue

		candidates_.append(affix_)
		total_weight_ += maxi(affix_.weight, 1)

	if candidates_.is_empty():
		for affix_ in affixes:
			if affix_ == null or affix_.affix_id.is_empty():
				continue
			if not affix_.is_valid_for_category(weapon_category_):
				continue

			candidates_.append(affix_)
			total_weight_ += maxi(affix_.weight, 1)

	if candidates_.is_empty() or total_weight_ <= 0:
		return null

	var roll_ := randi_range(1, total_weight_)
	var accumulated_weight_: int = 0
	for affix_ in candidates_:
		accumulated_weight_ += maxi(affix_.weight, 1)
		if roll_ <= accumulated_weight_:
			return affix_

	return candidates_.back()
