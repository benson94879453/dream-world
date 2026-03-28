class_name AffixData
extends Resource

@export var affix_id: StringName = &""
@export var affix_name: String = ""
@export_multiline var description: String = ""
@export var stat_modifiers: Dictionary = {}
@export var weight: int = 1
@export var valid_categories: Array[StringName] = []


func is_valid_for_category(weapon_category_: StringName) -> bool:
	if valid_categories.is_empty():
		return true

	return valid_categories.has(weapon_category_)
