class_name DWQuestManager
extends Node

const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const QuestDataResource = preload("res://game/scripts/data/QuestData.gd")
const QuestInstanceResource = preload("res://game/scripts/data/QuestInstance.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")

const QUEST_DATA_ROOT: String = "res://game/data/quests"

signal quest_accepted(quest_id: StringName)
signal quest_progress_updated(quest_id: StringName, current: int, target: int)
signal quest_completed(quest_id: StringName)
signal quest_turned_in(quest_id: StringName)

var active_quests: Dictionary = {}
var completed_quests: Array[StringName] = []
var quest_data_cache: Dictionary = {}

#region Core Lifecycle
func _ready() -> void:
	_load_quest_data_from_files()
#endregion

#region Public
func accept_quest(quest_id_: StringName) -> bool:
	var quest_data_: QuestDataResource = get_quest_data(quest_id_)
	if not can_accept_quest(quest_data_):
		return false

	var quest_ := QuestInstanceResource.create_from_data(quest_data_)
	active_quests[quest_id_] = quest_
	quest_accepted.emit(quest_id_)

	match quest_data_.quest_type:
		QuestDataResource.QuestType.COLLECT, QuestDataResource.QuestType.DELIVER:
			_sync_item_progress(quest_, true)

	return true


func abandon_quest(quest_id_: StringName) -> bool:
	if not has_active_quest(quest_id_):
		return false

	active_quests.erase(quest_id_)
	return true


func turn_in_quest(quest_id_: StringName) -> bool:
	var quest_: QuestInstanceResource = get_quest_by_id(quest_id_)
	if quest_ == null:
		return false

	if quest_.quest_data != null and quest_.quest_data.quest_type == QuestDataResource.QuestType.DELIVER:
		_sync_item_progress(quest_, true)

	if quest_.status != QuestDataResource.QuestStatus.COMPLETED:
		return false

	var player_: Node = _get_player()
	if player_ == null:
		return false

	var inventory_ = player_.get_inventory()
	var quest_data_ := quest_.quest_data
	if quest_data_ == null:
		return false

	if quest_data_.quest_type == QuestDataResource.QuestType.DELIVER:
		var item_data_: ItemDataResource = _resolve_item_data(quest_data_.target_item_id)
		if item_data_ == null:
			return false
		if inventory_ == null or inventory_.remove_item(item_data_, quest_.target_amount) < quest_.target_amount:
			_sync_item_progress(quest_, true)
			return false

	if quest_data_.reward_gold > 0:
		player_.add_gold(quest_data_.reward_gold)

	if quest_data_.reward_item_id != &"" and quest_data_.reward_item_amount > 0 and inventory_ != null:
		var reward_item_data_: ItemDataResource = _resolve_item_data(quest_data_.reward_item_id)
		if reward_item_data_ != null:
			var remaining_amount_: int = inventory_.add_item(reward_item_data_, quest_data_.reward_item_amount)
			if remaining_amount_ > 0:
				push_warning("[QuestManager] Reward item inventory overflow: %s (%d left)" % [String(quest_data_.reward_item_id), remaining_amount_])

	if quest_data_.reward_weapon_id != &"" and inventory_ != null:
		var weapon_data_: WeaponData = _resolve_weapon_data(quest_data_.reward_weapon_id)
		if weapon_data_ != null:
			if not inventory_.add_weapon(WeaponInstanceResource.create_from_data(weapon_data_)):
				push_warning("[QuestManager] Reward weapon inventory overflow: %s" % String(quest_data_.reward_weapon_id))

	quest_.status = QuestDataResource.QuestStatus.TURNED_IN
	quest_.turned_in_at = _get_iso8601_utc_now()
	_append_completed_quest_id(quest_id_)
	active_quests.erase(quest_id_)
	quest_turned_in.emit(quest_id_)
	return true


func report_enemy_killed(enemy_id_: StringName, count_: int = 1) -> void:
	if enemy_id_.is_empty() or count_ <= 0:
		return

	for quest_ in get_active_quests():
		if quest_ == null or quest_.status != QuestDataResource.QuestStatus.ACTIVE:
			continue
		if quest_.quest_data == null or quest_.quest_data.quest_type != QuestDataResource.QuestType.KILL:
			continue
		if quest_.quest_data.target_enemy_id != enemy_id_:
			continue

		_set_progress(quest_, quest_.current_progress + count_, true)


func report_item_collected(item_id_: StringName, _count_: int = 1) -> void:
	if item_id_.is_empty():
		return

	for quest_ in get_active_quests():
		if quest_ == null or quest_.status == QuestDataResource.QuestStatus.TURNED_IN:
			continue
		if quest_.quest_data == null:
			continue
		if quest_.quest_data.quest_type != QuestDataResource.QuestType.COLLECT and quest_.quest_data.quest_type != QuestDataResource.QuestType.DELIVER:
			continue
		if quest_.quest_data.target_item_id != item_id_:
			continue

		_sync_item_progress(quest_, true)


func report_npc_talked(npc_id_: StringName) -> void:
	if npc_id_.is_empty():
		return

	for quest_ in get_active_quests():
		if quest_ == null or quest_.status != QuestDataResource.QuestStatus.ACTIVE:
			continue
		if quest_.quest_data == null or quest_.quest_data.quest_type != QuestDataResource.QuestType.TALK:
			continue
		if quest_.quest_data.target_npc_id != npc_id_:
			continue

		_set_progress(quest_, quest_.current_progress + 1, true)


func get_active_quests() -> Array[QuestInstanceResource]:
	var quests_: Array[QuestInstanceResource] = []
	for quest_id_ in active_quests.keys():
		var quest_: QuestInstanceResource = active_quests.get(quest_id_) as QuestInstanceResource
		if quest_ != null:
			quests_.append(quest_)

	quests_.sort_custom(func(left_: QuestInstanceResource, right_: QuestInstanceResource) -> bool:
		return String(left_.quest_id) < String(right_.quest_id)
	)
	return quests_


func get_quest_by_id(quest_id_: StringName) -> QuestInstanceResource:
	return active_quests.get(quest_id_, null) as QuestInstanceResource


func get_quest_data(quest_id_: StringName) -> QuestDataResource:
	if quest_data_cache.is_empty():
		_load_quest_data_from_files()
	return quest_data_cache.get(quest_id_, null) as QuestDataResource


func has_active_quest(quest_id_: StringName) -> bool:
	return active_quests.has(quest_id_)


func has_completed_quest(quest_id_: StringName) -> bool:
	return completed_quests.has(quest_id_)


func can_accept_quest(quest_data_: QuestDataResource) -> bool:
	if quest_data_ == null or quest_data_.quest_id.is_empty():
		return false
	if has_active_quest(quest_data_.quest_id) or has_completed_quest(quest_data_.quest_id):
		return false
	if quest_data_.minimum_level > _get_player_level():
		return false
	if not quest_data_.prerequisite_quest_id.is_empty() and not has_completed_quest(quest_data_.prerequisite_quest_id):
		return false
	return true


func to_save_dict() -> Dictionary:
	var active_entries_: Array[Dictionary] = []
	for quest_ in get_active_quests():
		active_entries_.append(quest_.to_save_dict())

	var completed_entries_: Array[String] = []
	for quest_id_ in completed_quests:
		completed_entries_.append(String(quest_id_))

	return {
		"active_quests": active_entries_,
		"completed_quests": completed_entries_
	}


func from_save_dict(data_: Dictionary) -> bool:
	active_quests.clear()
	completed_quests.clear()

	if typeof(data_) != TYPE_DICTIONARY:
		return false

	if quest_data_cache.is_empty():
		_load_quest_data_from_files()

	var raw_completed_quests_ = data_.get("completed_quests", [])
	if typeof(raw_completed_quests_) == TYPE_ARRAY:
		for quest_id_value_ in raw_completed_quests_:
			var quest_id_: StringName = StringName(String(quest_id_value_))
			if quest_id_.is_empty() or completed_quests.has(quest_id_):
				continue
			completed_quests.append(quest_id_)

	var raw_active_quests_ = data_.get("active_quests", [])
	if typeof(raw_active_quests_) != TYPE_ARRAY:
		return true

	for quest_entry_ in raw_active_quests_:
		if typeof(quest_entry_) != TYPE_DICTIONARY:
			continue

		var quest_id_: StringName = StringName(String(quest_entry_.get("quest_id", "")))
		var quest_data_: QuestDataResource = get_quest_data(quest_id_)
		if quest_data_ == null:
			push_warning("[QuestManager] Missing quest data during load: %s" % String(quest_id_))
			continue

		active_quests[quest_id_] = QuestInstanceResource.create_from_save_dict(quest_data_, quest_entry_)

	return true
#endregion

#region Helpers
func _load_quest_data_from_files() -> void:
	quest_data_cache.clear()

	for quest_path_ in _collect_resource_paths(QUEST_DATA_ROOT):
		var quest_data_: QuestDataResource = load(quest_path_) as QuestDataResource
		if quest_data_ == null or quest_data_.quest_id.is_empty():
			continue
		quest_data_cache[quest_data_.quest_id] = quest_data_


func _collect_resource_paths(root_path_: String) -> PackedStringArray:
	var resource_paths_: PackedStringArray = []
	var directory_ := DirAccess.open(root_path_)
	if directory_ == null:
		return resource_paths_

	directory_.list_dir_begin()
	while true:
		var entry_name_ := directory_.get_next()
		if entry_name_.is_empty():
			break
		if entry_name_.begins_with("."):
			continue

		var entry_path_ := "%s/%s" % [root_path_, entry_name_]
		if directory_.current_is_dir():
			resource_paths_.append_array(_collect_resource_paths(entry_path_))
			continue

		if entry_name_.ends_with(".tres"):
			resource_paths_.append(entry_path_)

	return resource_paths_


func _sync_item_progress(quest_: QuestInstanceResource, emit_signal_: bool) -> void:
	if quest_ == null or quest_.quest_data == null:
		return

	var inventory_count_: int = _get_inventory_item_count(quest_.quest_data.target_item_id)
	var next_progress_: int = inventory_count_
	if quest_.quest_data.quest_type == QuestDataResource.QuestType.COLLECT:
		next_progress_ = maxi(quest_.current_progress, inventory_count_)

	_set_progress(quest_, next_progress_, emit_signal_)


func _set_progress(quest_: QuestInstanceResource, next_progress_: int, emit_signal_: bool) -> void:
	if quest_ == null or quest_.status == QuestDataResource.QuestStatus.TURNED_IN:
		return

	var clamped_progress_: int = clampi(next_progress_, 0, quest_.target_amount)
	var did_change_: bool = clamped_progress_ != quest_.current_progress
	quest_.current_progress = clamped_progress_

	var should_complete_: bool = quest_.current_progress >= quest_.target_amount
	if should_complete_ and quest_.status == QuestDataResource.QuestStatus.ACTIVE:
		quest_.status = QuestDataResource.QuestStatus.COMPLETED
		if quest_.completed_at.is_empty():
			quest_.completed_at = _get_iso8601_utc_now()
		quest_completed.emit(quest_.quest_id)
	elif not should_complete_ and quest_.status == QuestDataResource.QuestStatus.COMPLETED:
		quest_.status = QuestDataResource.QuestStatus.ACTIVE
		quest_.completed_at = ""

	if did_change_ and emit_signal_:
		quest_progress_updated.emit(quest_.quest_id, quest_.current_progress, quest_.target_amount)


func _append_completed_quest_id(quest_id_: StringName) -> void:
	if quest_id_.is_empty() or completed_quests.has(quest_id_):
		return
	completed_quests.append(quest_id_)


func _get_player() -> Node:
	return get_tree().get_first_node_in_group("player")


func _get_save_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("SaveManager")


func _resolve_item_data(item_id_: StringName) -> ItemDataResource:
	if item_id_.is_empty():
		return null

	var save_manager_: Node = _get_save_manager()
	if save_manager_ == null:
		return null
	return save_manager_.resolve_item_data(item_id_) as ItemDataResource


func _resolve_weapon_data(weapon_id_: StringName) -> WeaponData:
	if weapon_id_.is_empty():
		return null

	var save_manager_: Node = _get_save_manager()
	if save_manager_ == null:
		return null
	return save_manager_.resolve_weapon_data(weapon_id_)


func _get_inventory_item_count(item_id_: StringName) -> int:
	if item_id_.is_empty():
		return 0

	var player_: Node = _get_player()
	if player_ == null:
		return 0

	var inventory_ = player_.get_inventory()
	var item_data_: ItemDataResource = _resolve_item_data(item_id_)
	if inventory_ == null or item_data_ == null:
		return 0

	return inventory_.get_item_count(item_data_)


func _get_player_level() -> int:
	var player_: Node = _get_player()
	if player_ == null:
		return 1
	if player_.has_method("get_level"):
		return maxi(int(player_.call("get_level")), 1)

	var level_value_ = player_.get("level")
	if level_value_ == null:
		return 1
	return maxi(int(level_value_), 1)


func _get_iso8601_utc_now() -> String:
	var datetime_ := Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02dT%02d:%02d:%02dZ" % [
		int(datetime_.get("year", 1970)),
		int(datetime_.get("month", 1)),
		int(datetime_.get("day", 1)),
		int(datetime_.get("hour", 0)),
		int(datetime_.get("minute", 0)),
		int(datetime_.get("second", 0))
	]
#endregion
