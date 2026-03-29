class_name GearInstance
extends RefCounted

const GearDataResource = preload("res://game/scripts/data/GearData.gd")

var instance_uid: String = ""
var gear_id: StringName = &""
var gear_data: GearDataResource = null
var current_durability: int = -1
var enhance_level: int = 0
var socketed_gems: Array[StringName] = []

#region Public
static func create_from_data(gear_data_: GearDataResource) -> GearInstance:
	assert(gear_data_ != null, "GearInstance requires GearData")
	assert(not gear_data_.gear_id.is_empty(), "GearInstance requires GearData.gear_id")

	var gear_instance_ = preload("res://game/scripts/data/GearInstance.gd").new()
	gear_instance_.instance_uid = _generate_instance_uid(gear_data_)
	gear_instance_.gear_id = gear_data_.gear_id
	gear_instance_.gear_data = gear_data_
	gear_instance_.current_durability = gear_data_.max_durability if gear_data_.max_durability >= 0 else -1

	return gear_instance_


static func create_from_save_dict(gear_data_: GearDataResource, data_: Dictionary) -> GearInstance:
	assert(gear_data_ != null, "GearInstance restore requires GearData")

	var gear_instance_ := create_from_data(gear_data_)
	gear_instance_.instance_uid = String(data_.get("instance_uid", gear_instance_.instance_uid))
	gear_instance_.gear_id = StringName(data_.get("gear_id", gear_data_.gear_id))
	gear_instance_.current_durability = int(data_.get("current_durability", gear_instance_.current_durability))
	gear_instance_.enhance_level = maxi(int(data_.get("enhance_level", 0)), 0)

	var socketed_gems_ = data_.get("socketed_gems", [])
	gear_instance_.socketed_gems.clear()
	for gem_id_ in socketed_gems_:
		gear_instance_.socketed_gems.append(StringName(gem_id_))

	return gear_instance_


func to_save_dict() -> Dictionary:
	return {
		"instance_uid": instance_uid,
		"gear_id": String(gear_id),
		"current_durability": current_durability,
		"enhance_level": enhance_level,
		"socketed_gems": socketed_gems.map(func(value_: StringName) -> String: return String(value_))
	}


func get_total_defense() -> float:
	assert(gear_data != null, "GearInstance requires GearData")
	var base_defense_ := gear_data.defense
	var enhance_bonus_ := base_defense_ * float(enhance_level) * 0.1
	return base_defense_ + enhance_bonus_
#endregion

#region Helpers
static func _generate_instance_uid(gear_data_: GearDataResource) -> String:
	return "%s_%s_%d" % [
		String(gear_data_.gear_id),
		str(Time.get_unix_time_from_system()).replace(".", "_"),
		randi()
	]
#endregion
