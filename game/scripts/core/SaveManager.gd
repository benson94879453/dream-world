extends Node

const GearDataResource = preload("res://game/scripts/data/GearData.gd")
const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const RuneDataResource = preload("res://game/scripts/data/RuneData.gd")
const WeaponDataResource = preload("res://game/scripts/data/WeaponData.gd")

const SAVE_VERSION: int = 7
const SAVE_FILE_PATH: String = "user://savegame.json"
const GEAR_DATA_ROOT: String = "res://game/data/gears"
const ITEM_DATA_ROOT: String = "res://game/data/items"
const RUNE_DATA_ROOT: String = "res://game/data/runes"
const WEAPON_DATA_ROOT: String = "res://game/data/weapons"

signal save_completed(success: bool)
signal load_completed(success: bool)

var gear_data_by_id: Dictionary = {}
var item_data_by_id: Dictionary = {}
var rune_data_by_id: Dictionary = {}
var weapon_data_by_id: Dictionary = {}

#region Core Lifecycle
func _ready() -> void:
	_refresh_resource_caches()
#endregion

#region Public
func save_game() -> bool:
	var player_ = _get_player()
	if player_ == null:
		push_warning("[SaveManager] Cannot save without Player")
		save_completed.emit(false)
		return false

	var inventory_ = player_.get_inventory()
	if inventory_ == null:
		push_warning("[SaveManager] Cannot save without Inventory")
		save_completed.emit(false)
		return false

	var existing_data_ = _read_save_file()
	var created_at_ = existing_data_.get("created_at", _get_iso8601_utc_now()) if not existing_data_.is_empty() else _get_iso8601_utc_now()
	var dialog_manager_ = _get_dialog_manager()
	var quest_manager_ = _get_quest_manager()
	var player_data_: Dictionary = player_.to_save_dict()
	var inventory_data_: Dictionary = inventory_.to_save_dict()
	var save_data_ = {
		"save_version": SAVE_VERSION,
		"created_at": created_at_,
		"updated_at": _get_iso8601_utc_now(),
		"player": player_data_,
		"inventory": inventory_data_,
		"progression": {
			"unlocked_souls": [],
			"flags": {}
		},
		"dialog": dialog_manager_.to_save_dict() if dialog_manager_ != null else {},
		"quest": quest_manager_.to_save_dict() if quest_manager_ != null else {}
	}
	save_data_["checksum"] = _calculate_checksum(player_data_, inventory_data_)

	var save_file_ := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file_ == null:
		push_warning("[SaveManager] Failed to open save file for writing: %s" % SAVE_FILE_PATH)
		save_completed.emit(false)
		return false

	save_file_.store_string(JSON.stringify(save_data_, "\t"))
	save_file_.close()

	print("[SaveManager] Save completed: %s" % ProjectSettings.globalize_path(SAVE_FILE_PATH))
	save_completed.emit(true)
	return true


func load_game() -> bool:
	if not has_save_file():
		push_warning("[SaveManager] No save file found")
		load_completed.emit(false)
		return false

	var data_ = _read_save_file()
	if data_.is_empty():
		push_warning("[SaveManager] Save file is empty or invalid")
		load_completed.emit(false)
		return false

	if not _validate_save_data(data_, true):
		push_warning("[SaveManager] Save file failed validation")
		load_completed.emit(false)
		return false

	var save_version_ := int(data_.get("save_version", 0))
	var migrated_data_ = _migrate_save_data(data_, save_version_)
	if not _validate_save_data(migrated_data_, false):
		push_warning("[SaveManager] Migrated save data failed validation")
		load_completed.emit(false)
		return false
	var player_ = _get_player()
	if player_ == null:
		push_warning("[SaveManager] Cannot load without Player")
		load_completed.emit(false)
		return false

	var inventory_ = player_.get_inventory()
	if inventory_ == null:
		push_warning("[SaveManager] Cannot load without Inventory")
		load_completed.emit(false)
		return false

	var inventory_data_ = migrated_data_.get("inventory", {})
	var player_data_ = migrated_data_.get("player", {})

	inventory_.from_save_dict(inventory_data_)
	var player_load_report_: Dictionary = player_.from_save_dict(player_data_)

	var equipped_restored_ := true
	var equipment_data_ = player_data_.get("equipment", {})
	var has_equipment_save_: bool = typeof(equipment_data_) == TYPE_DICTIONARY and not equipment_data_.is_empty()
	var has_equipment_weapon_: bool = has_equipment_save_ and typeof(equipment_data_.get("weapon_main", null)) == TYPE_DICTIONARY
	if has_equipment_save_:
		if player_.equipment != null:
			var equipment_loaded_: bool = bool(player_load_report_.get("equipment_loaded", false))
			if not equipment_loaded_:
				push_warning("[SaveManager] Equipment load failed, will attempt fallback")
			equipped_restored_ = not has_equipment_weapon_ or player_.get_equipped_weapon() != null
		else:
			push_warning("[SaveManager] Player has no Equipment node")
			equipped_restored_ = false

	if not equipped_restored_:
		var equipped_weapon_uid_ := String(player_data_.get("equipped_weapon_uid", ""))
		if not equipped_weapon_uid_.is_empty():
			equipped_restored_ = inventory_.equip_weapon_by_uid(equipped_weapon_uid_)
		if not equipped_restored_:
			equipped_restored_ = player_.restore_equipped_weapon_from_save(player_data_)

	if not equipped_restored_:
		push_warning("[SaveManager] Equipped weapon could not be fully restored")

	var dialog_manager_ = _get_dialog_manager()
	if dialog_manager_ != null:
		var dialog_data_ = migrated_data_.get("dialog", {})
		dialog_manager_.from_save_dict(dialog_data_ if typeof(dialog_data_) == TYPE_DICTIONARY else {})

	var quest_manager_ = _get_quest_manager()
	if quest_manager_ != null:
		var quest_data_ = migrated_data_.get("quest", {})
		quest_manager_.from_save_dict(quest_data_ if typeof(quest_data_) == TYPE_DICTIONARY else {})

	print("[SaveManager] Load completed from: %s" % ProjectSettings.globalize_path(SAVE_FILE_PATH))
	load_completed.emit(true)
	return true


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)


func delete_save() -> bool:
	if not has_save_file():
		return true

	return DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE_PATH)) == OK


func debug_verify_save() -> Dictionary:
	var report_ := {
		"has_save_file": has_save_file(),
		"save_version": 0,
		"valid_structure": false,
		"checksum_valid": false,
		"has_equipment": false,
		"has_inventory_v2": false,
		"errors": []
	}

	if not bool(report_["has_save_file"]):
		report_["errors"].append("No save file found")
		return report_

	var data_ := _read_save_file()
	if data_.is_empty():
		report_["errors"].append("Save file is empty or invalid")
		return report_

	report_["save_version"] = int(data_.get("save_version", 0))
	var validation_errors_: Array[String] = _collect_save_validation_errors(data_, true)
	report_["valid_structure"] = validation_errors_.is_empty()
	report_["checksum_valid"] = _is_checksum_valid_for_data(data_)

	for error_ in validation_errors_:
		report_["errors"].append(error_)

	var player_data_ = data_.get("player", {})
	if typeof(player_data_) == TYPE_DICTIONARY:
		report_["has_equipment"] = player_data_.has("equipment")

	var inventory_data_ = data_.get("inventory", {})
	if typeof(inventory_data_) == TYPE_DICTIONARY:
		report_["has_inventory_v2"] = inventory_data_.has("version") and int(inventory_data_.get("version", 0)) >= 2

	return report_


func resolve_item_data(item_id_: StringName) -> ItemDataResource:
	if item_id_.is_empty():
		return null

	if item_data_by_id.is_empty():
		_refresh_resource_caches()

	return item_data_by_id.get(item_id_, null)


func resolve_gear_data(gear_id_: StringName) -> GearDataResource:
	if gear_id_.is_empty():
		return null

	if gear_data_by_id.is_empty():
		_refresh_resource_caches()

	return gear_data_by_id.get(gear_id_, null)


func resolve_weapon_data(weapon_id_: StringName) -> WeaponDataResource:
	if weapon_id_.is_empty():
		return null

	if weapon_data_by_id.is_empty():
		_refresh_resource_caches()

	return weapon_data_by_id.get(weapon_id_, null)


func resolve_rune_data(rune_id_: StringName) -> RuneDataResource:
	if rune_id_.is_empty():
		return null

	if rune_data_by_id.is_empty():
		_refresh_resource_caches()

	return rune_data_by_id.get(rune_id_, null)
#endregion

#region Helpers
func _get_player() -> Node:
	return get_tree().get_first_node_in_group("player")


func _get_dialog_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("DialogManager")


func _get_quest_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("QuestManager")


func _refresh_resource_caches() -> void:
	gear_data_by_id.clear()
	item_data_by_id.clear()
	rune_data_by_id.clear()
	weapon_data_by_id.clear()

	for gear_path_ in _collect_resource_paths(GEAR_DATA_ROOT):
		var gear_resource_ := load(gear_path_) as GearDataResource
		if gear_resource_ == null or gear_resource_.gear_id.is_empty():
			continue
		gear_data_by_id[gear_resource_.gear_id] = gear_resource_
		if not gear_resource_.item_id.is_empty():
			item_data_by_id[gear_resource_.item_id] = gear_resource_

	for item_path_ in _collect_resource_paths(ITEM_DATA_ROOT):
		var item_resource_ := load(item_path_) as ItemDataResource
		if item_resource_ == null or item_resource_.item_id.is_empty():
			continue
		item_data_by_id[item_resource_.item_id] = item_resource_

	for rune_path_ in _collect_resource_paths(RUNE_DATA_ROOT):
		var rune_resource_ := load(rune_path_) as RuneDataResource
		if rune_resource_ == null:
			continue

		var rune_id_ := rune_resource_.get_runtime_rune_id()
		if rune_id_.is_empty():
			continue

		item_data_by_id[rune_resource_.item_id] = rune_resource_
		rune_data_by_id[rune_id_] = rune_resource_

	for weapon_path_ in _collect_resource_paths(WEAPON_DATA_ROOT):
		var weapon_resource_ := load(weapon_path_) as WeaponDataResource
		if weapon_resource_ == null or weapon_resource_.weapon_id.is_empty():
			continue
		weapon_data_by_id[weapon_resource_.weapon_id] = weapon_resource_


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


func _read_save_file() -> Dictionary:
	if not has_save_file():
		return {}

	var save_file_ := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if save_file_ == null:
		return {}

	var raw_text_ := save_file_.get_as_text()
	save_file_.close()

	var parsed_ = JSON.parse_string(raw_text_)
	if typeof(parsed_) != TYPE_DICTIONARY:
		return {}

	return parsed_


func _calculate_checksum(player_data_: Dictionary, inventory_data_: Dictionary) -> String:
	var normalized_payload_ = JSON.parse_string(JSON.stringify({
		"player": player_data_,
		"inventory": inventory_data_
	}))
	if typeof(normalized_payload_) != TYPE_DICTIONARY:
		normalized_payload_ = {
			"player": player_data_,
			"inventory": inventory_data_
		}
	return _to_canonical_json(normalized_payload_).sha256_text()


func _validate_save_data(data_: Dictionary, verify_checksum_: bool) -> bool:
	return _collect_save_validation_errors(data_, verify_checksum_).is_empty()


func _collect_save_validation_errors(data_: Dictionary, verify_checksum_: bool) -> Array[String]:
	var errors_: Array[String] = []
	if typeof(data_) != TYPE_DICTIONARY:
		errors_.append("Save payload is not a Dictionary")
		return errors_

	if not data_.has("save_version"):
		errors_.append("Missing save_version")
	if not data_.has("player"):
		errors_.append("Missing player")
	if not data_.has("inventory"):
		errors_.append("Missing inventory")
	if not errors_.is_empty():
		return errors_

	var player_data_ = data_.get("player", {})
	if typeof(player_data_) != TYPE_DICTIONARY:
		errors_.append("Player payload is not a Dictionary")
		return errors_

	var inventory_data_ = data_.get("inventory", {})
	if typeof(inventory_data_) != TYPE_DICTIONARY:
		errors_.append("Inventory payload is not a Dictionary")
		return errors_

	if player_data_.has("equipment") and typeof(player_data_.get("equipment", {})) != TYPE_DICTIONARY:
		errors_.append("Equipment payload is not a Dictionary")

	if verify_checksum_ and not _is_checksum_valid_for_data(data_):
		errors_.append("Checksum mismatch")

	return errors_


func _is_checksum_valid_for_data(data_: Dictionary) -> bool:
	if typeof(data_) != TYPE_DICTIONARY:
		return false

	var save_version_: int = int(data_.get("save_version", 0))
	var checksum_: String = String(data_.get("checksum", ""))
	if checksum_.is_empty():
		return save_version_ < SAVE_VERSION

	var player_data_ = data_.get("player", {})
	var inventory_data_ = data_.get("inventory", {})
	if typeof(player_data_) != TYPE_DICTIONARY or typeof(inventory_data_) != TYPE_DICTIONARY:
		return false

	return checksum_ == _calculate_checksum(player_data_, inventory_data_)


func _to_canonical_json(value_: Variant) -> String:
	match typeof(value_):
		TYPE_DICTIONARY:
			var dictionary_ := value_ as Dictionary
			var keys_ := dictionary_.keys()
			keys_.sort_custom(func(left_, right_) -> bool:
				return String(left_) < String(right_)
			)

			var parts_: PackedStringArray = []
			for key_ in keys_:
				parts_.append("%s:%s" % [
					JSON.stringify(String(key_)),
					_to_canonical_json(dictionary_.get(key_))
				])
			return "{%s}" % ",".join(parts_)
		TYPE_ARRAY:
			var array_ := value_ as Array
			var parts_: PackedStringArray = []
			for entry_ in array_:
				parts_.append(_to_canonical_json(entry_))
			return "[%s]" % ",".join(parts_)
		_:
			return JSON.stringify(value_)


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


func _migrate_save_data(data_: Dictionary, from_version_: int) -> Dictionary:
	var migrated_data_ := data_.duplicate(true)
	if from_version_ < 1:
		return migrated_data_
	if from_version_ < 2 and not migrated_data_.has("dialog"):
		migrated_data_["dialog"] = {}
	if from_version_ < 3:
		pass
	if from_version_ < 4:
		pass
	if from_version_ < 5:
		var player_data_ = migrated_data_.get("player", {})
		if typeof(player_data_) != TYPE_DICTIONARY:
			player_data_ = {}
		if not player_data_.has("gold"):
			player_data_["gold"] = 0
		migrated_data_["player"] = player_data_
	if from_version_ < 6:
		var player_data_ = migrated_data_.get("player", {})
		if typeof(player_data_) != TYPE_DICTIONARY:
			player_data_ = {}

		var equipment_data_ = player_data_.get("equipment", {})
		if typeof(equipment_data_) != TYPE_DICTIONARY:
			equipment_data_ = _build_empty_equipment_save()
		elif equipment_data_.is_empty():
			equipment_data_ = _build_empty_equipment_save()

		if typeof(equipment_data_.get("weapon_main", null)) != TYPE_DICTIONARY:
			var legacy_weapon_data_ := _build_legacy_equipped_weapon_save(player_data_)
			if not legacy_weapon_data_.is_empty():
				equipment_data_["weapon_main"] = legacy_weapon_data_

		player_data_["_deprecated_equipped_weapon_fields"] = true
		player_data_["equipment"] = equipment_data_
		migrated_data_["player"] = player_data_
		migrated_data_["save_version"] = 6
		migrated_data_.erase("checksum")
	if from_version_ < 7:
		if not migrated_data_.has("quest") or typeof(migrated_data_.get("quest", {})) != TYPE_DICTIONARY:
			migrated_data_["quest"] = {}
		migrated_data_["save_version"] = 7
		migrated_data_.erase("checksum")
	return migrated_data_


func _build_empty_equipment_save() -> Dictionary:
	return {
		"weapon_main": null,
		"helmet": null,
		"chestplate": null,
		"leggings": null,
		"boots": null
	}


func _build_legacy_equipped_weapon_save(player_data_: Dictionary) -> Dictionary:
	if typeof(player_data_) != TYPE_DICTIONARY:
		return {}

	var equipped_weapon_id_ := String(player_data_.get("equipped_weapon_id", ""))
	if equipped_weapon_id_.is_empty():
		return {}

	return {
		"weapon_id": equipped_weapon_id_,
		"instance_uid": String(player_data_.get("equipped_weapon_uid", "")),
		"enhance_level": int(player_data_.get("equipped_weapon_enhance_level", 0)),
		"star_level": int(player_data_.get("equipped_weapon_star_level", 0)),
		"temporary_enchants": player_data_.get("equipped_weapon_temporary_enchants", []),
		"socketed_gems": player_data_.get("equipped_weapon_socketed_gems", []),
		"affixes": player_data_.get("equipped_weapon_affixes", []),
		"runes": player_data_.get("equipped_weapon_runes", [])
	}
#endregion
