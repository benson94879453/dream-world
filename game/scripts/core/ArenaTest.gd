extends Node2D

const AffixInstanceResource = preload("res://game/scripts/data/AffixInstance.gd")
const AffixTableResource = preload("res://game/scripts/data/AffixTable.gd")
const EnemyDataResource = preload("res://game/scripts/data/EnemyData.gd")
const EnemyAIControllerResource = preload("res://game/scripts/enemies/EnemyAIController.gd")
const AttackContextResource = preload("res://game/scripts/combat/AttackContext.gd")
const DamageReceiverNode = preload("res://game/scripts/combat/DamageReceiver.gd")
const RuneInstanceResource = preload("res://game/scripts/data/RuneInstance.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")

@export var enemy_container_path: NodePath = NodePath("World/Enemies")
@export var debug_spawn_enemy_data: EnemyDataResource = preload("res://game/data/enemies/en_slime_basic.tres")
@export var debug_spawn_archer_data: EnemyDataResource = preload("res://game/data/enemies/en_goblin_archer.tres")
@export var debug_spawn_boar_data: EnemyDataResource = preload("res://game/data/enemies/en_boar.tres")
@export var debug_spawn_archer_offset: Vector2 = Vector2(160.0, 0.0)
@export var debug_spawn_boar_offset: Vector2 = Vector2(96.0, 96.0)
@export var rune_test_sample_count: int = 100
@export var shield_test_amount: float = 50.0
@export var shield_test_hit_damage: float = 10.0

var enemy_container: Node2D = null

#region Core Lifecycle
func _ready() -> void:
	enemy_container = get_node_or_null(enemy_container_path) as Node2D
	assert(enemy_container != null, "Arena_Test enemy_container_path must point to Node2D")

	var save_manager_ = get_tree().root.get_node_or_null("SaveManager")
	if save_manager_ == null:
		push_warning("[Arena_Test] SaveManager autoload is missing")
		return

	if OS.get_environment("DW_RUN_SAVE_SMOKE") == "1":
		_run_save_smoke(save_manager_)
		return

	if not save_manager_.has_save_file():
		print("[Arena_Test] No save file found, using default state")
		return

	save_manager_.load_game()


func _unhandled_input(event_: InputEvent) -> void:
	if _try_handle_rune_test_input(event_):
		return

	_try_handle_debug_enemy_spawn(event_)


func _run_save_smoke(save_manager_) -> void:
	var player_ := get_tree().get_first_node_in_group("player") as PlayerController
	if player_ == null:
		push_warning("[Arena_Test] Save smoke requires Player")
		get_tree().quit(1)
		return

	var dialog_manager_ = get_tree().root.get_node_or_null("DialogManager")
	if dialog_manager_ == null:
		push_warning("[Arena_Test] Save smoke requires DialogManager")
		get_tree().quit(1)
		return

	var rune_manager_ = get_tree().root.get_node_or_null("RuneManager")
	if rune_manager_ == null:
		push_warning("[Arena_Test] Save smoke requires RuneManager")
		get_tree().quit(1)
		return

	var health_component_ := player_.get_health_component()
	var inventory_ := player_.get_inventory()
	save_manager_.delete_save()
	dialog_manager_.from_save_dict({})

	player_.global_position = Vector2(512.0, 256.0)
	health_component_.current_hp = 37.0
	health_component_.health_changed.emit(health_component_.current_hp, health_component_.max_hp)
	inventory_.clear()
	player_.set_gold(4321)
	inventory_.add_item(player_.debug_inventory_herb_data, 7)
	inventory_.add_item(player_.debug_inventory_potion_data, 2)
	player_._debug_add_upgrade_materials()
	inventory_.add_weapon(WeaponInstanceResource.create_from_data(player_.debug_equip_slot_2))
	player_.equip_weapon_data(player_.debug_equip_slot_3)
	player_.get_equipped_weapon().star_level = 3
	var affix_table_ := load("res://game/data/affixes/affix_table_basic.tres") as AffixTableResource
	if affix_table_ != null and not affix_table_.affixes.is_empty():
		player_.get_equipped_weapon().affixes.append(AffixInstanceResource.create_from_data(affix_table_.affixes[0]))
	var rune_data_ = rune_manager_.get_rune_data(&"rune_fire")
	if rune_data_ != null and not player_.get_equipped_weapon().rune_slots.is_empty():
		player_.get_equipped_weapon().rune_slots[0].equip(RuneInstanceResource.create_from_data(rune_data_))
	dialog_manager_.set_flag(&"save_smoke_dialog_flag")

	var save_ok_ = save_manager_.save_game()
	var save_version_ := -1
	var saved_hp_ := -1.0
	var saved_gold_ := -1
	var saved_equipped_uid_ := ""
	var saved_weapon_star_level_ := -1
	var saved_affix_count_ := -1
	var saved_rune_ids_: Array = []
	var saved_dialog_flag_ := false
	var save_file_ := FileAccess.open("user://savegame.json", FileAccess.READ)
	if save_file_ != null:
		var raw_save_text_ := save_file_.get_as_text()
		save_file_.close()
		var parsed_save_ = JSON.parse_string(raw_save_text_)
		if typeof(parsed_save_) == TYPE_DICTIONARY:
			save_version_ = int(parsed_save_.get("save_version", -1))
			var saved_player_ = parsed_save_.get("player", {})
			if typeof(saved_player_) == TYPE_DICTIONARY:
				saved_hp_ = float(saved_player_.get("current_hp", -1.0))
				saved_gold_ = int(saved_player_.get("gold", -1))
				saved_equipped_uid_ = String(saved_player_.get("equipped_weapon_uid", ""))
				saved_weapon_star_level_ = int(saved_player_.get("equipped_weapon_star_level", -1))
				var saved_affixes_ = saved_player_.get("equipped_weapon_affixes", [])
				if typeof(saved_affixes_) == TYPE_ARRAY:
					saved_affix_count_ = saved_affixes_.size()
				var saved_runes_ = saved_player_.get("equipped_weapon_runes", [])
				if typeof(saved_runes_) == TYPE_ARRAY:
					saved_rune_ids_ = saved_runes_
			var saved_dialog_ = parsed_save_.get("dialog", {})
			if typeof(saved_dialog_) == TYPE_DICTIONARY:
				var saved_dialog_flags_ = saved_dialog_.get("dialog_flags", {})
				if typeof(saved_dialog_flags_) == TYPE_DICTIONARY:
					saved_dialog_flag_ = bool(saved_dialog_flags_.get("save_smoke_dialog_flag", false))

	player_.global_position = Vector2.ZERO
	health_component_.current_hp = health_component_.max_hp
	health_component_.health_changed.emit(health_component_.current_hp, health_component_.max_hp)
	player_.set_gold(0)
	inventory_.clear()
	player_.equip_weapon_data(player_.debug_equip_slot_1)
	dialog_manager_.from_save_dict({})

	var load_ok_ = save_manager_.load_game()
	var restored_dialog_flag_: bool = dialog_manager_.has_flag(&"save_smoke_dialog_flag")
	print("[SaveSmokeFile] version=%d saved_hp=%.1f equipped_uid=%s" % [
		save_version_,
		saved_hp_,
		saved_equipped_uid_
	])
	print("[SaveSmokeGold] saved=%d restored=%d" % [
		saved_gold_,
		player_.get_gold()
	])
	print("[SaveSmokeWeapon] saved_stars=%d saved_affixes=%d restored_stars=%d restored_affixes=%d" % [
		saved_weapon_star_level_,
		saved_affix_count_,
		player_.get_equipped_weapon().star_level if player_.get_equipped_weapon() != null else -1,
		player_.get_equipped_weapon().affixes.size() if player_.get_equipped_weapon() != null else -1
	])
	print("[SaveSmokeRunes] saved=%s restored=%s" % [
		str(saved_rune_ids_),
		str(player_.get_equipped_weapon().get_equipped_rune_ids() if player_.get_equipped_weapon() != null else [])
	])
	print("[SaveSmokeDialog] saved=%s restored=%s flags=%s" % [
		str(saved_dialog_flag_),
		str(restored_dialog_flag_),
		dialog_manager_.get_debug_flag_summary()
	])
	print("[SaveSmoke] save=%s load=%s pos=(%.1f, %.1f) hp=%.1f herb=%d potion=%d inventory_weapons=%d equipped=%s" % [
		str(save_ok_),
		str(load_ok_),
		player_.global_position.x,
		player_.global_position.y,
		health_component_.current_hp,
		inventory_.get_item_count(player_.debug_inventory_herb_data),
		inventory_.get_item_count(player_.debug_inventory_potion_data),
		inventory_.get_all_weapons().size(),
		player_.get_equipped_weapon_display_name()
	])

	if OS.get_environment("DW_KEEP_SAVE_SMOKE") != "1":
		save_manager_.delete_save()

	get_tree().quit(0)
#endregion

#region Helpers
func _try_handle_rune_test_input(event_: InputEvent) -> bool:
	var key_event_ := event_ as InputEventKey
	if key_event_ == null or not key_event_.pressed or key_event_.echo:
		return false

	if key_event_.physical_keycode == KEY_T:
		_toggle_rune_test_mode()
		return true

	var rune_test_manager_ = _get_rune_test_manager()
	if rune_test_manager_ == null or not rune_test_manager_.is_test_mode_enabled():
		return false

	if key_event_.physical_keycode == KEY_Y:
		_run_probability_test()
		return true

	if key_event_.physical_keycode == KEY_U:
		_run_elemental_damage_test()
		return true

	if key_event_.physical_keycode == KEY_P:
		_run_shield_absorption_test()
		return true

	return false


func _toggle_rune_test_mode() -> void:
	var rune_test_manager_ = _get_rune_test_manager()
	if rune_test_manager_ == null:
		push_warning("[Arena_Test] RuneTestManager autoload is missing")
		return

	var next_enabled_: bool = not rune_test_manager_.is_test_mode_enabled()
	rune_test_manager_.set_test_mode(next_enabled_)
	print("[RuneTest] Mode: %s" % ("ON" if next_enabled_ else "OFF"))


func _run_probability_test() -> void:
	var player_ := get_tree().get_first_node_in_group("player") as PlayerController
	var rune_manager_ = _get_rune_manager()
	var rune_test_manager_ = _get_rune_test_manager()
	if player_ == null or rune_manager_ == null or rune_test_manager_ == null:
		push_warning("[RuneTest] Missing Player, RuneManager, or RuneTestManager")
		return

	var endless_weapon_ := _build_test_weapon(player_.debug_equip_slot_2, [&"rune_endless_blade"])
	var double_weapon_ := _build_test_weapon(player_.debug_equip_slot_2, [&"rune_double_strike"])
	if endless_weapon_ == null or double_weapon_ == null:
		push_warning("[RuneTest] Failed to build test weapons for probability checks")
		return

	rune_test_manager_.simulate_probability_test(
		endless_weapon_.get_total_stat_modifier(&"cooldown_refund_chance_pct"),
		double_weapon_.get_total_stat_modifier(&"double_strike_chance_pct"),
		rune_test_sample_count
	)

	print("[RuneTest][Proc] Endless Blade: %d/%d (%.1f%%) | Double Strike: %d/%d (%.1f%%)" % [
		int(rune_test_manager_.get_stat_entry("endless_blade").get("triggers", 0)),
		int(rune_test_manager_.get_stat_entry("endless_blade").get("total", 0)),
		rune_test_manager_.get_endless_blade_rate() * 100.0,
		int(rune_test_manager_.get_stat_entry("double_strike").get("triggers", 0)),
		int(rune_test_manager_.get_stat_entry("double_strike").get("total", 0)),
		rune_test_manager_.get_double_strike_rate() * 100.0
	])


func _run_elemental_damage_test() -> void:
	var player_ := get_tree().get_first_node_in_group("player") as PlayerController
	var rune_test_manager_ = _get_rune_test_manager()
	if player_ == null or rune_test_manager_ == null:
		push_warning("[RuneTest] Missing Player or RuneTestManager for elemental test")
		return

	var base_weapon_ := _build_test_weapon(player_.debug_equip_slot_2, [])
	var elemental_weapon_ := _build_test_weapon(player_.debug_equip_slot_2, [&"rune_fire"])
	var resonance_weapon_ := _build_test_weapon(player_.debug_equip_slot_2, [&"rune_fire", &"rune_elemental_resonance"])
	if base_weapon_ == null or elemental_weapon_ == null or resonance_weapon_ == null:
		push_warning("[RuneTest] Failed to build weapons for elemental test")
		return

	var base_damage_ := _calculate_weapon_preview_damage(base_weapon_)
	var elemental_damage_ := _calculate_weapon_preview_damage(elemental_weapon_)
	var resonance_damage_ := _calculate_weapon_preview_damage(resonance_weapon_)
	rune_test_manager_.set_elemental_result(base_damage_, elemental_damage_, resonance_damage_)

	print("[RuneTest][Elemental] Base: %.1f | Fire: %.1f | Fire+Resonance: %.1f" % [
		base_damage_,
		elemental_damage_,
		resonance_damage_
	])


func _run_shield_absorption_test() -> void:
	var player_ := get_tree().get_first_node_in_group("player") as PlayerController
	var rune_test_manager_ = _get_rune_test_manager()
	if player_ == null or rune_test_manager_ == null:
		push_warning("[RuneTest] Missing Player or RuneTestManager for shield test")
		return

	var health_component_ := player_.get_health_component()
	if health_component_ == null:
		push_warning("[RuneTest] Player HealthComponent is missing")
		return

	var original_hp_: float = health_component_.current_hp
	var original_shield_: float = health_component_.temporary_hp

	health_component_.current_hp = health_component_.max_hp
	health_component_.set_temporary_hp(shield_test_amount)
	health_component_.health_changed.emit(health_component_.current_hp, health_component_.max_hp)

	var initial_shield_: float = health_component_.temporary_hp
	var initial_hp_: float = health_component_.current_hp

	health_component_.apply_damage(shield_test_hit_damage)
	var first_hit_shield_: float = health_component_.temporary_hp
	var first_hit_hp_: float = health_component_.current_hp

	for _shield_hit_index in range(int(ceil(maxf(shield_test_amount / maxf(shield_test_hit_damage, 1.0), 1.0))) - 1):
		health_component_.apply_damage(shield_test_hit_damage)

	health_component_.apply_damage(shield_test_hit_damage)
	var final_shield_: float = health_component_.temporary_hp
	var final_hp_: float = health_component_.current_hp
	var passed_: bool = is_equal_approx(first_hit_shield_, shield_test_amount - shield_test_hit_damage) \
		and is_equal_approx(first_hit_hp_, health_component_.max_hp) \
		and is_zero_approx(final_shield_) \
		and is_equal_approx(final_hp_, health_component_.max_hp - shield_test_hit_damage)

	rune_test_manager_.set_shield_result(
		initial_shield_,
		initial_hp_,
		first_hit_shield_,
		first_hit_hp_,
		final_shield_,
		final_hp_,
		shield_test_hit_damage,
		passed_
	)

	health_component_.current_hp = original_hp_
	health_component_.set_temporary_hp(original_shield_)
	health_component_.health_changed.emit(health_component_.current_hp, health_component_.max_hp)

	print("[RuneTest][Shield] Initial Shield: %.1f | After First Hit: %.1f / %.1f | Final: %.1f / %.1f | Passed=%s" % [
		initial_shield_,
		first_hit_shield_,
		first_hit_hp_,
		final_shield_,
		final_hp_,
		str(passed_)
	])


func _try_handle_debug_enemy_spawn(event_: InputEvent) -> bool:
	var key_event_ := event_ as InputEventKey
	if key_event_ == null or not key_event_.pressed or key_event_.echo:
		return false

	if key_event_.physical_keycode != KEY_F6:
		if key_event_.physical_keycode != KEY_F7:
			if key_event_.physical_keycode != KEY_F8:
				return false

	var player_ := get_tree().get_first_node_in_group("player") as PlayerController
	if player_ == null:
		push_warning("[Arena_Test] Cannot spawn debug enemy without Player")
		return true

	if key_event_.physical_keycode == KEY_F6:
		_spawn_enemy(debug_spawn_enemy_data, player_.global_position)
		return true

	if key_event_.physical_keycode == KEY_F7:
		_spawn_enemy(debug_spawn_archer_data, player_.global_position + debug_spawn_archer_offset)
		return true

	_spawn_enemy(debug_spawn_boar_data, player_.global_position + debug_spawn_boar_offset)
	return true


func _spawn_enemy(enemy_data_: EnemyDataResource, global_position_: Vector2) -> EnemyAIControllerResource:
	assert(enemy_data_ != null, "Arena_Test requires debug_spawn_enemy_data")
	assert(enemy_data_.enemy_scene != null, "Arena_Test requires EnemyData.enemy_scene")

	var enemy_ := enemy_data_.enemy_scene.instantiate() as EnemyAIControllerResource
	assert(enemy_ != null, "EnemyData.enemy_scene must instantiate EnemyAIController")

	enemy_.enemy_data = enemy_data_
	enemy_container.add_child(enemy_)
	enemy_.global_position = global_position_
	return enemy_


func _build_test_weapon(weapon_data_: WeaponData, rune_ids_: Array[StringName]) -> WeaponInstanceResource:
	if weapon_data_ == null:
		return null

	var weapon_instance_ := WeaponInstanceResource.create_from_data(weapon_data_)
	weapon_instance_.star_level = 5

	for rune_id_ in rune_ids_:
		if not _equip_rune_on_test_weapon(weapon_instance_, rune_id_):
			push_warning("[RuneTest] Could not equip rune %s on %s" % [String(rune_id_), weapon_data_.display_name])

	return weapon_instance_


func _equip_rune_on_test_weapon(weapon_instance_: WeaponInstanceResource, rune_id_: StringName) -> bool:
	var rune_manager_ = _get_rune_manager()
	if weapon_instance_ == null or rune_manager_ == null:
		return false

	var rune_data_ = rune_manager_.get_rune_data(rune_id_)
	if rune_data_ == null:
		return false

	for slot_ in weapon_instance_.rune_slots:
		if slot_ == null or not slot_.can_equip(rune_data_):
			continue
		return slot_.equip(RuneInstanceResource.create_from_data(rune_data_))

	return false


func _calculate_weapon_preview_damage(weapon_instance_: WeaponInstanceResource) -> float:
	if weapon_instance_ == null:
		return 0.0

	var attack_context_ := AttackContextResource.new()
	attack_context_.base_damage = weapon_instance_.get_base_attack()
	attack_context_.weapon_instance = weapon_instance_
	attack_context_.tags = [&"melee", weapon_instance_.weapon_data.weapon_type]
	for tag_ in weapon_instance_.get_attack_element_tags():
		if not attack_context_.tags.has(tag_):
			attack_context_.tags.append(tag_)

	return DamageReceiverNode.calculate_damage_preview(attack_context_)


func _get_rune_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("RuneManager")


func _get_rune_test_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("RuneTestManager")
#endregion
