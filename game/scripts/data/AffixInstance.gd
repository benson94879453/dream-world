class_name AffixInstance
extends RefCounted

const AffixDataResource = preload("res://game/scripts/data/AffixData.gd")

var affix_id: StringName = &""
var affix_name: String = ""
var description: String = ""
var stat_modifiers: Dictionary = {}

#region Public
static func create_from_data(affix_data_: AffixDataResource):
	assert(affix_data_ != null, "AffixInstance requires AffixData")

	var affix_instance_ = new()
	affix_instance_.affix_id = affix_data_.affix_id
	affix_instance_.affix_name = affix_data_.affix_name
	affix_instance_.description = affix_data_.description
	affix_instance_.stat_modifiers = affix_data_.stat_modifiers.duplicate(true)
	return affix_instance_


static func create_from_save_dict(data_: Dictionary):
	var affix_instance_ = new()
	affix_instance_.affix_id = StringName(String(data_.get("affix_id", "")))
	affix_instance_.affix_name = String(data_.get("affix_name", ""))
	affix_instance_.description = String(data_.get("description", ""))

	var stat_modifiers_ = data_.get("stat_modifiers", {})
	if typeof(stat_modifiers_) == TYPE_DICTIONARY:
		affix_instance_.stat_modifiers = stat_modifiers_.duplicate(true)

	return affix_instance_


func to_save_dict() -> Dictionary:
	return {
		"affix_id": String(affix_id),
		"affix_name": affix_name,
		"description": description,
		"stat_modifiers": stat_modifiers.duplicate(true)
	}
#endregion
