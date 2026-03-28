class_name EnemyInstance
extends RefCounted

var instance_uid: String = ""
var enemy_id: StringName = &""
var current_hp: float = 0.0
var enemy_data: EnemyData = null

#region Public
func _init(enemy_id_: StringName = &"", uid_: String = "") -> void:
	enemy_id = enemy_id_
	instance_uid = uid_ if not uid_.is_empty() else _generate_instance_uid(enemy_id_)


static func create_from_data(enemy_data_: EnemyData) -> EnemyInstance:
	assert(enemy_data_ != null, "EnemyInstance requires EnemyData")

	var enemy_instance_: EnemyInstance = EnemyInstance.new(enemy_data_.enemy_id)
	enemy_instance_.enemy_data = enemy_data_
	enemy_instance_.current_hp = float(enemy_data_.max_hp)

	return enemy_instance_


static func create_from_save_dict(enemy_data_: EnemyData, data_: Dictionary) -> EnemyInstance:
	var enemy_instance_: EnemyInstance = create_from_data(enemy_data_)
	enemy_instance_.instance_uid = String(data_.get("instance_uid", enemy_instance_.instance_uid))
	enemy_instance_.enemy_id = StringName(data_.get("enemy_id", enemy_data_.enemy_id))
	enemy_instance_.current_hp = float(data_.get("current_hp", enemy_instance_.current_hp))

	return enemy_instance_


func to_save_dict() -> Dictionary:
	return {
		"instance_uid": instance_uid,
		"enemy_id": String(enemy_id),
		"current_hp": current_hp
	}
#endregion

#region Helpers
static func _generate_instance_uid(enemy_id_: StringName) -> String:
	return "%s_%s_%d" % [
		String(enemy_id_),
		str(Time.get_unix_time_from_system()).replace(".", "_"),
		randi()
	]
#endregion
