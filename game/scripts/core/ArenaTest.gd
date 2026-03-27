extends Node2D

const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")

func _ready() -> void:
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


func _run_save_smoke(save_manager_) -> void:
	var player_ := get_tree().get_first_node_in_group("player") as PlayerController
	if player_ == null:
		push_warning("[Arena_Test] Save smoke requires Player")
		get_tree().quit(1)
		return

	var health_component_ := player_.get_health_component()
	var inventory_ := player_.get_inventory()
	save_manager_.delete_save()

	player_.global_position = Vector2(512.0, 256.0)
	health_component_.current_hp = 37.0
	health_component_.health_changed.emit(health_component_.current_hp, health_component_.max_hp)
	inventory_.clear()
	inventory_.add_item(player_.debug_inventory_herb_data, 7)
	inventory_.add_item(player_.debug_inventory_potion_data, 2)
	inventory_.add_weapon(WeaponInstanceResource.create_from_data(player_.debug_equip_slot_2))
	player_.equip_weapon_data(player_.debug_equip_slot_3)

	var save_ok_ = save_manager_.save_game()
	var save_version_ := -1
	var saved_hp_ := -1.0
	var saved_equipped_uid_ := ""
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
				saved_equipped_uid_ = String(saved_player_.get("equipped_weapon_uid", ""))

	player_.global_position = Vector2.ZERO
	health_component_.current_hp = health_component_.max_hp
	health_component_.health_changed.emit(health_component_.current_hp, health_component_.max_hp)
	inventory_.clear()
	player_.equip_weapon_data(player_.debug_equip_slot_1)

	var load_ok_ = save_manager_.load_game()
	print("[SaveSmokeFile] version=%d saved_hp=%.1f equipped_uid=%s" % [
		save_version_,
		saved_hp_,
		saved_equipped_uid_
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
