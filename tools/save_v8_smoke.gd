extends Node

const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")

const TOWN_HUB_SCENE_PATH: String = "res://game/scenes/levels/TownHub.tscn"
const DUNGEON01_SCENE_PATH: String = "res://game/scenes/levels/Dungeon01.tscn"
const DEFAULT_RESPAWN_SPAWN_POINT_ID: StringName = &"Spawn_default"
const DUNGEON_RESPAWN_POINT_ID: StringName = &"Spawn_boss"
const SAVE_CYCLE_COUNT: int = 5
const QUEST_STATUS_ACTIVE: int = 1

var _failures: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_attach_to_root_and_run")


func _attach_to_root_and_run() -> void:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return

	if get_parent() != tree_.root:
		var current_parent_: Node = get_parent()
		if current_parent_ != null:
			current_parent_.remove_child(self)
		tree_.root.add_child(self)

	await tree_.process_frame
	await _run()


func _run() -> void:
	var exit_code_: int = 0
	if not await _boot_to_scene(TOWN_HUB_SCENE_PATH):
		exit_code_ = 1
	else:
		var save_manager_: Node = _get_singleton("SaveManager")
		if save_manager_ == null:
			_fail("SaveManager autoload is missing")
			exit_code_ = 1
		else:
			save_manager_.delete_save()
			if not await _run_v7_migration_smoke():
				exit_code_ = 1
			elif not await _run_v8_cycle_smoke():
				exit_code_ = 1

	if OS.get_environment("DW_KEEP_SAVE_SMOKE") != "1":
		var save_manager_: Node = _get_singleton("SaveManager")
		if save_manager_ != null:
			save_manager_.delete_save()

	if _failures.is_empty():
		print("[SaveV8Smoke] PASS")
	else:
		for failure_ in _failures:
			print("[SaveV8Smoke][FAIL] %s" % failure_)
		exit_code_ = 1

	get_tree().quit(exit_code_)


func _run_v7_migration_smoke() -> bool:
	print("[SaveV8Smoke] v7 -> v8 migration")
	if not await _boot_to_scene(TOWN_HUB_SCENE_PATH):
		return false

	if not _prepare_migration_state():
		return false

	var v7_save_data_: Dictionary = _build_v7_save_data()
	if v7_save_data_.is_empty():
		return false

	if not _write_user_save_data(v7_save_data_):
		_fail("Failed to write synthetic v7 save file")
		return false

	_dirty_runtime_state(false)

	var save_manager_: Node = _get_singleton("SaveManager")
	var load_ok_: bool = await save_manager_.load_game()
	await _await_process_frames(3)
	if not _check(load_ok_, "v7 save loads successfully"):
		return false

	var migrated_save_data_: Dictionary = _read_user_save_data()
	if not _check(not migrated_save_data_.is_empty(), "migrated save file can be read back"):
		return false
	if not _check(int(migrated_save_data_.get("save_version", 0)) == 8, "migrated save file is persisted as v8"):
		return false
	if not _check(_is_v8_payload_complete(migrated_save_data_), "migrated save file contains the full v8 payload"):
		return false

	var verify_report_: Dictionary = save_manager_.debug_verify_save()
	if not _check(bool(verify_report_.get("valid_structure", false)), "migrated save passes structure validation"):
		return false
	if not _check(bool(verify_report_.get("checksum_valid", false)), "migrated save checksum is valid"):
		return false

	var migrated_hotbar_data_ = migrated_save_data_.get("hotbar", {})
	if not _check(_has_default_hotbar_bindings(migrated_hotbar_data_), "v7 migration fills default hotbar bindings"):
		return false

	var migrated_respawn_data_: Dictionary = _extract_respawn_snapshot(migrated_save_data_.get("respawn", {}))
	if not _check(String(migrated_respawn_data_.get("scene_path", "")) == TOWN_HUB_SCENE_PATH, "v7 migration defaults respawn scene to TownHub"):
		return false
	if not _check(String(migrated_respawn_data_.get("spawn_point_id", "")) == String(DEFAULT_RESPAWN_SPAWN_POINT_ID), "v7 migration defaults respawn spawn point to Spawn_default"):
		return false

	var expected_snapshot_: Dictionary = _extract_expected_snapshot_from_save_data(migrated_save_data_)
	var runtime_snapshot_: Dictionary = _extract_runtime_snapshot()
	if not _check(_snapshots_match(runtime_snapshot_, expected_snapshot_), "runtime state matches migrated v8 save data"):
		return false

	return _check_player_at_respawn(DEFAULT_RESPAWN_SPAWN_POINT_ID, "migration load places the player at TownHub Spawn_default")


func _run_v8_cycle_smoke() -> bool:
	print("[SaveV8Smoke] repeated save/load cycles")
	if not await _boot_to_scene(TOWN_HUB_SCENE_PATH):
		return false
	if not await _transition_to_scene(DUNGEON01_SCENE_PATH, DEFAULT_RESPAWN_SPAWN_POINT_ID):
		return false
	if not _prepare_cycle_state():
		return false

	var save_manager_: Node = _get_singleton("SaveManager")
	for cycle_index_ in range(SAVE_CYCLE_COUNT):
		var cycle_label_: String = "Cycle %d" % [cycle_index_ + 1]
		var save_ok_: bool = save_manager_.save_game()
		if not _check(save_ok_, "%s save succeeds" % cycle_label_):
			return false

		var save_data_: Dictionary = _read_user_save_data()
		if not _check(_is_v8_payload_complete(save_data_), "%s writes a full v8 payload" % cycle_label_):
			return false

		var verify_report_: Dictionary = save_manager_.debug_verify_save()
		if not _check(bool(verify_report_.get("valid_structure", false)), "%s save passes structure validation" % cycle_label_):
			return false
		if not _check(bool(verify_report_.get("checksum_valid", false)), "%s save checksum remains valid" % cycle_label_):
			return false

		var expected_snapshot_: Dictionary = _extract_expected_snapshot_from_save_data(save_data_)
		var expect_scene_transition_: bool = cycle_index_ == 0
		if expect_scene_transition_:
			if not await _transition_to_scene(TOWN_HUB_SCENE_PATH, DEFAULT_RESPAWN_SPAWN_POINT_ID):
				return false
			if not _check(_get_current_scene_path() == TOWN_HUB_SCENE_PATH, "%s pre-load state starts from TownHub" % cycle_label_):
				return false

		_dirty_runtime_state(expect_scene_transition_)
		var load_ok_: bool = await save_manager_.load_game()
		await _await_process_frames(3)
		if not _check(load_ok_, "%s load succeeds" % cycle_label_):
			return false

		var runtime_snapshot_: Dictionary = _extract_runtime_snapshot()
		if not _check(_snapshots_match(runtime_snapshot_, expected_snapshot_), "%s restored snapshot matches saved data" % cycle_label_):
			return false

		var target_scene_path_: String = String(expected_snapshot_.get("current_scene_path", ""))
		if not _check(_get_current_scene_path() == target_scene_path_, "%s ends in the saved respawn scene" % cycle_label_):
			return false

		var expected_respawn_ = expected_snapshot_.get("respawn", {})
		var respawn_spawn_point_id_: StringName = StringName(String(expected_respawn_.get("spawn_point_id", DEFAULT_RESPAWN_SPAWN_POINT_ID)))
		if not _check_player_at_respawn(respawn_spawn_point_id_, "%s places the player at the saved respawn point" % cycle_label_):
			return false
		if expect_scene_transition_ and not _check(_get_current_scene_path() == DUNGEON01_SCENE_PATH, "%s verified cross-scene respawn back into Dungeon01" % cycle_label_):
			return false

	return true


func _prepare_migration_state() -> bool:
	var player_: PlayerController = _get_player()
	var dialog_manager_: Node = _get_singleton("DialogManager")
	var quest_manager_: Node = _get_singleton("QuestManager")
	var scene_state_manager_: Node = _get_singleton("SceneStateManager")
	var scene_transition_manager_: Node = _get_singleton("SceneTransitionManager")
	if player_ == null or dialog_manager_ == null or quest_manager_ == null or scene_state_manager_ == null or scene_transition_manager_ == null:
		_fail("Migration smoke is missing runtime dependencies")
		return false

	var inventory_ = player_.get_inventory()
	var health_component_ = player_.get_health_component()
	if inventory_ == null or health_component_ == null:
		_fail("Migration smoke requires Player inventory and health")
		return false

	dialog_manager_.from_save_dict({})
	quest_manager_.from_save_dict({})
	scene_state_manager_.from_save_dict({})
	scene_transition_manager_.from_save_dict({})

	player_.global_position = Vector2(-48.0, 24.0)
	health_component_.current_hp = 41.0
	health_component_.health_changed.emit(health_component_.current_hp, health_component_.max_hp)
	player_.set_gold(2468)
	inventory_.clear()
	inventory_.add_item(player_.debug_inventory_herb_data, 6)
	inventory_.add_item(player_.debug_inventory_potion_data, 2)
	inventory_.add_weapon(WeaponInstanceResource.create_from_data(player_.debug_equip_slot_2))
	player_.equip_weapon_data(player_.debug_equip_slot_3)
	dialog_manager_.set_flag(&"save_v8_migration_flag")
	quest_manager_.from_save_dict({
		"active_quests": [
			{
				"quest_id": "quest_kill_slime",
				"status": QUEST_STATUS_ACTIVE,
				"current_progress": 2,
				"target_amount": 5,
				"accepted_at": _build_timestamp()
			}
		],
		"completed_quests": ["quest_talk_blacksmith"]
	})

	var state_id_: String = scene_state_manager_.generate_state_id(TOWN_HUB_SCENE_PATH, "save_v8_migration_state", 0)
	scene_state_manager_.record_state(state_id_, {
		"type": "generic",
		"opened": true
	})
	return true


func _prepare_cycle_state() -> bool:
	var player_: PlayerController = _get_player()
	var dialog_manager_: Node = _get_singleton("DialogManager")
	var quest_manager_: Node = _get_singleton("QuestManager")
	var hotbar_manager_: Node = _get_singleton("HotbarRuntime")
	var scene_state_manager_: Node = _get_singleton("SceneStateManager")
	var scene_transition_manager_: Node = _get_singleton("SceneTransitionManager")
	if player_ == null or dialog_manager_ == null or quest_manager_ == null or hotbar_manager_ == null or scene_state_manager_ == null or scene_transition_manager_ == null:
		_fail("Cycle smoke is missing runtime dependencies")
		return false

	var inventory_ = player_.get_inventory()
	var health_component_ = player_.get_health_component()
	if inventory_ == null or health_component_ == null:
		_fail("Cycle smoke requires Player inventory and health")
		return false

	dialog_manager_.from_save_dict({})
	quest_manager_.from_save_dict({})
	scene_state_manager_.from_save_dict({})
	scene_transition_manager_.from_save_dict({})
	hotbar_manager_.from_save_dict({})

	player_.global_position = Vector2(160.0, 48.0)
	health_component_.current_hp = 29.0
	health_component_.health_changed.emit(health_component_.current_hp, health_component_.max_hp)
	player_.set_gold(4321)
	inventory_.clear()
	inventory_.add_item(player_.debug_inventory_herb_data, 8)
	inventory_.add_item(player_.debug_inventory_potion_data, 3)
	var inventory_weapon_ = WeaponInstanceResource.create_from_data(player_.debug_equip_slot_2)
	if not inventory_.add_weapon(inventory_weapon_):
		_fail("Cycle smoke could not add the inventory weapon")
		return false
	player_.equip_weapon_data(player_.debug_equip_slot_4)
	dialog_manager_.set_flag(&"save_v8_cycle_flag")
	quest_manager_.from_save_dict({
		"active_quests": [
			{
				"quest_id": "quest_collect_herb",
				"status": QUEST_STATUS_ACTIVE,
				"current_progress": 3,
				"target_amount": 10,
				"accepted_at": _build_timestamp()
			}
		],
		"completed_quests": ["quest_talk_blacksmith", "quest_kill_slime"]
	})

	var state_id_: String = scene_state_manager_.generate_state_id(DUNGEON01_SCENE_PATH, "save_v8_cycle_state", 0)
	scene_state_manager_.record_state(state_id_, {
		"type": "enemy",
		"dead": true
	})

	var potion_slot_index_: int = _find_inventory_slot_index_for_item(inventory_, player_.debug_inventory_potion_data)
	var inventory_weapon_slot_index_: int = _find_inventory_slot_index_for_weapon_uid(inventory_, inventory_weapon_.instance_uid)
	if potion_slot_index_ == -1 or inventory_weapon_slot_index_ == -1:
		_fail("Cycle smoke could not resolve hotbar binding slot indices")
		return false

	hotbar_manager_.bind_slot(0, potion_slot_index_, inventory_)
	hotbar_manager_.bind_slot(1, inventory_weapon_slot_index_, inventory_)
	hotbar_manager_.bind_slot(4, potion_slot_index_, inventory_)

	var respawn_position_: Vector2 = scene_transition_manager_.get_spawn_position(DUNGEON_RESPAWN_POINT_ID)
	if not _check(respawn_position_ != Vector2.ZERO, "Cycle smoke resolved the Dungeon01 respawn marker"):
		return false

	scene_transition_manager_.set_respawn_point(DUNGEON01_SCENE_PATH, DUNGEON_RESPAWN_POINT_ID, respawn_position_)
	return true


func _build_v7_save_data() -> Dictionary:
	var player_: PlayerController = _get_player()
	var dialog_manager_: Node = _get_singleton("DialogManager")
	var quest_manager_: Node = _get_singleton("QuestManager")
	var scene_state_manager_: Node = _get_singleton("SceneStateManager")
	var zone_reset_manager_: Node = _get_singleton("ZoneResetManager")
	var save_manager_: Node = _get_singleton("SaveManager")
	if player_ == null or dialog_manager_ == null or quest_manager_ == null or scene_state_manager_ == null or zone_reset_manager_ == null or save_manager_ == null:
		_fail("Failed to gather v7 save dependencies")
		return {}

	var inventory_ = player_.get_inventory()
	if inventory_ == null:
		_fail("Player inventory is missing while building the v7 save")
		return {}

	var player_data_: Dictionary = player_.to_save_dict()
	var inventory_data_: Dictionary = inventory_.to_save_dict()
	return {
		"save_version": 7,
		"created_at": _build_timestamp(),
		"updated_at": _build_timestamp(),
		"player": player_data_,
		"inventory": inventory_data_,
		"progression": {
			"unlocked_souls": [],
			"flags": {
				"save_v8_migration_smoke": true
			}
		},
		"dialog": dialog_manager_.to_save_dict(),
		"quest": quest_manager_.to_save_dict(),
		"scene_state": scene_state_manager_.to_save_dict(),
		"zone_reset": zone_reset_manager_.to_save_dict(),
		"checksum": String(save_manager_.call("_calculate_checksum", player_data_, inventory_data_))
	}


func _dirty_runtime_state(use_cross_scene_variant_: bool) -> void:
	var player_: PlayerController = _get_player()
	var dialog_manager_: Node = _get_singleton("DialogManager")
	var quest_manager_: Node = _get_singleton("QuestManager")
	var hotbar_manager_: Node = _get_singleton("HotbarRuntime")
	var scene_state_manager_: Node = _get_singleton("SceneStateManager")
	var scene_transition_manager_: Node = _get_singleton("SceneTransitionManager")
	if player_ == null or dialog_manager_ == null or quest_manager_ == null or hotbar_manager_ == null or scene_state_manager_ == null or scene_transition_manager_ == null:
		return

	var inventory_ = player_.get_inventory()
	var health_component_ = player_.get_health_component()
	if inventory_ == null or health_component_ == null:
		return

	player_.global_position = Vector2.ZERO if not use_cross_scene_variant_ else Vector2(640.0, 64.0)
	health_component_.current_hp = health_component_.max_hp
	health_component_.health_changed.emit(health_component_.current_hp, health_component_.max_hp)
	player_.set_gold(0)
	inventory_.clear()
	player_.equip_weapon_data(player_.debug_equip_slot_1)
	dialog_manager_.from_save_dict({})
	quest_manager_.from_save_dict({})
	hotbar_manager_.from_save_dict({})
	scene_state_manager_.from_save_dict({})
	scene_transition_manager_.from_save_dict({})


func _boot_to_scene(scene_path_: String) -> bool:
	var change_result_: int = get_tree().change_scene_to_file(scene_path_)
	if change_result_ != OK:
		_fail("Failed to boot into %s (error=%d)" % [scene_path_, change_result_])
		return false

	await _await_process_frames(3)
	if _get_player() == null:
		_fail("Booted scene %s but no player node was found" % scene_path_)
		return false

	_get_current_scene_path()
	return true


func _transition_to_scene(scene_path_: String, spawn_point_id_: StringName) -> bool:
	var scene_transition_manager_: Node = _get_singleton("SceneTransitionManager")
	if scene_transition_manager_ == null:
		_fail("SceneTransitionManager autoload is missing")
		return false

	var transition_started_: bool = bool(scene_transition_manager_.transition_to(scene_path_, spawn_point_id_))
	if not transition_started_:
		_fail("Failed to start transition to %s" % scene_path_)
		return false

	await scene_transition_manager_.wait_for_transition_completion()
	await _await_process_frames(3)
	return _check(_get_current_scene_path() == scene_path_, "Transition completed into %s" % scene_path_)


func _await_process_frames(frame_count_: int) -> void:
	for _frame_index_ in range(maxi(frame_count_, 1)):
		await get_tree().process_frame


func _extract_expected_snapshot_from_save_data(save_data_: Dictionary) -> Dictionary:
	return {
		"current_scene_path": String(save_data_.get("respawn", {}).get("scene_path", "")),
		"player": _sanitize_player_save_data(save_data_.get("player", {})),
		"inventory": _safe_dictionary(save_data_.get("inventory", {})),
		"dialog": _safe_dictionary(save_data_.get("dialog", {})),
		"quest": _safe_dictionary(save_data_.get("quest", {})),
		"hotbar": _safe_dictionary(save_data_.get("hotbar", {})),
		"scene_state": _safe_dictionary(save_data_.get("scene_state", {})),
		"zone_reset": _safe_dictionary(save_data_.get("zone_reset", {})),
		"respawn": _extract_respawn_snapshot(save_data_.get("respawn", {}))
	}


func _extract_runtime_snapshot() -> Dictionary:
	var player_: PlayerController = _get_player()
	var dialog_manager_: Node = _get_singleton("DialogManager")
	var quest_manager_: Node = _get_singleton("QuestManager")
	var hotbar_manager_: Node = _get_singleton("HotbarRuntime")
	var scene_state_manager_: Node = _get_singleton("SceneStateManager")
	var zone_reset_manager_: Node = _get_singleton("ZoneResetManager")
	var scene_transition_manager_: Node = _get_singleton("SceneTransitionManager")
	if player_ == null or dialog_manager_ == null or quest_manager_ == null or hotbar_manager_ == null or scene_state_manager_ == null or zone_reset_manager_ == null or scene_transition_manager_ == null:
		return {}

	var inventory_ = player_.get_inventory()
	if inventory_ == null:
		return {}

	return {
		"current_scene_path": _get_current_scene_path(),
		"player": _sanitize_player_save_data(player_.to_save_dict()),
		"inventory": inventory_.to_save_dict(),
		"dialog": dialog_manager_.to_save_dict(),
		"quest": quest_manager_.to_save_dict(),
		"hotbar": hotbar_manager_.to_save_dict(),
		"scene_state": scene_state_manager_.to_save_dict(),
		"zone_reset": zone_reset_manager_.to_save_dict(),
		"respawn": _extract_respawn_snapshot(scene_transition_manager_.to_save_dict())
	}


func _sanitize_player_save_data(player_data_: Variant) -> Dictionary:
	var safe_player_data_: Dictionary = _safe_dictionary(player_data_)
	safe_player_data_.erase("global_position")
	return safe_player_data_


func _extract_respawn_snapshot(respawn_data_: Variant) -> Dictionary:
	var safe_respawn_data_: Dictionary = _safe_dictionary(respawn_data_)
	return {
		"scene_path": String(safe_respawn_data_.get("scene_path", "")).strip_edges(),
		"spawn_point_id": String(safe_respawn_data_.get("spawn_point_id", "")).strip_edges()
	}


func _build_default_hotbar_save_data() -> Dictionary:
	var bindings_: Array[int] = []
	bindings_.resize(5)
	for hotbar_index_ in range(5):
		bindings_[hotbar_index_] = -1

	return {
		"bindings": bindings_
	}


func _has_default_hotbar_bindings(hotbar_data_: Variant) -> bool:
	var safe_hotbar_data_: Dictionary = _safe_dictionary(hotbar_data_)
	var bindings_ = safe_hotbar_data_.get("bindings", [])
	if typeof(bindings_) != TYPE_ARRAY or bindings_.size() != 5:
		return false

	for binding_value_ in bindings_:
		if int(binding_value_) != -1:
			return false

	return true


func _snapshots_match(left_: Variant, right_: Variant) -> bool:
	return _to_canonical_json(_normalize_json_value(left_)) == _to_canonical_json(_normalize_json_value(right_))


func _is_v8_payload_complete(save_data_: Dictionary) -> bool:
	if typeof(save_data_) != TYPE_DICTIONARY:
		return false
	if int(save_data_.get("save_version", 0)) != 8:
		return false

	for required_field_ in ["player", "inventory", "dialog", "quest", "hotbar", "scene_state", "zone_reset", "respawn"]:
		if typeof(save_data_.get(required_field_, null)) != TYPE_DICTIONARY:
			return false

	var hotbar_data_ = save_data_.get("hotbar", {})
	var bindings_ = hotbar_data_.get("bindings", [])
	if typeof(bindings_) != TYPE_ARRAY or bindings_.size() != 5:
		return false

	var respawn_data_ = save_data_.get("respawn", {})
	return not String(respawn_data_.get("scene_path", "")).strip_edges().is_empty() \
		and not String(respawn_data_.get("spawn_point_id", "")).strip_edges().is_empty()


func _check_player_at_respawn(spawn_point_id_: StringName, message_: String) -> bool:
	var scene_transition_manager_: Node = _get_singleton("SceneTransitionManager")
	var player_: PlayerController = _get_player()
	if scene_transition_manager_ == null or player_ == null:
		_fail("%s (missing runtime nodes)" % message_)
		return false

	var expected_position_: Vector2 = scene_transition_manager_.get_spawn_position(spawn_point_id_)
	if expected_position_ == Vector2.ZERO:
		_fail("%s (spawn point %s resolved to Vector2.ZERO)" % [message_, String(spawn_point_id_)])
		return false

	return _check(player_.global_position.distance_to(expected_position_) <= 0.5, message_)


func _read_user_save_data() -> Dictionary:
	var save_file_ := FileAccess.open("user://savegame.json", FileAccess.READ)
	if save_file_ == null:
		return {}

	var raw_text_: String = save_file_.get_as_text()
	save_file_.close()

	var parsed_ = JSON.parse_string(raw_text_)
	if typeof(parsed_) != TYPE_DICTIONARY:
		return {}

	return parsed_


func _write_user_save_data(data_: Dictionary) -> bool:
	var save_file_ := FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if save_file_ == null:
		return false

	save_file_.store_string(JSON.stringify(data_, "\t"))
	save_file_.close()
	return true


func _find_inventory_slot_index_for_item(inventory_, item_data_) -> int:
	if inventory_ == null or item_data_ == null:
		return -1

	for slot_index_ in range(inventory_.slots.size()):
		var slot_ = inventory_.get_slot(slot_index_)
		if slot_ == null or slot_.item_data == null:
			continue
		if slot_.item_data.item_id != item_data_.item_id:
			continue
		return slot_index_

	return -1


func _find_inventory_slot_index_for_weapon_uid(inventory_, weapon_uid_: String) -> int:
	if inventory_ == null or weapon_uid_.is_empty():
		return -1

	for slot_index_ in range(inventory_.slots.size()):
		var slot_ = inventory_.get_slot(slot_index_)
		if slot_ == null or slot_.weapon_instance == null:
			continue
		if slot_.weapon_instance.instance_uid == weapon_uid_:
			return slot_index_

	return -1


func _get_current_scene_path() -> String:
	var scene_transition_manager_: Node = _get_singleton("SceneTransitionManager")
	if scene_transition_manager_ != null and scene_transition_manager_.has_method("get_current_scene_path"):
		return String(scene_transition_manager_.get_current_scene_path()).strip_edges()

	if get_tree().current_scene == null:
		return ""

	return get_tree().current_scene.scene_file_path


func _get_player() -> PlayerController:
	return get_tree().get_first_node_in_group("player")


func _get_singleton(node_name_: String) -> Node:
	var root_ = get_tree().root
	if root_ == null:
		return null
	return root_.get_node_or_null(node_name_)


func _build_timestamp() -> String:
	var datetime_ := Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02dT%02d:%02d:%02dZ" % [
		int(datetime_.get("year", 1970)),
		int(datetime_.get("month", 1)),
		int(datetime_.get("day", 1)),
		int(datetime_.get("hour", 0)),
		int(datetime_.get("minute", 0)),
		int(datetime_.get("second", 0))
	]


func _safe_dictionary(value_: Variant) -> Dictionary:
	if typeof(value_) != TYPE_DICTIONARY:
		return {}
	return (value_ as Dictionary).duplicate(true)


func _normalize_json_value(value_: Variant) -> Variant:
	var normalized_value_ = JSON.parse_string(JSON.stringify(value_))
	if normalized_value_ == null and value_ != null:
		return value_
	return normalized_value_


func _check(condition_: bool, message_: String) -> bool:
	if condition_:
		print("[SaveV8Smoke][OK] %s" % message_)
		return true

	_fail(message_)
	return false


func _fail(message_: String) -> void:
	print("[SaveV8Smoke][FAIL] %s" % message_)
	_failures.append(message_)


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
