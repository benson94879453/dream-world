extends CanvasLayer

const HotbarManagerNode = preload("res://game/scripts/core/HotbarManager.gd")

@onready var player_state_label: Label = $Root/Panel/DebugInfo/PlayerState
@onready var player_hp_label: Label = $Root/Panel/DebugInfo/PlayerHP
@onready var player_weapon_label: Label = $Root/Panel/DebugInfo/PlayerWeapon
@onready var player_weapon_stars_label: Label = $Root/Panel/DebugInfo/PlayerWeaponStars
@onready var player_attack_phase_label: Label = $Root/Panel/DebugInfo/PlayerAttackPhase
@onready var player_combo_available_label: Label = $Root/Panel/DebugInfo/PlayerComboAvailable
@onready var player_combo_queued_label: Label = $Root/Panel/DebugInfo/PlayerComboQueued
@onready var dash_cooldown_label: Label = $Root/Panel/DebugInfo/DashCooldown
@onready var inventory_usage_label: Label = $Root/Panel/DebugInfo/InventoryUsage
@onready var hotbar_status_label: Label = $Root/Panel/DebugInfo/HotbarStatus
@onready var player_gold_label: Label = $Root/Panel/DebugInfo/PlayerGold
@onready var recent_pickup_label: Label = $Root/Panel/DebugInfo/RecentPickup
@onready var dialog_state_label: Label = $Root/Panel/DebugInfo/DialogState
@onready var dialog_node_label: Label = $Root/Panel/DebugInfo/DialogNode
@onready var dialog_flags_label: Label = $Root/Panel/DebugInfo/DialogFlags
@onready var slime_state_label: Label = $Root/Panel/DebugInfo/SlimeState
@onready var slime_hp_label: Label = $Root/Panel/DebugInfo/SlimeHP
@onready var slime_distance_label: Label = $Root/Panel/DebugInfo/SlimeDistance
@onready var archer_state_label: Label = $Root/Panel/DebugInfo/ArcherState
@onready var archer_hp_label: Label = $Root/Panel/DebugInfo/ArcherHP
@onready var archer_distance_label: Label = $Root/Panel/DebugInfo/ArcherDistance
@onready var archer_visibility_label: Label = $Root/Panel/DebugInfo/ArcherVisibility
@onready var boar_state_label: Label = $Root/Panel/DebugInfo/BoarState
@onready var boar_hp_label: Label = $Root/Panel/DebugInfo/BoarHP
@onready var boar_dash_cooldown_label: Label = $Root/Panel/DebugInfo/BoarDashCooldown
@onready var rune_test_title_label: Label = $Root/Panel/DebugInfo/RuneTestTitle
@onready var rune_test_mode_label: Label = $Root/Panel/DebugInfo/RuneTestMode
@onready var rune_test_endless_label: Label = $Root/Panel/DebugInfo/RuneTestEndless
@onready var rune_test_double_label: Label = $Root/Panel/DebugInfo/RuneTestDouble
@onready var rune_test_elemental_label: Label = $Root/Panel/DebugInfo/RuneTestElemental
@onready var rune_test_shield_label: Label = $Root/Panel/DebugInfo/RuneTestShield
@onready var rune_test_shield_detail_label: Label = $Root/Panel/DebugInfo/RuneTestShieldDetail

#region Core Lifecycle
func _ready() -> void:
	assert(player_state_label != null, "DebugOverlay requires PlayerState label")
	assert(player_hp_label != null, "DebugOverlay requires PlayerHP label")
	assert(player_weapon_label != null, "DebugOverlay requires PlayerWeapon label")
	assert(player_weapon_stars_label != null, "DebugOverlay requires PlayerWeaponStars label")
	assert(player_attack_phase_label != null, "DebugOverlay requires PlayerAttackPhase label")
	assert(player_combo_available_label != null, "DebugOverlay requires PlayerComboAvailable label")
	assert(player_combo_queued_label != null, "DebugOverlay requires PlayerComboQueued label")
	assert(dash_cooldown_label != null, "DebugOverlay requires DashCooldown label")
	assert(inventory_usage_label != null, "DebugOverlay requires InventoryUsage label")
	assert(hotbar_status_label != null, "DebugOverlay requires HotbarStatus label")
	assert(player_gold_label != null, "DebugOverlay requires PlayerGold label")
	assert(recent_pickup_label != null, "DebugOverlay requires RecentPickup label")
	assert(dialog_state_label != null, "DebugOverlay requires DialogState label")
	assert(dialog_node_label != null, "DebugOverlay requires DialogNode label")
	assert(dialog_flags_label != null, "DebugOverlay requires DialogFlags label")
	assert(slime_state_label != null, "DebugOverlay requires SlimeState label")
	assert(slime_hp_label != null, "DebugOverlay requires SlimeHP label")
	assert(slime_distance_label != null, "DebugOverlay requires SlimeDistance label")
	assert(archer_state_label != null, "DebugOverlay requires ArcherState label")
	assert(archer_hp_label != null, "DebugOverlay requires ArcherHP label")
	assert(archer_distance_label != null, "DebugOverlay requires ArcherDistance label")
	assert(archer_visibility_label != null, "DebugOverlay requires ArcherVisibility label")
	assert(boar_state_label != null, "DebugOverlay requires BoarState label")
	assert(boar_hp_label != null, "DebugOverlay requires BoarHP label")
	assert(boar_dash_cooldown_label != null, "DebugOverlay requires BoarDashCooldown label")
	assert(rune_test_title_label != null, "DebugOverlay requires RuneTestTitle label")
	assert(rune_test_mode_label != null, "DebugOverlay requires RuneTestMode label")
	assert(rune_test_endless_label != null, "DebugOverlay requires RuneTestEndless label")
	assert(rune_test_double_label != null, "DebugOverlay requires RuneTestDouble label")
	assert(rune_test_elemental_label != null, "DebugOverlay requires RuneTestElemental label")
	assert(rune_test_shield_label != null, "DebugOverlay requires RuneTestShield label")
	assert(rune_test_shield_detail_label != null, "DebugOverlay requires RuneTestShieldDetail label")

	_set_rune_test_labels_visible(false)

func _process(_delta: float) -> void:
	_update_player_debug()
	_update_dialog_debug()
	_update_slime_debug()
	_update_archer_debug()
	_update_boar_debug()
	_update_rune_test_debug()
#endregion

#region Helpers
func _update_player_debug() -> void:
	var player_ := get_tree().get_first_node_in_group("player") as PlayerController
	if player_ == null:
		player_state_label.text = "Player State: N/A"
		player_hp_label.text = "Player HP: N/A"
		player_weapon_label.text = "Player Weapon: N/A"
		player_weapon_stars_label.text = "Weapon Stars: N/A"
		player_attack_phase_label.text = "Attack Phase: N/A"
		player_combo_available_label.text = "Combo Ready: N/A"
		player_combo_queued_label.text = "Combo Queued: N/A"
		dash_cooldown_label.text = "Dash: N/A"
		inventory_usage_label.text = "Inventory: N/A"
		hotbar_status_label.text = "Hotbar: N/A"
		player_gold_label.text = "Gold: N/A"
		recent_pickup_label.text = "Recent Pickup: N/A"
		return

	var health_component_: HealthComponent = player_.get_health_component()
	player_state_label.text = "Player State: %s" % player_.get_current_state_name()
	if health_component_.temporary_hp > 0.0:
		player_hp_label.text = "Player HP: %.0f / %.0f + Shield %.0f" % [
			health_component_.current_hp,
			health_component_.max_hp,
			health_component_.temporary_hp
		]
	else:
		player_hp_label.text = "Player HP: %.0f / %.0f" % [health_component_.current_hp, health_component_.max_hp]
	player_weapon_label.text = "Player Weapon: %s" % player_.get_equipped_weapon_display_name()
	player_weapon_stars_label.text = "Weapon Stars: %s" % _get_star_text(player_.get_equipped_weapon().star_level if player_.get_equipped_weapon() != null else 0)
	player_attack_phase_label.text = "Attack Phase: %s" % player_.get_current_attack_phase()
	player_combo_available_label.text = "Combo Ready: %s" % ("Yes" if player_.can_current_weapon_combo() else "No")
	player_combo_queued_label.text = "Combo Queued: %s" % ("Yes" if player_.is_attack_combo_queued() else "No")
	if player_.is_dashing:
		dash_cooldown_label.text = "Dash: ACTIVE"
	elif player_.dash_cooldown_timer > 0.0:
		dash_cooldown_label.text = "Dash: %.1fs" % player_.dash_cooldown_timer
	else:
		dash_cooldown_label.text = "Dash: READY"
	inventory_usage_label.text = "Inventory: %s" % player_.get_inventory_usage_summary()
	hotbar_status_label.text = "Hotbar: %s" % _get_hotbar_summary(player_)
	player_gold_label.text = "Gold: %d" % player_.get_gold()
	recent_pickup_label.text = "Recent Pickup: %s" % player_.get_recent_pickup_summary()


func _update_dialog_debug() -> void:
	var dialog_manager_ = get_tree().root.get_node_or_null("DialogManager")
	if dialog_manager_ == null:
		dialog_state_label.text = "Dialog: N/A"
		dialog_node_label.text = "Dialog Node: N/A"
		dialog_flags_label.text = "Dialog Flags: N/A"
		return

	if dialog_manager_.is_dialog_active:
		dialog_state_label.text = "Dialog: ACTIVE (%s)" % String(dialog_manager_.get_current_dialog_id())
		dialog_node_label.text = "Dialog Node: %s" % String(dialog_manager_.get_current_node_id())
	else:
		dialog_state_label.text = "Dialog: IDLE"
		dialog_node_label.text = "Dialog Node: -"

	dialog_flags_label.text = "Dialog Flags: %s" % dialog_manager_.get_debug_flag_summary()


func _update_slime_debug() -> void:
	var slime_: EnemyAIController = _find_debug_slime()
	if slime_ == null:
		slime_state_label.text = "Slime State: N/A"
		slime_hp_label.text = "Slime HP: N/A"
		slime_distance_label.text = "Slime Distance: N/A"
		return

	var health_component_: HealthComponent = slime_.get_health_component()
	var distance_to_player_: float = slime_.get_debug_distance_to_player()
	slime_state_label.text = "Slime State: %s" % slime_.get_current_state_name()
	slime_hp_label.text = "Slime HP: %.0f / %.0f" % [health_component_.current_hp, health_component_.max_hp]
	slime_distance_label.text = "Slime Distance: %.1f" % distance_to_player_


func _update_archer_debug() -> void:
	var archer_: EnemyAIController = _find_debug_archer()
	if archer_ == null:
		archer_state_label.text = "Archer State: N/A"
		archer_hp_label.text = "Archer HP: N/A"
		archer_distance_label.text = "Archer Distance: N/A"
		archer_visibility_label.text = "Archer Can See Player: N/A"
		return

	var health_component_: HealthComponent = archer_.get_health_component()
	var distance_to_player_: float = archer_.get_debug_distance_to_player()
	archer_state_label.text = "Archer State: %s" % archer_.get_current_state_name()
	archer_hp_label.text = "Archer HP: %.0f / %.0f" % [health_component_.current_hp, health_component_.max_hp]
	archer_distance_label.text = "Archer Distance: %.1f" % distance_to_player_
	archer_visibility_label.text = "Archer Can See Player: %s" % ("Yes" if archer_.get_debug_can_see_player() else "No")


func _update_boar_debug() -> void:
	var boar_: EnemyAIController = _find_debug_boar()
	if boar_ == null:
		boar_state_label.text = "Boar State: N/A"
		boar_hp_label.text = "Boar HP: N/A"
		boar_dash_cooldown_label.text = "Boar Dash: N/A"
		return

	var health_component_: HealthComponent = boar_.get_health_component()
	boar_state_label.text = "Boar State: %s" % boar_.get_current_state_name()
	boar_hp_label.text = "Boar HP: %.0f / %.0f" % [health_component_.current_hp, health_component_.max_hp]
	if boar_.get_debug_dash_cooldown() > 0.0:
		boar_dash_cooldown_label.text = "Boar Dash: %.1fs" % boar_.get_debug_dash_cooldown()
	else:
		boar_dash_cooldown_label.text = "Boar Dash: READY"


func _update_rune_test_debug() -> void:
	var rune_test_manager_ = _get_rune_test_manager()
	if rune_test_manager_ == null:
		_set_rune_test_labels_visible(false)
		return

	var test_mode_enabled_: bool = rune_test_manager_.is_test_mode_enabled()
	_set_rune_test_labels_visible(test_mode_enabled_)
	if not test_mode_enabled_:
		return

	var endless_stat_: Dictionary = rune_test_manager_.get_stat_entry("endless_blade")
	var endless_total_: int = int(endless_stat_.get("total", 0))
	var endless_triggered_: int = int(endless_stat_.get("triggers", 0))
	var double_stat_: Dictionary = rune_test_manager_.get_stat_entry("double_strike")
	var double_total_: int = int(double_stat_.get("total", 0))
	var double_triggered_: int = int(double_stat_.get("triggers", 0))
	var elemental_result_: Dictionary = rune_test_manager_.elemental_result
	var shield_result_: Dictionary = rune_test_manager_.shield_result

	rune_test_title_label.text = "=== 符文效果測試 ==="
	rune_test_mode_label.text = "Test Mode: ON | Y=100 Rolls | U=Element | P=Shield"
	rune_test_endless_label.text = "[無盡之刃] 觸發: %d/%d (%.1f%%) | 期望: 10%%" % [
		endless_triggered_,
		endless_total_,
		rune_test_manager_.get_endless_blade_rate() * 100.0
	]
	rune_test_double_label.text = "[雙重打擊] 觸發: %d/%d (%.1f%%) | 期望: 15%%" % [
		double_triggered_,
		double_total_,
		rune_test_manager_.get_double_strike_rate() * 100.0
	]
	rune_test_elemental_label.text = "[元素共鳴] 基礎: %.1f | 火焰: %.1f (+%.0f%%) | 共鳴: %.1f (+%.0f%%)" % [
		float(elemental_result_.get("base_damage", 0.0)),
		float(elemental_result_.get("elemental_damage", 0.0)),
		float(elemental_result_.get("elemental_bonus_pct", 0.0)) * 100.0,
		float(elemental_result_.get("resonance_damage", 0.0)),
		float(elemental_result_.get("resonance_bonus_pct", 0.0)) * 100.0
	]
	rune_test_shield_label.text = "[護盾測試] 起始: Shield %.0f | HP %.0f/%.0f | hit=%.0f" % [
		float(shield_result_.get("initial_shield", 0.0)),
		float(shield_result_.get("initial_hp", 0.0)),
		_get_player_max_hp(),
		float(shield_result_.get("hit_damage", 0.0))
	]
	rune_test_shield_detail_label.text = "受擊後: Shield %.0f | HP %.0f/%.0f | 最終: Shield %.0f | HP %.0f/%.0f %s" % [
		float(shield_result_.get("first_hit_shield", 0.0)),
		float(shield_result_.get("first_hit_hp", 0.0)),
		_get_player_max_hp(),
		float(shield_result_.get("final_shield", 0.0)),
		float(shield_result_.get("final_hp", 0.0)),
		_get_player_max_hp(),
		"✓" if bool(shield_result_.get("passed", false)) else "x"
	]


func _find_debug_slime() -> EnemyAIController:
	return _find_closest_enemy_by_id(&"en_slime_basic")


func _find_debug_archer() -> EnemyAIController:
	return _find_closest_enemy_by_id(&"en_goblin_archer")


func _find_debug_boar() -> EnemyAIController:
	return _find_closest_enemy_by_id(&"en_boar")


func _find_closest_enemy_by_id(enemy_id_: StringName) -> EnemyAIController:
	var enemies_: Array[Node] = get_tree().get_nodes_in_group("debug_enemy")
	if enemies_.is_empty():
		return null

	var player_ := get_tree().get_first_node_in_group("player") as PlayerController
	var closest_enemy_: EnemyAIController = null
	var closest_distance_: float = INF

	for enemy_node_ in enemies_:
		var enemy_ := enemy_node_ as EnemyAIController
		if enemy_ == null or enemy_.get_enemy_id() != enemy_id_:
			continue

		if player_ == null:
			return enemy_

		var distance_: float = player_.global_position.distance_to(enemy_.global_position)
		if closest_enemy_ != null and distance_ >= closest_distance_:
			continue

		closest_enemy_ = enemy_
		closest_distance_ = distance_

	return closest_enemy_


func _get_star_text(star_level_: int) -> String:
	var clamped_star_level_: int = clampi(star_level_, 0, 5)
	return "★".repeat(clamped_star_level_) + "☆".repeat(5 - clamped_star_level_)


func _set_rune_test_labels_visible(visible_: bool) -> void:
	rune_test_title_label.visible = visible_
	rune_test_mode_label.visible = visible_
	rune_test_endless_label.visible = visible_
	rune_test_double_label.visible = visible_
	rune_test_elemental_label.visible = visible_
	rune_test_shield_label.visible = visible_
	rune_test_shield_detail_label.visible = visible_


func _get_rune_test_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("RuneTestManager")


func _get_hotbar_summary(player_: PlayerController) -> String:
	if player_ == null:
		return "N/A"

	var hotbar_manager_ = _get_hotbar_manager()
	var inventory_ = player_.get_inventory()
	if hotbar_manager_ == null or inventory_ == null:
		return "N/A"

	var entries_: Array[String] = []
	for hotbar_index_ in range(HotbarManagerNode.HOTBAR_SIZE):
		entries_.append("%d:%s" % [hotbar_index_ + 1, hotbar_manager_.get_slot_display_name(inventory_, hotbar_index_)])

	return " | ".join(entries_)


func _get_hotbar_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("HotbarRuntime")


func _get_player_max_hp() -> float:
	var player_ := get_tree().get_first_node_in_group("player") as PlayerController
	if player_ == null or player_.get_health_component() == null:
		return 0.0
	return player_.get_health_component().max_hp
#endregion
