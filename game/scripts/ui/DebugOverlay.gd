extends CanvasLayer

@onready var player_state_label: Label = $Root/Panel/DebugInfo/PlayerState
@onready var player_hp_label: Label = $Root/Panel/DebugInfo/PlayerHP
@onready var player_weapon_label: Label = $Root/Panel/DebugInfo/PlayerWeapon
@onready var player_attack_phase_label: Label = $Root/Panel/DebugInfo/PlayerAttackPhase
@onready var player_combo_available_label: Label = $Root/Panel/DebugInfo/PlayerComboAvailable
@onready var player_combo_queued_label: Label = $Root/Panel/DebugInfo/PlayerComboQueued
@onready var inventory_usage_label: Label = $Root/Panel/DebugInfo/InventoryUsage
@onready var recent_pickup_label: Label = $Root/Panel/DebugInfo/RecentPickup
@onready var dummy_state_label: Label = $Root/Panel/DebugInfo/DummyState
@onready var dummy_hp_label: Label = $Root/Panel/DebugInfo/DummyHP

#region Core Lifecycle
func _ready() -> void:
	assert(player_state_label != null, "DebugOverlay requires PlayerState label")
	assert(player_hp_label != null, "DebugOverlay requires PlayerHP label")
	assert(player_weapon_label != null, "DebugOverlay requires PlayerWeapon label")
	assert(player_attack_phase_label != null, "DebugOverlay requires PlayerAttackPhase label")
	assert(player_combo_available_label != null, "DebugOverlay requires PlayerComboAvailable label")
	assert(player_combo_queued_label != null, "DebugOverlay requires PlayerComboQueued label")
	assert(inventory_usage_label != null, "DebugOverlay requires InventoryUsage label")
	assert(recent_pickup_label != null, "DebugOverlay requires RecentPickup label")
	assert(dummy_state_label != null, "DebugOverlay requires DummyState label")
	assert(dummy_hp_label != null, "DebugOverlay requires DummyHP label")


func _process(_delta: float) -> void:
	_update_player_debug()
	_update_dummy_debug()
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
	inventory_usage_label.text = "Inventory: %s" % player_.get_inventory_usage_summary()
	recent_pickup_label.text = "Recent Pickup: %s" % player_.get_recent_pickup_summary()


func _update_dummy_debug() -> void:
	var dummy_ := get_tree().get_first_node_in_group("debug_dummy") as EnemyDummy
	if dummy_ == null:
		dummy_state_label.text = "Dummy State: N/A"
		dummy_hp_label.text = "Dummy HP: N/A"
		return

	var health_component_: HealthComponent = dummy_.get_health_component()
	dummy_state_label.text = "Dummy State: %s" % dummy_.get_current_state_name()
	dummy_hp_label.text = "Dummy HP: %.0f / %.0f" % [health_component_.current_hp, health_component_.max_hp]
#endregion
