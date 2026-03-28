class_name WeaponUpgradeUI
extends CanvasLayer

const DECOMPOSE_MANAGER_PATH: NodePath = NodePath("/root/DecomposeManager")
const DIALOG_MANAGER_PATH: NodePath = NodePath("/root/DialogManager")
const UPGRADE_MANAGER_PATH: NodePath = NodePath("/root/UpgradeManager")
const InventoryResource = preload("res://game/scripts/inventory/Inventory.gd")
const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const RuneSocketUIResource = preload("res://game/scripts/ui/RuneSocketUI.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")

@export var open_action_id: StringName = &"open_weapon_upgrade"
@export var close_action: StringName = &"ui_cancel"

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/TitleLabel
@onready var gold_label: Label = $Panel/GoldLabel
@onready var tab_container: TabContainer = $Panel/TabContainer
@onready var weapon_icon: TextureRect = $Panel/TabContainer/Upgrade/UpgradeContent/WeaponSummary/WeaponIcon
@onready var weapon_name_label: Label = $Panel/TabContainer/Upgrade/UpgradeContent/WeaponSummary/WeaponNameLabel
@onready var star_label: Label = $Panel/TabContainer/Upgrade/UpgradeContent/Stats/StarLabel
@onready var attack_label: Label = $Panel/TabContainer/Upgrade/UpgradeContent/Stats/AttackLabel
@onready var rune_slots_label: Label = $Panel/TabContainer/Upgrade/UpgradeContent/Stats/RuneSlotsLabel
@onready var affixes_label: Label = $Panel/TabContainer/Upgrade/UpgradeContent/Columns/AffixesLabel
@onready var materials_label: Label = $Panel/TabContainer/Upgrade/UpgradeContent/Columns/MaterialsLabel
@onready var status_label: Label = $Panel/TabContainer/Upgrade/UpgradeContent/StatusLabel
@onready var upgrade_button: Button = $Panel/TabContainer/Upgrade/UpgradeContent/Buttons/UpgradeButton
@onready var rune_socket_ui: RuneSocketUIResource = $Panel/TabContainer/Runes/Margin/RuneSocketUI
@onready var decompose_gold_label: Label = $Panel/TabContainer/Decompose/DecomposeContent/RewardColumns/DecomposeGoldLabel
@onready var decompose_materials_label: Label = $Panel/TabContainer/Decompose/DecomposeContent/RewardColumns/DecomposeMaterialsLabel
@onready var decompose_bonus_label: Label = $Panel/TabContainer/Decompose/DecomposeContent/RewardColumns/DecomposeBonusLabel
@onready var decompose_status_label: Label = $Panel/TabContainer/Decompose/DecomposeContent/StatusLabel
@onready var decompose_button: Button = $Panel/TabContainer/Decompose/DecomposeContent/Buttons/DecomposeButton
@onready var decompose_confirm_dialog: ConfirmationDialog = $Panel/DecomposeConfirmDialog
@onready var close_button: Button = $Panel/CloseButton

var tracked_inventory: InventoryResource = null
var tracked_player: Node = null

#region Core Lifecycle
func _ready() -> void:
	assert(panel != null, "WeaponUpgradeUI requires Panel")
	assert(title_label != null, "WeaponUpgradeUI requires TitleLabel")
	assert(gold_label != null, "WeaponUpgradeUI requires GoldLabel")
	assert(tab_container != null, "WeaponUpgradeUI requires TabContainer")
	assert(weapon_icon != null, "WeaponUpgradeUI requires WeaponIcon")
	assert(weapon_name_label != null, "WeaponUpgradeUI requires WeaponNameLabel")
	assert(star_label != null, "WeaponUpgradeUI requires StarLabel")
	assert(attack_label != null, "WeaponUpgradeUI requires AttackLabel")
	assert(rune_slots_label != null, "WeaponUpgradeUI requires RuneSlotsLabel")
	assert(affixes_label != null, "WeaponUpgradeUI requires AffixesLabel")
	assert(materials_label != null, "WeaponUpgradeUI requires MaterialsLabel")
	assert(status_label != null, "WeaponUpgradeUI requires StatusLabel")
	assert(upgrade_button != null, "WeaponUpgradeUI requires UpgradeButton")
	assert(rune_socket_ui != null, "WeaponUpgradeUI requires RuneSocketUI")
	assert(decompose_gold_label != null, "WeaponUpgradeUI requires DecomposeGoldLabel")
	assert(decompose_materials_label != null, "WeaponUpgradeUI requires DecomposeMaterialsLabel")
	assert(decompose_bonus_label != null, "WeaponUpgradeUI requires DecomposeBonusLabel")
	assert(decompose_status_label != null, "WeaponUpgradeUI requires DecomposeStatusLabel")
	assert(decompose_button != null, "WeaponUpgradeUI requires DecomposeButton")
	assert(decompose_confirm_dialog != null, "WeaponUpgradeUI requires DecomposeConfirmDialog")
	assert(close_button != null, "WeaponUpgradeUI requires CloseButton")

	add_to_group("modal_ui")
	visible = false
	panel.visible = false
	tab_container.tab_changed.connect(_on_tab_changed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	decompose_button.pressed.connect(_on_decompose_pressed)
	decompose_confirm_dialog.confirmed.connect(_on_decompose_confirmed)
	close_button.pressed.connect(hide_upgrade_ui)

	var dialog_manager_ = _get_dialog_manager()
	if dialog_manager_ != null:
		dialog_manager_.dialog_action_requested.connect(_on_dialog_action_requested)

	var upgrade_manager_ = _get_upgrade_manager()
	if upgrade_manager_ != null:
		upgrade_manager_.upgrade_succeeded.connect(_on_upgrade_succeeded)
		upgrade_manager_.upgrade_failed.connect(_on_upgrade_failed)

	_connect_inventory_signals()
	_connect_player_signals()
#endregion

#region Core Lifecycle (Input)
func _unhandled_input(event_: InputEvent) -> void:
	if not visible:
		return

	var key_event_ := event_ as InputEventKey
	if key_event_ != null and key_event_.echo:
		return

	if event_.is_action_pressed(String(close_action)):
		hide_upgrade_ui()
		get_viewport().set_input_as_handled()
#endregion

#region Public
func open_for_current_weapon() -> void:
	var player_ = _get_player()
	var weapon_: WeaponInstanceResource = player_.get_equipped_weapon() if player_ != null else null
	if weapon_ == null:
		status_label.text = "目前沒有裝備武器。"
		return

	_connect_inventory_signals()
	_connect_player_signals()
	visible = true
	panel.visible = true
	title_label.text = "鐵匠武器升級"
	tab_container.current_tab = 0
	_set_player_locked(true)
	_refresh_view()


func hide_upgrade_ui() -> void:
	visible = false
	panel.visible = false
	status_label.text = ""
	decompose_status_label.text = ""
	_set_player_locked(false)
#endregion

#region Helpers
func _refresh_view() -> void:
	var player_ = _get_player()
	var weapon_: WeaponInstanceResource = player_.get_equipped_weapon() if player_ != null else null
	var inventory_: InventoryResource = player_.get_inventory() if player_ != null else null
	var upgrade_manager_ = _get_upgrade_manager()
	var decompose_manager_ = _get_decompose_manager()

	gold_label.text = "持有金幣：%d" % (player_.get_gold() if player_ != null else 0)
	rune_socket_ui.setup(weapon_, inventory_)

	if weapon_ == null or upgrade_manager_ == null:
		weapon_name_label.text = "未裝備武器"
		weapon_icon.texture = null
		star_label.text = "星級：-----"
		attack_label.text = "攻擊力：N/A"
		rune_slots_label.text = "符文槽：N/A"
		affixes_label.text = "詞綴：\n- 無"
		materials_label.text = "材料：\n- N/A"
		upgrade_button.disabled = true
		_refresh_decompose_preview({}, "目前沒有可分解的武器。")
		return

	var preview_: Dictionary = upgrade_manager_.get_upgrade_preview(weapon_)
	weapon_name_label.text = String(preview_.get("weapon_name", weapon_.weapon_data.display_name))
	weapon_icon.texture = weapon_.weapon_data.weapon_sprite_texture
	star_label.text = "星級：%s" % _get_star_text(weapon_.star_level)
	attack_label.text = "攻擊力：%.1f -> %.1f (%.0f%% -> %.0f%%)" % [
		float(preview_.get("current_attack", 0.0)),
		float(preview_.get("next_attack", 0.0)),
		float(preview_.get("current_attack_bonus_pct", 0.0)) * 100.0,
		float(preview_.get("next_attack_bonus_pct", 0.0)) * 100.0
	]
	rune_slots_label.text = "符文槽：%d -> %d" % [
		int(preview_.get("current_rune_slots", weapon_.get_max_rune_slots())),
		int(preview_.get("next_rune_slots", weapon_.get_max_rune_slots()))
	]
	affixes_label.text = _build_affix_summary(weapon_)
	materials_label.text = _build_material_summary(preview_.get("costs", []), inventory_)

	var failure_reason_: String = upgrade_manager_.get_upgrade_failure_reason(weapon_, inventory_)
	upgrade_button.disabled = not failure_reason_.is_empty()
	status_label.text = "準備就緒。" if failure_reason_.is_empty() else failure_reason_

	if decompose_manager_ == null:
		_refresh_decompose_preview({}, "DecomposeManager 尚未就緒。")
		return

	var decompose_reason_: String = decompose_manager_.get_decompose_failure_reason(weapon_, inventory_)
	var decompose_preview_: Dictionary = decompose_manager_.get_decompose_reward_preview(weapon_)
	_refresh_decompose_preview(decompose_preview_, decompose_reason_)


func _build_affix_summary(weapon_: WeaponInstanceResource) -> String:
	if weapon_ == null or weapon_.affixes.is_empty():
		return "詞綴：\n- 尚未獲得詞綴"

	var lines_: PackedStringArray = PackedStringArray(["詞綴："])
	for affix_ in weapon_.affixes:
		if affix_ == null:
			continue
		lines_.append("- %s：%s" % [affix_.affix_name, affix_.description])

	return "\n".join(lines_)


func _build_material_summary(costs_: Array, inventory_: InventoryResource) -> String:
	if costs_.is_empty():
		return "材料：\n- 已達最高星級"

	var save_manager_ = _get_save_manager()
	var lines_: PackedStringArray = PackedStringArray(["材料："])
	for cost_entry_ in costs_:
		if typeof(cost_entry_) != TYPE_DICTIONARY:
			continue

		var item_id_: StringName = StringName(String(cost_entry_.get("item_id", "")))
		var amount_: int = int(cost_entry_.get("amount", 0))
		var item_data_: ItemDataResource = save_manager_.resolve_item_data(item_id_) if save_manager_ != null else null
		var current_count_: int = inventory_.get_item_count(item_data_) if inventory_ != null and item_data_ != null else 0
		var item_name_: String = item_data_.display_name if item_data_ != null else String(item_id_)
		lines_.append("- %s %d / %d" % [item_name_, current_count_, amount_])

	return "\n".join(lines_)


func _build_reward_summary(entries_: Array, empty_text_: String) -> String:
	var lines_: PackedStringArray = PackedStringArray()
	for entry_ in entries_:
		if typeof(entry_) != TYPE_DICTIONARY:
			continue
		var item_data_ := entry_.get("item_data", null) as ItemDataResource
		var amount_: int = int(entry_.get("amount", 0))
		if item_data_ == null or amount_ <= 0:
			continue
		lines_.append("- %s x%d" % [item_data_.display_name, amount_])

	return "\n".join(lines_) if not lines_.is_empty() else empty_text_


func _build_chance_reward_summary(entries_: Array) -> String:
	if entries_.is_empty():
		return "額外機率獎勵：\n- 無"

	var lines_: PackedStringArray = PackedStringArray(["額外機率獎勵："])
	for entry_ in entries_:
		if typeof(entry_) != TYPE_DICTIONARY:
			continue

		var item_data_ := entry_.get("item_data", null) as ItemDataResource
		var item_name_: String = item_data_.display_name if item_data_ != null else String(entry_.get("label", ""))
		var amount_: int = int(entry_.get("amount", 0))
		var chance_: float = float(entry_.get("chance", 0.0)) * 100.0
		if item_name_.is_empty() or amount_ <= 0 or chance_ <= 0.0:
			continue

		lines_.append("- %s x%d (%.0f%%)" % [item_name_, amount_, chance_])

	return "\n".join(lines_)


func _refresh_decompose_preview(preview_: Dictionary, failure_reason_: String) -> void:
	decompose_gold_label.text = "分解可得金幣：%d" % int(preview_.get("gold", 0))
	decompose_materials_label.text = "固定素材：\n%s" % _build_reward_summary(preview_.get("items", []), "- 無")
	decompose_bonus_label.text = _build_chance_reward_summary(preview_.get("chance_items", []))
	decompose_button.disabled = not failure_reason_.is_empty()
	decompose_status_label.text = "確認後會直接分解目前裝備武器。" if failure_reason_.is_empty() else failure_reason_


func _get_star_text(star_level_: int) -> String:
	var clamped_star_level_: int = clampi(star_level_, 0, 5)
	return "★".repeat(clamped_star_level_) + "☆".repeat(5 - clamped_star_level_)


func _on_dialog_action_requested(action_id_: StringName) -> void:
	if action_id_ != open_action_id:
		return

	call_deferred("open_for_current_weapon")


func _on_tab_changed(tab_index_: int) -> void:
	if not visible:
		return

	if tab_index_ == 1:
		var player_ = _get_player()
		var weapon_: WeaponInstanceResource = player_.get_equipped_weapon() if player_ != null else null
		var inventory_: InventoryResource = player_.get_inventory() if player_ != null else null
		rune_socket_ui.setup(weapon_, inventory_)
		return

	if tab_index_ == 2:
		_refresh_view()


func _on_upgrade_pressed() -> void:
	var player_ = _get_player()
	if player_ == null:
		return

	var weapon_: WeaponInstanceResource = player_.get_equipped_weapon()
	var inventory_: InventoryResource = player_.get_inventory()
	var upgrade_manager_ = _get_upgrade_manager()
	if weapon_ == null or inventory_ == null or upgrade_manager_ == null:
		return

	upgrade_manager_.upgrade_weapon(weapon_, inventory_)


func _on_upgrade_succeeded(_weapon_, new_affix_) -> void:
	if not visible:
		return

	_refresh_view()
	if new_affix_ == null:
		status_label.text = "升級成功。"
	else:
		status_label.text = "升級成功，獲得詞綴：%s" % new_affix_.affix_name


func _on_upgrade_failed(_weapon_, reason_: String) -> void:
	if not visible:
		return

	_refresh_view()
	status_label.text = reason_


func _on_decompose_pressed() -> void:
	var player_ = _get_player()
	if player_ == null:
		return

	var weapon_: WeaponInstanceResource = player_.get_equipped_weapon()
	var inventory_: InventoryResource = player_.get_inventory()
	var decompose_manager_ = _get_decompose_manager()
	if weapon_ == null or inventory_ == null or decompose_manager_ == null:
		return

	var failure_reason_: String = decompose_manager_.get_decompose_failure_reason(weapon_, inventory_)
	if not failure_reason_.is_empty():
		_refresh_view()
		decompose_status_label.text = failure_reason_
		return

	var preview_: Dictionary = decompose_manager_.get_decompose_reward_preview(weapon_)
	decompose_confirm_dialog.dialog_text = "確定要分解 %s 嗎？\n可得 %d 金幣。\n%s" % [
		weapon_.weapon_data.display_name,
		int(preview_.get("gold", 0)),
		_build_reward_summary(preview_.get("items", []), "- 無")
	]
	decompose_confirm_dialog.popup_centered()


func _on_decompose_confirmed() -> void:
	var player_ = _get_player()
	if player_ == null:
		return

	var weapon_: WeaponInstanceResource = player_.get_equipped_weapon()
	var inventory_: InventoryResource = player_.get_inventory()
	var decompose_manager_ = _get_decompose_manager()
	if weapon_ == null or inventory_ == null or decompose_manager_ == null:
		return

	var result_: Dictionary = decompose_manager_.decompose_weapon(weapon_, inventory_)
	if not bool(result_.get("success", false)):
		_refresh_view()
		decompose_status_label.text = String(result_.get("reason", "分解失敗。"))
		return

	_refresh_view()
	decompose_status_label.text = "分解完成，獲得 %d 金幣與素材。" % int(result_.get("gold", 0))


func _connect_inventory_signals() -> void:
	var player_ = _get_player()
	var inventory_: InventoryResource = player_.get_inventory() if player_ != null else null
	if inventory_ == tracked_inventory:
		return

	if tracked_inventory != null:
		_disconnect_inventory_signals(tracked_inventory)

	tracked_inventory = inventory_
	if tracked_inventory == null:
		return

	if not tracked_inventory.slot_changed.is_connected(_on_inventory_changed):
		tracked_inventory.slot_changed.connect(_on_inventory_changed)
	if not tracked_inventory.item_added.is_connected(_on_inventory_item_amount_changed):
		tracked_inventory.item_added.connect(_on_inventory_item_amount_changed)
	if not tracked_inventory.item_removed.is_connected(_on_inventory_item_amount_changed):
		tracked_inventory.item_removed.connect(_on_inventory_item_amount_changed)


func _disconnect_inventory_signals(inventory_: InventoryResource) -> void:
	if inventory_ == null:
		return

	if inventory_.slot_changed.is_connected(_on_inventory_changed):
		inventory_.slot_changed.disconnect(_on_inventory_changed)
	if inventory_.item_added.is_connected(_on_inventory_item_amount_changed):
		inventory_.item_added.disconnect(_on_inventory_item_amount_changed)
	if inventory_.item_removed.is_connected(_on_inventory_item_amount_changed):
		inventory_.item_removed.disconnect(_on_inventory_item_amount_changed)


func _connect_player_signals() -> void:
	var player_ = _get_player()
	if player_ == tracked_player:
		return

	if tracked_player != null and tracked_player.gold_changed.is_connected(_on_player_gold_changed):
		tracked_player.gold_changed.disconnect(_on_player_gold_changed)

	tracked_player = player_
	if tracked_player == null:
		return

	if not tracked_player.gold_changed.is_connected(_on_player_gold_changed):
		tracked_player.gold_changed.connect(_on_player_gold_changed)


func _on_inventory_changed(_slot_index_: int) -> void:
	if visible:
		_refresh_view()


func _on_inventory_item_amount_changed(_item_data, _amount_: int) -> void:
	if visible:
		_refresh_view()


func _on_player_gold_changed(_new_amount_: int, _delta_: int) -> void:
	if visible:
		_refresh_view()


func _set_player_locked(locked_: bool) -> void:
	var player_ = _get_player()
	if player_ == null:
		return

	player_.set_controls_locked(locked_)


func _get_player() -> Node:
	return get_tree().get_first_node_in_group("player")


func _get_dialog_manager() -> Node:
	return get_node_or_null(DIALOG_MANAGER_PATH)


func _get_upgrade_manager() -> Node:
	return get_node_or_null(UPGRADE_MANAGER_PATH)


func _get_decompose_manager() -> Node:
	return get_node_or_null(DECOMPOSE_MANAGER_PATH)


func _get_save_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("SaveManager")
#endregion
