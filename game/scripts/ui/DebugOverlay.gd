extends CanvasLayer

@onready var player_state_label: Label = $Root/Panel/DebugInfo/PlayerState
@onready var player_hp_label: Label = $Root/Panel/DebugInfo/PlayerHP
@onready var dummy_state_label: Label = $Root/Panel/DebugInfo/DummyState
@onready var dummy_hp_label: Label = $Root/Panel/DebugInfo/DummyHP

#region Core Lifecycle
func _ready() -> void:
	assert(player_state_label != null, "DebugOverlay requires PlayerState label")
	assert(player_hp_label != null, "DebugOverlay requires PlayerHP label")
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
		return

	var health_component_: HealthComponent = player_.get_health_component()
	player_state_label.text = "Player State: %s" % player_.get_current_state_name()
	player_hp_label.text = "Player HP: %.0f / %.0f" % [health_component_.current_hp, health_component_.max_hp]


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
