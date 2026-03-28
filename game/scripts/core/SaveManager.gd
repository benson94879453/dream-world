extends Node

const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const RuneDataResource = preload("res://game/scripts/data/RuneData.gd")
const WeaponDataResource = preload("res://game/scripts/data/WeaponData.gd")

const SAVE_VERSION: int = 5
const SAVE_FILE_PATH: String = "user://savegame.json"
const ITEM_DATA_ROOT: String = "res://game/data/items"
const RUNE_DATA_ROOT: String = "res://game/data/runes"
const WEAPON_DATA_ROOT: String = "res://game/data/weapons"

signal save_completed(success: bool)
signal load_completed(success: bool)

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
	var save_data_ = {
		"save_version": SAVE_VERSION,
		"created_at": created_at_,
		"updated_at": _get_iso8601_utc_now(),
		"player": player_.to_save_dict(),
		"inventory": inventory_.to_save_dict(),
		"progression": {
			"unlocked_souls": [],
			"flags": {}
		},
		"dialog": dialog_manager_.to_save_dict() if dialog_manager_ != null else {}
	}

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

	var save_version_ := int(data_.get("save_version", 0))
	var migrated_data_ = _migrate_save_data(data_, save_version_)
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
	player_.from_save_dict(player_data_)

	var equipped_weapon_uid_ := String(player_data_.get("equipped_weapon_uid", ""))
	var equipped_restored_ := true
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

	print("[SaveManager] Load completed from: %s" % ProjectSettings.globalize_path(SAVE_FILE_PATH))
	load_completed.emit(true)
	return true


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)


func delete_save() -> bool:
	if not has_save_file():
		return true

	return DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE_PATH)) == OK


func resolve_item_data(item_id_: StringName) -> ItemDataResource:
	if item_id_.is_empty():
		return null

	if item_data_by_id.is_empty():
		_refresh_resource_caches()

	return item_data_by_id.get(item_id_, null)


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


func _refresh_resource_caches() -> void:
	item_data_by_id.clear()
	rune_data_by_id.clear()
	weapon_data_by_id.clear()

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
	return migrated_data_
#endregion
