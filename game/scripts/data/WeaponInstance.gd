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
	weapon_instance_.instance_uid = "%s_%s" % [String(weapon_data_.weapon_id), str(Time.get_unix_time_from_system()).replace(".", "_")]
	weapon_instance_.weapon_id = weapon_data_.weapon_id
	weapon_instance_.weapon_data = weapon_data_

	return weapon_instance_


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
