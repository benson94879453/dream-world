class_name QuestInstance
extends RefCounted

const QuestDataResource = preload("res://game/scripts/data/QuestData.gd")

var quest_id: StringName = &""
var quest_data: QuestDataResource = null
var status: QuestDataResource.QuestStatus = QuestDataResource.QuestStatus.NOT_STARTED

var current_progress: int = 0
var target_amount: int = 1

var accepted_at: String = ""
var completed_at: String = ""
var turned_in_at: String = ""

static func create_from_data(quest_data_: QuestDataResource) -> QuestInstance:
	assert(quest_data_ != null, "QuestInstance.create_from_data requires QuestData")

	var quest_instance_ := QuestInstance.new()
	quest_instance_.quest_id = quest_data_.quest_id
	quest_instance_.quest_data = quest_data_
	quest_instance_.status = QuestDataResource.QuestStatus.ACTIVE
	quest_instance_.target_amount = maxi(quest_data_.target_amount, 1)
	quest_instance_.accepted_at = _get_iso8601_utc_now()
	return quest_instance_


static func create_from_save_dict(quest_data_: QuestDataResource, data_: Dictionary) -> QuestInstance:
	var quest_instance_ := create_from_data(quest_data_)
	quest_instance_.quest_id = StringName(String(data_.get("quest_id", quest_data_.quest_id)))
	quest_instance_.status = int(data_.get("status", QuestDataResource.QuestStatus.ACTIVE))
	quest_instance_.current_progress = maxi(int(data_.get("current_progress", 0)), 0)
	quest_instance_.target_amount = maxi(int(data_.get("target_amount", quest_data_.target_amount)), 1)
	quest_instance_.accepted_at = String(data_.get("accepted_at", quest_instance_.accepted_at))
	quest_instance_.completed_at = String(data_.get("completed_at", ""))
	quest_instance_.turned_in_at = String(data_.get("turned_in_at", ""))
	return quest_instance_


func to_save_dict() -> Dictionary:
	return {
		"quest_id": String(quest_id),
		"status": int(status),
		"current_progress": current_progress,
		"target_amount": target_amount,
		"accepted_at": accepted_at,
		"completed_at": completed_at,
		"turned_in_at": turned_in_at
	}


func is_completed() -> bool:
	return status == QuestDataResource.QuestStatus.COMPLETED or status == QuestDataResource.QuestStatus.TURNED_IN


func get_progress_text() -> String:
	return "%d/%d" % [current_progress, target_amount]


static func _get_iso8601_utc_now() -> String:
	var datetime_ := Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02dT%02d:%02d:%02dZ" % [
		int(datetime_.get("year", 1970)),
		int(datetime_.get("month", 1)),
		int(datetime_.get("day", 1)),
		int(datetime_.get("hour", 0)),
		int(datetime_.get("minute", 0)),
		int(datetime_.get("second", 0))
	]
