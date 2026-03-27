class_name WeaponInstance
extends RefCounted

var instance_uid: String = ""
var weapon_id: StringName = &""
var enhance_level: int = 0
var temporary_enchants: Array[StringName] = []
var socketed_gems: Array[StringName] = []
var weapon_data: WeaponData = null

#region Public
static func create_from_data(weapon_data_: WeaponData) -> WeaponInstance:
	assert(weapon_data_ != null, "WeaponInstance requires WeaponData")

	var weapon_instance_: WeaponInstance = WeaponInstance.new()
	weapon_instance_.instance_uid = _generate_instance_uid(weapon_data_)
	weapon_instance_.weapon_id = weapon_data_.weapon_id
	weapon_instance_.weapon_data = weapon_data_

	return weapon_instance_


static func create_from_save_dict(weapon_data_: WeaponData, data_: Dictionary) -> WeaponInstance:
	var weapon_instance_ := create_from_data(weapon_data_)
	weapon_instance_.instance_uid = String(data_.get("instance_uid", weapon_instance_.instance_uid))
	weapon_instance_.weapon_id = StringName(data_.get("weapon_id", weapon_data_.weapon_id))
	weapon_instance_.enhance_level = int(data_.get("enhance_level", 0))

	var temporary_enchants_ = data_.get("temporary_enchants", [])
	weapon_instance_.temporary_enchants.clear()
	for enchant_ in temporary_enchants_:
		weapon_instance_.temporary_enchants.append(StringName(enchant_))

	var socketed_gems_ = data_.get("socketed_gems", [])
	weapon_instance_.socketed_gems.clear()
	for gem_ in socketed_gems_:
		weapon_instance_.socketed_gems.append(StringName(gem_))

	return weapon_instance_


func to_save_dict() -> Dictionary:
	return {
		"instance_uid": instance_uid,
		"weapon_id": String(weapon_id),
		"enhance_level": enhance_level,
		"temporary_enchants": temporary_enchants.map(func(value_: StringName) -> String: return String(value_)),
		"socketed_gems": socketed_gems.map(func(value_: StringName) -> String: return String(value_))
	}


func get_base_attack() -> float:
	assert(weapon_data != null, "WeaponInstance requires WeaponData")
	return weapon_data.base_atk + enhance_level


func get_attack_cooldown() -> float:
	assert(weapon_data != null, "WeaponInstance requires WeaponData")
	return 1.0 / maxf(weapon_data.attack_speed, 0.001)


func get_attack_range() -> float:
	assert(weapon_data != null, "WeaponInstance requires WeaponData")
	return weapon_data.attack_range
#endregion

#region Helpers
static func _generate_instance_uid(weapon_data_: WeaponData) -> String:
	return "%s_%s_%d" % [
		String(weapon_data_.weapon_id),
		str(Time.get_unix_time_from_system()).replace(".", "_"),
		randi()
	]
#endregion
