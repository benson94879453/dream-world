class_name EquipmentUI
extends PanelContainer

const EquipmentNode = preload("res://game/scripts/inventory/Equipment.gd")
const EquipmentSlotUIResource = preload("res://game/scripts/ui/EquipmentSlotUI.gd")
const UIColorsResource = preload("res://game/scripts/ui/UIColors.gd")

var player: PlayerController = null
var inventory_ui = null
var tracked_equipment: EquipmentNode = null
var equipment_slot_uis: Array[EquipmentSlotUIResource] = []

@onready var title_label: Label = $Margin/Root/TitleLabel
@onready var weapon_slot: EquipmentSlotUIResource = $Margin/Root/WeaponSlot
@onready var helmet_slot: EquipmentSlotUIResource = $Margin/Root/ArmorGrid/HelmetSlot
@onready var chestplate_slot: EquipmentSlotUIResource = $Margin/Root/ArmorGrid/ChestplateSlot
@onready var leggings_slot: EquipmentSlotUIResource = $Margin/Root/ArmorGrid/LeggingsSlot
@onready var boots_slot: EquipmentSlotUIResource = $Margin/Root/ArmorGrid/BootsSlot
@onready var defense_label: Label = $Margin/Root/StatsPanel/DefenseLabel
@onready var stats_label: Label = $Margin/Root/StatsPanel/StatsLabel

#region Core Lifecycle
func _ready() -> void:
	assert(title_label != null, "EquipmentUI requires TitleLabel")
	assert(weapon_slot != null, "EquipmentUI requires WeaponSlot")
	assert(helmet_slot != null, "EquipmentUI requires HelmetSlot")
	assert(chestplate_slot != null, "EquipmentUI requires ChestplateSlot")
	assert(leggings_slot != null, "EquipmentUI requires LeggingsSlot")
	assert(boots_slot != null, "EquipmentUI requires BootsSlot")
	assert(defense_label != null, "EquipmentUI requires DefenseLabel")
	assert(stats_label != null, "EquipmentUI requires StatsLabel")

	title_label.text = "裝備"
	equipment_slot_uis = [weapon_slot, helmet_slot, chestplate_slot, leggings_slot, boots_slot]
	for slot_ui_ in equipment_slot_uis:
		slot_ui_.slot_clicked.connect(_on_slot_clicked)
		slot_ui_.slot_shift_clicked.connect(_on_slot_shift_clicked)

	_apply_style()
	visible = false
	_update_all_slots()
	_update_stats()
#endregion

#region Public
func open(player_: PlayerController, inventory_ui_ = null) -> void:
	player = player_
	inventory_ui = inventory_ui_
	visible = true
	_bind_equipment(player.equipment if player != null else null)
	_update_all_slots()
	_update_stats()


func close() -> void:
	visible = false
	_bind_equipment(null)
	player = null
	inventory_ui = null


func refresh_view() -> void:
	_update_all_slots()
	_update_stats()
#endregion

#region Helpers
func _bind_equipment(equipment_: EquipmentNode) -> void:
	if tracked_equipment == equipment_:
		for slot_ui_ in equipment_slot_uis:
			slot_ui_.configure(tracked_equipment)
		return

	if tracked_equipment != null and tracked_equipment.equipment_changed.is_connected(_on_equipment_changed):
		tracked_equipment.equipment_changed.disconnect(_on_equipment_changed)

	tracked_equipment = equipment_
	for slot_ui_ in equipment_slot_uis:
		slot_ui_.configure(tracked_equipment)

	if tracked_equipment != null and not tracked_equipment.equipment_changed.is_connected(_on_equipment_changed):
		tracked_equipment.equipment_changed.connect(_on_equipment_changed)


func _update_all_slots() -> void:
	for slot_ui_ in equipment_slot_uis:
		slot_ui_.configure(tracked_equipment)


func _update_stats() -> void:
	if tracked_equipment == null:
		defense_label.text = "總防禦: 0.0"
		stats_label.text = "無裝備加成"
		return

	defense_label.text = "總防禦: %.1f" % tracked_equipment.get_total_defense()
	var modifiers_ := tracked_equipment.get_total_stat_modifiers()
	if modifiers_.is_empty():
		stats_label.text = "無裝備加成"
		return

	var stat_lines_: Array[String] = []
	for modifier_key_ in modifiers_:
		var stat_key_ := StringName(String(modifier_key_))
		var value_ := float(modifiers_.get(modifier_key_, 0.0))
		stat_lines_.append("%s: %+.1f" % [_format_stat_key(stat_key_), value_])

	stats_label.text = "\n".join(stat_lines_)


func _convert_to_equipment_slot(slot_type_: EquipmentSlotUIResource.SlotType) -> EquipmentNode.EquipmentSlot:
	match slot_type_:
		EquipmentSlotUIResource.SlotType.WEAPON_MAIN:
			return EquipmentNode.EquipmentSlot.WEAPON_MAIN
		EquipmentSlotUIResource.SlotType.HELMET:
			return EquipmentNode.EquipmentSlot.HELMET
		EquipmentSlotUIResource.SlotType.CHESTPLATE:
			return EquipmentNode.EquipmentSlot.CHESTPLATE
		EquipmentSlotUIResource.SlotType.LEGGINGS:
			return EquipmentNode.EquipmentSlot.LEGGINGS
		EquipmentSlotUIResource.SlotType.BOOTS:
			return EquipmentNode.EquipmentSlot.BOOTS
		_:
			return EquipmentNode.EquipmentSlot.WEAPON_MAIN


func _on_slot_clicked(_slot_type_: EquipmentSlotUIResource.SlotType) -> void:
	# Reserved for future interactions such as direct compare/equip.
	pass


func _on_slot_shift_clicked(slot_type_: EquipmentSlotUIResource.SlotType) -> void:
	if player == null:
		return

	var equipment_slot_ := _convert_to_equipment_slot(slot_type_)
	if not player.try_unequip_to_inventory(equipment_slot_):
		return

	_update_all_slots()
	_update_stats()
	if inventory_ui != null and inventory_ui.has_method("refresh"):
		inventory_ui.refresh()


func _on_equipment_changed() -> void:
	_update_all_slots()
	_update_stats()
	if inventory_ui != null and inventory_ui.has_method("refresh"):
		inventory_ui.refresh()


func _apply_style() -> void:
	var stylebox_ := UIColorsResource.build_panel_style(UIColorsResource.PANEL_BG_DARK, UIColorsResource.PANEL_BORDER, UIColorsResource.MODAL_BORDER_WIDTH, UIColorsResource.MODAL_CORNER_RADIUS)
	add_theme_stylebox_override("panel", stylebox_)


func _format_stat_key(stat_key_: StringName) -> String:
	match stat_key_:
		&"max_hp_bonus":
			return "最大生命"
		&"move_speed_bonus_pct":
			return "移動速度%"
		_:
			return String(stat_key_)
#endregion
