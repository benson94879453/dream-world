class_name RuneInstance
extends RefCounted

const RuneDataResource = preload("res://game/scripts/data/RuneData.gd")

var rune_data: RuneDataResource = null
var instance_uid: String = ""

static func create_from_data(data_: RuneDataResource):
	assert(data_ != null, "RuneInstance requires RuneData")

	var rune_instance_ = preload("res://game/scripts/data/RuneInstance.gd").new()
	rune_instance_.rune_data = data_
	rune_instance_.instance_uid = "%s_%s_%d" % [
		String(data_.get_runtime_rune_id()),
		str(Time.get_unix_time_from_system()).replace(".", "_"),
		randi()
	]
	return rune_instance_
