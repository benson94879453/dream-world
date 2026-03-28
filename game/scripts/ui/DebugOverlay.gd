extends CanvasLayer

@onready var player_state_label: Label = $Root/Panel/DebugInfo/PlayerState
@onready var player_hp_label: Label = $Root/Panel/DebugInfo/PlayerHP
@onready var player_weapon_label: Label = $Root/Panel/DebugInfo/PlayerWeapon
@onready var player_attack_phase_label: Label = $Root/Panel/DebugInfo/PlayerAttackPhase
@onready var player_combo_available_label: Label = $Root/Panel/DebugInfo/PlayerComboAvailable
@onready var player_combo_queued_label: Label = $Root/Panel/DebugInfo/PlayerComboQueued
@onready var dash_cooldown_label: Label = $Root/Panel/DebugInfo/DashCooldown
@onready var inventory_usage_label: Label = $Root/Panel/DebugInfo/InventoryUsage
@onready var recent_pickup_label: Label = $Root/Panel/DebugInfo/RecentPickup
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

#region Core Lifecycle
func _ready() -> void:
	assert(player_state_label != null, "DebugOverlay requires PlayerState label")
	assert(player_hp_label != null, "DebugOverlay requires PlayerHP label")
	assert(player_weapon_label != null, "DebugOverlay requires PlayerWeapon label")
	assert(player_attack_phase_label != null, "DebugOverlay requires PlayerAttackPhase label")
	assert(player_combo_available_label != null, "DebugOverlay requires PlayerComboAvailable label")
	assert(player_combo_queued_label != null, "DebugOverlay requires PlayerComboQueued label")
	assert(dash_cooldown_label != null, "DebugOverlay requires DashCooldown label")
	assert(inventory_usage_label != null, "DebugOverlay requires InventoryUsage label")
	assert(recent_pickup_label != null, "DebugOverlay requires RecentPickup label")
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


func _process(_delta: float) -> void:
	_update_player_debug()
	_update_slime_debug()
	_update_archer_debug()
	_update_boar_debug()
#endregion

#region Helpers
func _update_player_debug() -> void:
	var player_ := get_tree().get_first_node_in_group("player") as PlayerController
	if player_ == null:
		player_state_label.text = "Player State: N/A"
		player_hp_label.text = "Player HP: N/A"
		player_weapon_label.text = "Player Weapon: N/A"
		player_attack_phase_label.text = "Attack Phase: N/A"
		player_combo_available_label.text = "Combo Ready: N/A"
		player_combo_queued_label.text = "Combo Queued: N/A"
		dash_cooldown_label.text = "Dash: N/A"
		inventory_usage_label.text = "Inventory: N/A"
		recent_pickup_label.text = "Recent Pickup: N/A"
		return

	var health_component_: HealthComponent = player_.get_health_component()
	player_state_label.text = "Player State: %s" % player_.get_current_state_name()
	player_hp_label.text = "Player HP: %.0f / %.0f" % [health_component_.current_hp, health_component_.max_hp]
	player_weapon_label.text = "Player Weapon: %s" % player_.get_equipped_weapon_display_name()
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
	recent_pickup_label.text = "Recent Pickup: %s" % player_.get_recent_pickup_summary()


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
#endregion
