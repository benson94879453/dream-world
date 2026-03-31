extends Node

const GearDataResource = preload("res://game/scripts/data/GearData.gd")
const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const RuneDataResource = preload("res://game/scripts/data/RuneData.gd")
const WeaponDataResource = preload("res://game/scripts/data/WeaponData.gd")

const SAVE_VERSION: int = 8
const SAVE_FILE_PATH: String = "user://savegame.json"
const GEAR_DATA_ROOT: String = "res://game/data/gears"
const ITEM_DATA_ROOT: String = "res://game/data/items"
const RUNE_DATA_ROOT: String = "res://game/data/runes"
const WEAPON_DATA_ROOT: String = "res://game/data/weapons"
const DEFAULT_RESPAWN_SPAWN_POINT_ID: String = "Spawn_default"
const HOTBAR_SLOT_COUNT: int = 5

signal save_completed(success: bool)
signal load_completed(success: bool)

var gear_data_by_id: Dictionary = {}
var item_data_by_id: Dictionary = {}
var rune_data_by_id: Dictionary = {}
var weapon_data_by_id: Dictionary = {}
var _is_loading: bool = false

#region Core Lifecycle
func _ready() -> void:
	_refresh_resource_caches()
#endregion

#region Public
func save_game() -> bool:
	var player_: Node = _get_player()
	if player_ == null:
		push_warning("[SaveManager] Cannot save without Player")
		save_completed.emit(false)
		return false

	var inventory_ = player_.get_inventory()
	if inventory_ == null:
		push_warning("[SaveManager] Cannot save without Inventory")
		save_completed.emit(false)
		return false

	var existing_data_: Dictionary = _read_save_file()
	var created_at_ = existing_data_.get("created_at", _get_iso8601_utc_now()) if not existing_data_.is_empty() else _get_iso8601_utc_now()
	var dialog_manager_: Node = _get_dialog_manager()
	var quest_manager_: Node = _get_quest_manager()
	var hotbar_manager_: Node = _get_hotbar_manager()
	var scene_transition_manager_: Node = _get_scene_transition_manager()
	var scene_state_manager_: Node = _get_scene_state_manager()
	var zone_reset_manager_: Node = _get_zone_reset_manager()
	var player_data_: Dictionary = player_.to_save_dict()
	var inventory_data_: Dictionary = inventory_.to_save_dict()
	var hotbar_data_: Dictionary = _build_default_hotbar_save_data()
	if hotbar_manager_ != null and hotbar_manager_.has_method("to_save_dict"):
		hotbar_data_ = _normalize_hotbar_save_data(hotbar_manager_.to_save_dict())
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
		"quest": quest_manager_.to_save_dict() if quest_manager_ != null else {},
		"hotbar": hotbar_data_,
		"scene_state": scene_state_manager_.to_save_dict() if scene_state_manager_ != null else {},
		"zone_reset": zone_reset_manager_.to_save_dict() if zone_reset_manager_ != null else {},
		"respawn": _normalize_respawn_save_data(scene_transition_manager_.to_save_dict() if scene_transition_manager_ != null and scene_transition_manager_.has_method("to_save_dict") else {})
	}
	save_data_ = _finalize_save_data_for_current_version(save_data_, true)

	if not _write_save_file_data(save_data_):
		push_warning("[SaveManager] Failed to open save file for writing: %s" % SAVE_FILE_PATH)
		save_completed.emit(false)
		return false

	print("[SaveManager] Save completed: %s" % ProjectSettings.globalize_path(SAVE_FILE_PATH))
	save_completed.emit(true)
	return true


func load_game() -> bool:
	if _is_loading:
		push_warning("[SaveManager] load_game already in progress")
		load_completed.emit(false)
		return false

	_is_loading = true
	_debug_log_load_step("Starting load_game")

	if not has_save_file():
		push_warning("[SaveManager] No save file found")
		return _complete_load(false)

	var data_: Dictionary = _read_save_file()
	if data_.is_empty():
		push_warning("[SaveManager] Save file is empty or invalid")
		return _complete_load(false)

	if not _validate_save_data(data_, true):
		push_warning("[SaveManager] Save file failed validation")
		return _complete_load(false)

	var save_version_: int = int(data_.get("save_version", 0))
	var migrated_data_: Dictionary = _migrate_save_data(data_, save_version_)
	var migrated_data_changed_: bool = _did_save_data_change(data_, migrated_data_)
	migrated_data_ = _finalize_save_data_for_current_version(migrated_data_, migrated_data_changed_)
	if not _validate_save_data(migrated_data_, true, true):
		push_warning("[SaveManager] Migrated save data failed validation")
		return _complete_load(false)

	var scene_transition_manager_: Node = _get_scene_transition_manager()
	if scene_transition_manager_ != null and scene_transition_manager_.has_method("is_transitioning") and bool(scene_transition_manager_.call("is_transitioning")):
		push_warning("[SaveManager] Cannot load while a scene transition is in progress")
		return _complete_load(false)

	var respawn_data_: Dictionary = _normalize_respawn_save_data(migrated_data_.get("respawn", {}))
	if scene_transition_manager_ != null and scene_transition_manager_.has_method("from_save_dict"):
		scene_transition_manager_.from_save_dict(respawn_data_)
		_debug_log_load_step("scene_transition.from_save_dict -> done")

	var player_: Node = _get_player()
	if player_ == null:
		push_warning("[SaveManager] Cannot load without Player")
		return _complete_load(false)

	var inventory_ = player_.get_inventory()
	if inventory_ == null:
		push_warning("[SaveManager] Cannot load without Inventory")
		return _complete_load(false)

	var dialog_manager_: Node = _get_dialog_manager()
	var quest_manager_: Node = _get_quest_manager()
	var hotbar_manager_: Node = _get_hotbar_manager()
	var scene_state_manager_: Node = _get_scene_state_manager()
	var zone_reset_manager_: Node = _get_zone_reset_manager()

	_debug_log_player_runtime_state(player_, "before_reset")
	_debug_log_modal_ui_state("before_reset")
	_cancel_active_interactions_for_load(dialog_manager_)
	if player_.has_method("reset_runtime_state_for_load"):
		player_.reset_runtime_state_for_load()
	_debug_log_player_runtime_state(player_, "after_reset")
	_debug_log_modal_ui_state("after_reset")

	var inventory_data_ = migrated_data_.get("inventory", {})
	var player_data_ = migrated_data_.get("player", {})

	var inventory_loaded_: bool = inventory_.from_save_dict(inventory_data_)
	_debug_log_load_step("inventory.from_save_dict -> %s" % str(inventory_loaded_))
	var player_load_report_: Dictionary = player_.from_save_dict(player_data_)
	_debug_log_load_step("player.from_save_dict -> %s" % JSON.stringify(player_load_report_))

	var equipped_restored_: bool = true
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
		var equipped_weapon_uid_: String = String(player_data_.get("equipped_weapon_uid", ""))
		if not equipped_weapon_uid_.is_empty():
			equipped_restored_ = inventory_.equip_weapon_by_uid(equipped_weapon_uid_)
		if not equipped_restored_:
			equipped_restored_ = player_.restore_equipped_weapon_from_save(player_data_)

	if not equipped_restored_:
		push_warning("[SaveManager] Equipped weapon could not be fully restored")
	_debug_log_load_step("equipped weapon restored -> %s" % str(equipped_restored_))

	if dialog_manager_ != null:
		var dialog_data_ = migrated_data_.get("dialog", {})
		dialog_manager_.from_save_dict(dialog_data_ if typeof(dialog_data_) == TYPE_DICTIONARY else {})
		_debug_log_load_step("dialog.from_save_dict -> done")

	if quest_manager_ != null:
		var quest_data_ = migrated_data_.get("quest", {})
		var quest_loaded_: bool = quest_manager_.from_save_dict(quest_data_ if typeof(quest_data_) == TYPE_DICTIONARY else {})
		_debug_log_load_step("quest.from_save_dict -> %s" % str(quest_loaded_))

	if hotbar_manager_ != null and hotbar_manager_.has_method("from_save_dict"):
		var hotbar_data_ = migrated_data_.get("hotbar", {})
		var hotbar_loaded_: bool = hotbar_manager_.from_save_dict(hotbar_data_ if typeof(hotbar_data_) == TYPE_DICTIONARY else {})
		_debug_log_load_step("hotbar.from_save_dict -> %s" % str(hotbar_loaded_))

	if scene_state_manager_ != null:
		var scene_state_data_ = migrated_data_.get("scene_state", {})
		scene_state_manager_.from_save_dict(scene_state_data_ if typeof(scene_state_data_) == TYPE_DICTIONARY else {})
		_debug_log_load_step("scene_state.from_save_dict -> done")

	if zone_reset_manager_ != null:
		var zone_reset_data_ = migrated_data_.get("zone_reset", {})
		zone_reset_manager_.from_save_dict(zone_reset_data_ if typeof(zone_reset_data_) == TYPE_DICTIONARY else {})
		_debug_log_load_step("zone_reset.from_save_dict -> done")

	var target_scene_path_: String = String(respawn_data_.get("scene_path", "")).strip_edges()
	var target_spawn_point_id_: StringName = StringName(String(respawn_data_.get("spawn_point_id", DEFAULT_RESPAWN_SPAWN_POINT_ID)).strip_edges())
	if target_spawn_point_id_.is_empty():
		target_spawn_point_id_ = StringName(DEFAULT_RESPAWN_SPAWN_POINT_ID)

	var current_scene_path_: String = ""
	if scene_transition_manager_ != null and scene_transition_manager_.has_method("get_current_scene_path"):
		current_scene_path_ = String(scene_transition_manager_.call("get_current_scene_path")).strip_edges()

	var transitioned_to_respawn_scene_: bool = false
	if scene_transition_manager_ != null and not target_scene_path_.is_empty() and target_scene_path_ != current_scene_path_:
		_debug_log_load_step("transition_to respawn scene -> %s (%s)" % [target_scene_path_, String(target_spawn_point_id_)])
		var transition_started_: bool = bool(scene_transition_manager_.call("transition_to", target_scene_path_, target_spawn_point_id_, true))
		if transition_started_:
			transitioned_to_respawn_scene_ = true
			if scene_transition_manager_.has_method("wait_for_transition_completion"):
				await scene_transition_manager_.call("wait_for_transition_completion")
			_debug_log_load_step("respawn scene transition -> completed")
		else:
			push_warning("[SaveManager] Failed to start respawn scene transition")

	if scene_state_manager_ != null:
		if scene_state_manager_.has_method("request_reapply_current_scene_state"):
			scene_state_manager_.request_reapply_current_scene_state()
			_debug_log_load_step("scene_state.request_reapply_current_scene_state -> scheduled")
		elif scene_state_manager_.has_method("reapply_current_scene_state"):
			scene_state_manager_.reapply_current_scene_state()
			_debug_log_load_step("scene_state.reapply_current_scene_state -> immediate")

	if not transitioned_to_respawn_scene_ and scene_transition_manager_ != null and scene_transition_manager_.has_method("apply_saved_respawn"):
		var respawn_applied_: bool = bool(scene_transition_manager_.call("apply_saved_respawn", respawn_data_))
		_debug_log_load_step("scene_transition.apply_saved_respawn -> %s" % str(respawn_applied_))

	player_ = _get_player()
	_debug_log_player_runtime_state(player_, "after_restore")
	_debug_log_modal_ui_state("after_restore")
	if migrated_data_changed_:
		var migration_save_ok_: bool = _write_save_file_data(migrated_data_)
		if migration_save_ok_:
			_debug_log_load_step("Persisted migrated save as v8")
		else:
			push_warning("[SaveManager] Failed to persist migrated save data")
	print("[SaveManager] Load completed from: %s" % ProjectSettings.globalize_path(SAVE_FILE_PATH))
	return _complete_load(true)


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
		"has_hotbar": false,
		"has_respawn": false,
		"has_quest": false,
		"has_scene_state": false,
		"has_zone_reset": false,
		"errors": []
	}

	if not bool(report_["has_save_file"]):
		report_["errors"].append("No save file found")
		return report_

	var data_: Dictionary = _read_save_file()
	if data_.is_empty():
		report_["errors"].append("Save file is empty or invalid")
		return report_

	report_["save_version"] = int(data_.get("save_version", 0))
	report_["has_hotbar"] = typeof(data_.get("hotbar", null)) == TYPE_DICTIONARY
	report_["has_respawn"] = typeof(data_.get("respawn", null)) == TYPE_DICTIONARY
	report_["has_quest"] = typeof(data_.get("quest", null)) == TYPE_DICTIONARY
	report_["has_scene_state"] = typeof(data_.get("scene_state", null)) == TYPE_DICTIONARY
	report_["has_zone_reset"] = typeof(data_.get("zone_reset", null)) == TYPE_DICTIONARY
	var validation_errors_: Array[String] = _collect_save_validation_errors(
		data_,
		true,
		int(report_["save_version"]) >= SAVE_VERSION
	)
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


func _get_hotbar_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("HotbarRuntime")


func _get_scene_transition_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("SceneTransitionManager")


func _get_scene_state_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("SceneStateManager")


func _get_zone_reset_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("ZoneResetManager")


func _complete_load(success_: bool) -> bool:
	_is_loading = false
	_debug_log_load_step("load_completed.emit(%s)" % str(success_))
	load_completed.emit(success_)
	return success_


func _cancel_active_interactions_for_load(dialog_manager_: Node) -> void:
	if dialog_manager_ != null and dialog_manager_.has_method("end_dialog"):
		if _has_property(dialog_manager_, "is_dialog_active") and bool(dialog_manager_.get("is_dialog_active")):
			_debug_log_load_step("Ending active dialog before load")
		dialog_manager_.end_dialog()

	for modal_ui_ in get_tree().get_nodes_in_group("modal_ui"):
		_close_modal_ui(modal_ui_)


func _close_modal_ui(modal_ui_: Node) -> void:
	if modal_ui_ == null:
		return

	var was_visible_: bool = _has_property(modal_ui_, "visible") and bool(modal_ui_.get("visible"))
	if modal_ui_.has_method("set_inventory_open"):
		modal_ui_.call("set_inventory_open", false)
	elif modal_ui_.has_method("set_journal_open"):
		modal_ui_.call("set_journal_open", false)
	elif modal_ui_.has_method("hide_upgrade_ui"):
		modal_ui_.call("hide_upgrade_ui")
	elif modal_ui_.has_method("hide_dialog"):
		modal_ui_.call("hide_dialog")
	elif _has_property(modal_ui_, "visible"):
		modal_ui_.set("visible", false)

	if was_visible_:
		_debug_log_load_step("Closed modal UI: %s" % String(modal_ui_.get_path()))


func _debug_log_load_step(message_: String) -> void:
	print("[SaveManager][Load] %s" % message_)


func _debug_log_player_runtime_state(player_: Node, label_: String) -> void:
	if player_ == null:
		_debug_log_load_step("Player snapshot (%s): <missing player>" % label_)
		return

	var snapshot_: Dictionary = {}
	if player_.has_method("get_debug_runtime_snapshot"):
		snapshot_ = player_.call("get_debug_runtime_snapshot")

	_debug_log_load_step("Player snapshot (%s): %s" % [label_, JSON.stringify(snapshot_)])


func _debug_log_modal_ui_state(label_: String) -> void:
	var visible_modal_paths_: PackedStringArray = PackedStringArray()
	for modal_ui_ in get_tree().get_nodes_in_group("modal_ui"):
		if modal_ui_ == null:
			continue
		if not _has_property(modal_ui_, "visible") or not bool(modal_ui_.get("visible")):
			continue
		visible_modal_paths_.append(String(modal_ui_.get_path()))

	var summary_: String = "none"
	if not visible_modal_paths_.is_empty():
		summary_ = ", ".join(visible_modal_paths_)

	_debug_log_load_step("Visible modal UI (%s): %s" % [label_, summary_])


func _has_property(object_: Object, property_name_: String) -> bool:
	if object_ == null:
		return false

	for property_ in object_.get_property_list():
		if String(property_.get("name", "")) == property_name_:
			return true
	return false


func _refresh_resource_caches() -> void:
	gear_data_by_id.clear()
	item_data_by_id.clear()
	rune_data_by_id.clear()
	weapon_data_by_id.clear()

	for gear_path_ in _collect_resource_paths(GEAR_DATA_ROOT):
		var gear_resource_: GearDataResource = load(gear_path_) as GearDataResource
		if gear_resource_ == null or gear_resource_.gear_id.is_empty():
			continue
		gear_data_by_id[gear_resource_.gear_id] = gear_resource_
		if not gear_resource_.item_id.is_empty():
			item_data_by_id[gear_resource_.item_id] = gear_resource_

	for item_path_ in _collect_resource_paths(ITEM_DATA_ROOT):
		var item_resource_: ItemDataResource = load(item_path_) as ItemDataResource
		if item_resource_ == null or item_resource_.item_id.is_empty():
			continue
		item_data_by_id[item_resource_.item_id] = item_resource_

	for rune_path_ in _collect_resource_paths(RUNE_DATA_ROOT):
		var rune_resource_: RuneDataResource = load(rune_path_) as RuneDataResource
		if rune_resource_ == null:
			continue

		var rune_id_ := rune_resource_.get_runtime_rune_id()
		if rune_id_.is_empty():
			continue

		item_data_by_id[rune_resource_.item_id] = rune_resource_
		rune_data_by_id[rune_id_] = rune_resource_

	for weapon_path_ in _collect_resource_paths(WEAPON_DATA_ROOT):
		var weapon_resource_: WeaponDataResource = load(weapon_path_) as WeaponDataResource
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


func _write_save_file_data(data_: Dictionary) -> bool:
	if typeof(data_) != TYPE_DICTIONARY:
		return false

	var save_file_ := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file_ == null:
		return false

	save_file_.store_string(JSON.stringify(data_, "\t"))
	save_file_.close()
	return true


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


func _validate_save_data(data_: Dictionary, verify_checksum_: bool, require_current_schema_: bool = false) -> bool:
	return _collect_save_validation_errors(data_, verify_checksum_, require_current_schema_).is_empty()


func _collect_save_validation_errors(data_: Dictionary, verify_checksum_: bool, require_current_schema_: bool = false) -> Array[String]:
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

	if require_current_schema_:
		var required_dictionary_fields_ := {
			"dialog": "Dialog",
			"quest": "Quest",
			"hotbar": "Hotbar",
			"scene_state": "SceneState",
			"zone_reset": "ZoneReset",
			"respawn": "Respawn"
		}
		for field_name_ in required_dictionary_fields_.keys():
			if not data_.has(field_name_):
				errors_.append("Missing %s" % field_name_)
				continue

			if typeof(data_.get(field_name_, null)) != TYPE_DICTIONARY:
				errors_.append("%s payload is not a Dictionary" % String(required_dictionary_fields_[field_name_]))

		var hotbar_data_ = data_.get("hotbar", {})
		if typeof(hotbar_data_) == TYPE_DICTIONARY and not _is_valid_hotbar_save_data(hotbar_data_):
			errors_.append("Hotbar payload has invalid bindings")

		var respawn_data_ = data_.get("respawn", {})
		if typeof(respawn_data_) == TYPE_DICTIONARY and not _is_valid_respawn_save_data(respawn_data_):
			errors_.append("Respawn payload is invalid")

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
			var dictionary_: Dictionary = value_ as Dictionary
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
			var array_: Array = value_ as Array
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


func _build_default_hotbar_bindings() -> Array[int]:
	var bindings_: Array[int] = []
	bindings_.resize(HOTBAR_SLOT_COUNT)
	for hotbar_index_ in range(HOTBAR_SLOT_COUNT):
		bindings_[hotbar_index_] = -1
	return bindings_


func _build_default_hotbar_save_data() -> Dictionary:
	return {
		"bindings": _build_default_hotbar_bindings()
	}


func _normalize_hotbar_save_data(hotbar_data_: Variant) -> Dictionary:
	var normalized_data_: Dictionary = _build_default_hotbar_save_data()
	if typeof(hotbar_data_) != TYPE_DICTIONARY:
		return normalized_data_

	var raw_hotbar_data_: Dictionary = hotbar_data_ as Dictionary
	var bindings_ = raw_hotbar_data_.get("bindings", [])
	if typeof(bindings_) != TYPE_ARRAY:
		return normalized_data_

	for hotbar_index_ in range(mini(bindings_.size(), HOTBAR_SLOT_COUNT)):
		var binding_value_ = bindings_[hotbar_index_]
		if typeof(binding_value_) != TYPE_INT and typeof(binding_value_) != TYPE_FLOAT:
			continue

		normalized_data_["bindings"][hotbar_index_] = maxi(int(binding_value_), -1)

	return normalized_data_


func _build_default_respawn_save_data() -> Dictionary:
	var default_scene_path_: String = String(ProjectSettings.get_setting("application/run/main_scene", "")).strip_edges()
	return {
		"scene_path": default_scene_path_,
		"spawn_point_id": DEFAULT_RESPAWN_SPAWN_POINT_ID,
		"spawn_position": {}
	}


func _normalize_respawn_save_data(respawn_data_: Variant) -> Dictionary:
	var normalized_data_: Dictionary = _build_default_respawn_save_data()
	if typeof(respawn_data_) != TYPE_DICTIONARY:
		return normalized_data_

	var raw_respawn_data_: Dictionary = respawn_data_ as Dictionary
	var scene_path_: String = String(raw_respawn_data_.get("scene_path", "")).strip_edges()
	if scene_path_.is_empty() or not ResourceLoader.exists(scene_path_):
		return normalized_data_

	normalized_data_["scene_path"] = scene_path_

	var spawn_point_id_: String = String(raw_respawn_data_.get("spawn_point_id", DEFAULT_RESPAWN_SPAWN_POINT_ID)).strip_edges()
	normalized_data_["spawn_point_id"] = spawn_point_id_ if not spawn_point_id_.is_empty() else DEFAULT_RESPAWN_SPAWN_POINT_ID
	normalized_data_["spawn_position"] = _normalize_spawn_position_data(raw_respawn_data_.get("spawn_position", {}))
	return normalized_data_


func _normalize_spawn_position_data(position_data_: Variant) -> Dictionary:
	if typeof(position_data_) != TYPE_DICTIONARY:
		return {}

	var raw_position_data_: Dictionary = position_data_ as Dictionary
	if not raw_position_data_.has("x") or not raw_position_data_.has("y"):
		return {}

	var x_: Variant = raw_position_data_.get("x", null)
	var y_: Variant = raw_position_data_.get("y", null)
	if typeof(x_) != TYPE_INT and typeof(x_) != TYPE_FLOAT:
		return {}
	if typeof(y_) != TYPE_INT and typeof(y_) != TYPE_FLOAT:
		return {}

	return {
		"x": float(x_),
		"y": float(y_)
	}


func _is_valid_hotbar_save_data(hotbar_data_: Variant) -> bool:
	if typeof(hotbar_data_) != TYPE_DICTIONARY:
		return false

	var bindings_ = hotbar_data_.get("bindings", [])
	if typeof(bindings_) != TYPE_ARRAY or bindings_.size() != HOTBAR_SLOT_COUNT:
		return false

	for binding_value_ in bindings_:
		if typeof(binding_value_) != TYPE_INT and typeof(binding_value_) != TYPE_FLOAT:
			return false
		if int(binding_value_) < -1:
			return false

	return true


func _is_valid_respawn_save_data(respawn_data_: Variant) -> bool:
	if typeof(respawn_data_) != TYPE_DICTIONARY:
		return false

	var scene_path_: String = String(respawn_data_.get("scene_path", "")).strip_edges()
	if scene_path_.is_empty() or not ResourceLoader.exists(scene_path_):
		return false

	var spawn_point_id_: String = String(respawn_data_.get("spawn_point_id", "")).strip_edges()
	if spawn_point_id_.is_empty():
		return false

	return true


func _build_default_progression_save_data() -> Dictionary:
	return {
		"unlocked_souls": [],
		"flags": {}
	}


func _finalize_save_data_for_current_version(data_: Dictionary, touch_updated_at_: bool) -> Dictionary:
	var finalized_data_ := data_.duplicate(true)
	var now_utc_: String = _get_iso8601_utc_now()

	finalized_data_["save_version"] = SAVE_VERSION
	if String(finalized_data_.get("created_at", "")).is_empty():
		finalized_data_["created_at"] = now_utc_
	if touch_updated_at_ or String(finalized_data_.get("updated_at", "")).is_empty():
		finalized_data_["updated_at"] = now_utc_

	var player_data_ = finalized_data_.get("player", {})
	if typeof(player_data_) != TYPE_DICTIONARY:
		player_data_ = {}
	finalized_data_["player"] = player_data_

	var inventory_data_ = finalized_data_.get("inventory", {})
	if typeof(inventory_data_) != TYPE_DICTIONARY:
		inventory_data_ = {}
	finalized_data_["inventory"] = inventory_data_

	var progression_data_ = finalized_data_.get("progression", {})
	if typeof(progression_data_) != TYPE_DICTIONARY:
		progression_data_ = _build_default_progression_save_data()
	else:
		if typeof(progression_data_.get("unlocked_souls", [])) != TYPE_ARRAY:
			progression_data_["unlocked_souls"] = []
		if typeof(progression_data_.get("flags", {})) != TYPE_DICTIONARY:
			progression_data_["flags"] = {}
	finalized_data_["progression"] = progression_data_

	for section_name_ in ["dialog", "quest", "scene_state", "zone_reset"]:
		if typeof(finalized_data_.get(section_name_, {})) != TYPE_DICTIONARY:
			finalized_data_[section_name_] = {}

	finalized_data_["hotbar"] = _normalize_hotbar_save_data(finalized_data_.get("hotbar", {}))
	finalized_data_["respawn"] = _normalize_respawn_save_data(finalized_data_.get("respawn", {}))
	finalized_data_["checksum"] = _calculate_checksum(player_data_, inventory_data_)
	return finalized_data_


func _did_save_data_change(previous_data_: Dictionary, next_data_: Dictionary) -> bool:
	if typeof(previous_data_) != TYPE_DICTIONARY or typeof(next_data_) != TYPE_DICTIONARY:
		return true
	return _to_canonical_json(previous_data_) != _to_canonical_json(next_data_)


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
			var legacy_weapon_data_: Dictionary = _build_legacy_equipped_weapon_save(player_data_)
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
	if from_version_ < 8:
		# v8: persist hotbar inventory-slot bindings
		migrated_data_["hotbar"] = _normalize_hotbar_save_data(migrated_data_.get("hotbar", {}))
		if not migrated_data_.has("respawn") or typeof(migrated_data_.get("respawn", {})) != TYPE_DICTIONARY:
			migrated_data_["respawn"] = _build_default_respawn_save_data()
		migrated_data_["save_version"] = 8
		migrated_data_.erase("checksum")
	migrated_data_["hotbar"] = _normalize_hotbar_save_data(migrated_data_.get("hotbar", {}))
	migrated_data_["respawn"] = _normalize_respawn_save_data(migrated_data_.get("respawn", {}))
	if not migrated_data_.has("scene_state") or typeof(migrated_data_.get("scene_state", {})) != TYPE_DICTIONARY:
		migrated_data_["scene_state"] = {}
	if not migrated_data_.has("zone_reset") or typeof(migrated_data_.get("zone_reset", {})) != TYPE_DICTIONARY:
		migrated_data_["zone_reset"] = {}
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

	var equipped_weapon_id_: String = String(player_data_.get("equipped_weapon_id", ""))
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
