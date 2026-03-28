class_name InventoryUI
extends CanvasLayer

const InventoryResource = preload("res://game/scripts/inventory/Inventory.gd")
const InventorySlotResource = preload("res://game/scripts/inventory/InventorySlot.gd")
const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const ItemSlotUIScene = preload("res://game/scenes/ui/ItemSlotUI.tscn")
const RuneDataResource = preload("res://game/scripts/data/RuneData.gd")
const HotbarManagerNode = preload("res://game/scripts/core/HotbarManager.gd")

const FILTER_ALL: StringName = &"all"
const FILTER_MATERIAL: StringName = &"material"
const FILTER_CONSUMABLE: StringName = &"consumable"
const FILTER_WEAPON: StringName = &"weapon"
const FILTER_RUNE: StringName = &"rune"
const FILTER_KEY: StringName = &"key"
const TOOLTIP_OFFSET: Vector2 = Vector2(18.0, 18.0)
const TOOLTIP_DELAY_SECONDS: float = 0.5

var current_filter: StringName = FILTER_ALL
var tracked_player: PlayerController = null
var tracked_inventory: InventoryResource = null
var hotbar_manager = null
var inventory_slot_uis: Array = []
var hotbar_slot_uis: Array = []
var hovered_slot_ui = null

@onready var main_panel: PanelContainer = $MainPanel
@onready var title_label: Label = $MainPanel/PanelMargin/Root/TitleBar/TitleLabel
@onready var tab_all_button: Button = $MainPanel/PanelMargin/Root/CategoryTabs/TabAll
@onready var tab_material_button: Button = $MainPanel/PanelMargin/Root/CategoryTabs/TabMaterial
@onready var tab_consumable_button: Button = $MainPanel/PanelMargin/Root/CategoryTabs/TabConsumable
@onready var tab_weapon_button: Button = $MainPanel/PanelMargin/Root/CategoryTabs/TabWeapon
@onready var tab_rune_button: Button = $MainPanel/PanelMargin/Root/CategoryTabs/TabRune
@onready var tab_key_button: Button = $MainPanel/PanelMargin/Root/CategoryTabs/TabKey
@onready var item_grid: GridContainer = $MainPanel/PanelMargin/Root/ItemGrid
@onready var hotbar_slots: HBoxContainer = $MainPanel/PanelMargin/Root/HotbarSection/HotbarSlots
@onready var info_label: Label = $MainPanel/PanelMargin/Root/InfoLabel
@onready var tooltip_panel: PanelContainer = $TooltipPanel
@onready var tooltip_name_label: Label = $TooltipPanel/TooltipMargin/TooltipContent/ItemNameLabel
@onready var tooltip_type_label: Label = $TooltipPanel/TooltipMargin/TooltipContent/ItemTypeLabel
@onready var tooltip_description_label: Label = $TooltipPanel/TooltipMargin/TooltipContent/ItemDescriptionLabel
@onready var tooltip_stats_label: Label = $TooltipPanel/TooltipMargin/TooltipContent/ItemStatsLabel
@onready var tooltip_slot_label: Label = $TooltipPanel/TooltipMargin/TooltipContent/ItemSlotLabel
@onready var tooltip_delay_timer: Timer = $TooltipDelayTimer

#region Core Lifecycle
func _ready() -> void:
	assert(main_panel != null, "InventoryUI requires MainPanel")
	assert(title_label != null, "InventoryUI requires TitleLabel")
	assert(tab_all_button != null, "InventoryUI requires TabAll")
	assert(tab_material_button != null, "InventoryUI requires TabMaterial")
	assert(tab_consumable_button != null, "InventoryUI requires TabConsumable")
	assert(tab_weapon_button != null, "InventoryUI requires TabWeapon")
	assert(tab_rune_button != null, "InventoryUI requires TabRune")
	assert(tab_key_button != null, "InventoryUI requires TabKey")
	assert(item_grid != null, "InventoryUI requires ItemGrid")
	assert(hotbar_slots != null, "InventoryUI requires HotbarSlots")
	assert(info_label != null, "InventoryUI requires InfoLabel")
	assert(tooltip_panel != null, "InventoryUI requires TooltipPanel")
	assert(tooltip_name_label != null, "InventoryUI requires ItemNameLabel")
	assert(tooltip_type_label != null, "InventoryUI requires ItemTypeLabel")
	assert(tooltip_description_label != null, "InventoryUI requires ItemDescriptionLabel")
	assert(tooltip_stats_label != null, "InventoryUI requires ItemStatsLabel")
	assert(tooltip_slot_label != null, "InventoryUI requires ItemSlotLabel")
	assert(tooltip_delay_timer != null, "InventoryUI requires TooltipDelayTimer")

	add_to_group("inventory_ui")
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	tooltip_panel.visible = false
	tooltip_delay_timer.wait_time = TOOLTIP_DELAY_SECONDS
	tooltip_delay_timer.one_shot = true
	tooltip_delay_timer.timeout.connect(_on_tooltip_delay_timeout)

	hotbar_manager = _get_hotbar_manager()
	assert(hotbar_manager != null, "InventoryUI requires HotbarManager autoload")

	_connect_category_tabs()
	_style_ui()
	_resolve_inventory_context()
	_build_slot_ui()
	_update_category_tab_states()
	refresh_all()

	if hotbar_manager != null and not hotbar_manager.binding_changed.is_connected(_on_hotbar_binding_changed):
		hotbar_manager.binding_changed.connect(_on_hotbar_binding_changed)


func _process(_delta: float) -> void:
	if tooltip_panel.visible:
		_update_tooltip_position()


func _input(event_: InputEvent) -> void:
	if not event_.is_action_pressed("ui_inventory"):
		return

	set_inventory_open(not is_open())
	get_viewport().set_input_as_handled()
#endregion

#region Public
func is_open() -> bool:
	return visible


func set_inventory_open(open_: bool) -> void:
	_resolve_inventory_context()
	if tracked_player != null:
		tracked_player.set_inventory_ui_open(open_)

	visible = open_
	if not open_:
		tooltip_delay_timer.stop()
		hovered_slot_ui = null
		tooltip_panel.visible = false
		return

	refresh_all()


func toggle_inventory() -> void:
	set_inventory_open(not is_open())


func refresh_all() -> void:
	_refresh_item_grid()
	_refresh_hotbar()
	_update_category_tab_states()
#endregion

#region Helpers
func _build_slot_ui() -> void:
	for child_ in item_grid.get_children():
		child_.queue_free()
	for child_ in hotbar_slots.get_children():
		child_.queue_free()

	inventory_slot_uis.clear()
	hotbar_slot_uis.clear()

	assert(tracked_inventory != null, "InventoryUI requires tracked Inventory before building slots")
	for slot_index_ in range(tracked_inventory.slots.size()):
		var slot_ui_ = ItemSlotUIScene.instantiate()
		assert(slot_ui_ != null, "InventoryUI requires ItemSlotUI scene to instantiate slot UI")
		item_grid.add_child(slot_ui_)
		slot_ui_.configure_inventory_slot(tracked_inventory, slot_index_)
		slot_ui_.hover_started.connect(_on_slot_hover_started)
		slot_ui_.hover_ended.connect(_on_slot_hover_ended)
		inventory_slot_uis.append(slot_ui_)

	for hotbar_index_ in range(HotbarManagerNode.HOTBAR_SIZE):
		var hotbar_slot_ui_ = ItemSlotUIScene.instantiate()
		assert(hotbar_slot_ui_ != null, "InventoryUI requires ItemSlotUI scene to instantiate hotbar slot UI")
		hotbar_slots.add_child(hotbar_slot_ui_)
		hotbar_slot_ui_.configure_hotbar_slot(tracked_inventory, hotbar_manager, hotbar_index_)
		hotbar_slot_ui_.hover_started.connect(_on_slot_hover_started)
		hotbar_slot_ui_.hover_ended.connect(_on_slot_hover_ended)
		hotbar_slot_uis.append(hotbar_slot_ui_)


func _connect_category_tabs() -> void:
	tab_all_button.pressed.connect(_on_category_tab_pressed.bind(FILTER_ALL))
	tab_material_button.pressed.connect(_on_category_tab_pressed.bind(FILTER_MATERIAL))
	tab_consumable_button.pressed.connect(_on_category_tab_pressed.bind(FILTER_CONSUMABLE))
	tab_weapon_button.pressed.connect(_on_category_tab_pressed.bind(FILTER_WEAPON))
	tab_rune_button.pressed.connect(_on_category_tab_pressed.bind(FILTER_RUNE))
	tab_key_button.pressed.connect(_on_category_tab_pressed.bind(FILTER_KEY))


func _style_ui() -> void:
	title_label.text = "背包"
	info_label.text = "[E / I] 開關背包   [1-5] 使用快捷欄   拖曳可整理與綁定"
	_apply_panel_style(main_panel, Color(0.16, 0.16, 0.16, 0.96), Color(0.68, 0.68, 0.68, 1.0), 4)
	_apply_panel_style(tooltip_panel, Color(0.12, 0.12, 0.12, 0.97), Color(0.95, 0.85, 0.42, 1.0), 3)

	var tab_buttons_: Array[Button] = [
		tab_all_button,
		tab_material_button,
		tab_consumable_button,
		tab_weapon_button,
		tab_rune_button,
		tab_key_button
	]
	for button_ in tab_buttons_:
		button_.custom_minimum_size = Vector2(90.0, 36.0)


func _apply_panel_style(panel_: Control, bg_color_: Color, border_color_: Color, border_width_: int) -> void:
	var stylebox_: StyleBoxFlat = StyleBoxFlat.new()
	stylebox_.bg_color = bg_color_
	stylebox_.border_color = border_color_
	stylebox_.border_width_left = border_width_
	stylebox_.border_width_top = border_width_
	stylebox_.border_width_right = border_width_
	stylebox_.border_width_bottom = border_width_
	stylebox_.corner_radius_top_left = 4
	stylebox_.corner_radius_top_right = 4
	stylebox_.corner_radius_bottom_left = 4
	stylebox_.corner_radius_bottom_right = 4
	panel_.add_theme_stylebox_override("panel", stylebox_)


func _apply_tab_button_style(button_: Button, active_: bool) -> void:
	var normal_style_: StyleBoxFlat = StyleBoxFlat.new()
	normal_style_.bg_color = Color(0.27, 0.27, 0.27, 1.0) if active_ else Color(0.18, 0.18, 0.18, 1.0)
	normal_style_.border_color = Color(0.95, 0.85, 0.42, 1.0) if active_ else Color(0.46, 0.46, 0.46, 1.0)
	normal_style_.border_width_left = 2
	normal_style_.border_width_top = 2
	normal_style_.border_width_right = 2
	normal_style_.border_width_bottom = 2
	normal_style_.corner_radius_top_left = 2
	normal_style_.corner_radius_top_right = 2
	normal_style_.corner_radius_bottom_left = 2
	normal_style_.corner_radius_bottom_right = 2

	button_.add_theme_stylebox_override("normal", normal_style_)
	button_.add_theme_stylebox_override("hover", normal_style_)
	button_.add_theme_stylebox_override("pressed", normal_style_)
	button_.add_theme_stylebox_override("focus", normal_style_)
	button_.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82, 1.0) if active_ else Color(0.88, 0.88, 0.88, 1.0))


func _resolve_inventory_context() -> void:
	var player_ := get_tree().get_first_node_in_group("player") as PlayerController
	assert(player_ != null, "InventoryUI requires PlayerController in group 'player'")

	var inventory_ := player_.get_inventory()
	assert(inventory_ != null, "InventoryUI requires PlayerController inventory")

	if tracked_inventory == inventory_ and tracked_player == player_:
		return

	if tracked_inventory != null and tracked_inventory.slot_changed.is_connected(_on_inventory_slot_changed):
		tracked_inventory.slot_changed.disconnect(_on_inventory_slot_changed)

	tracked_player = player_
	tracked_inventory = inventory_
	if not tracked_inventory.slot_changed.is_connected(_on_inventory_slot_changed):
		tracked_inventory.slot_changed.connect(_on_inventory_slot_changed)


func _refresh_item_grid() -> void:
	if tracked_inventory == null:
		return

	for slot_index_ in range(inventory_slot_uis.size()):
		var slot_ui_ = inventory_slot_uis[slot_index_]
		var slot_data_: InventorySlotResource = tracked_inventory.get_slot(slot_index_)
		var should_show_content_: bool = _should_show_slot(slot_data_)
		slot_ui_.setup_inventory_slot(slot_data_, should_show_content_)


func _refresh_hotbar() -> void:
	if tracked_inventory == null or hotbar_manager == null:
		return

	for hotbar_index_ in range(hotbar_slot_uis.size()):
		_refresh_hotbar_slot(hotbar_index_)


func _refresh_hotbar_slot(hotbar_index_: int) -> void:
	if hotbar_index_ < 0 or hotbar_index_ >= hotbar_slot_uis.size():
		return

	var inventory_index_: int = hotbar_manager.get_bound_inventory_index(hotbar_index_)
	var slot_data_: InventorySlotResource = tracked_inventory.get_slot(inventory_index_) if tracked_inventory != null else null
	hotbar_slot_uis[hotbar_index_].setup_hotbar_slot(slot_data_, inventory_index_)


func _should_show_slot(slot_data_: InventorySlotResource) -> bool:
	if current_filter == FILTER_ALL:
		return true
	if slot_data_ == null or slot_data_.is_empty():
		return true
	if slot_data_.weapon_instance != null:
		return current_filter == FILTER_WEAPON
	if slot_data_.item_data == null:
		return true

	var item_data_: ItemDataResource = slot_data_.item_data
	match current_filter:
		FILTER_RUNE:
			return item_data_ is RuneDataResource
		FILTER_MATERIAL:
			return item_data_.item_type == ItemData.ItemType.MATERIAL and not (item_data_ is RuneDataResource)
		FILTER_CONSUMABLE:
			return item_data_.item_type == ItemData.ItemType.CONSUMABLE
		FILTER_KEY:
			return item_data_.item_type == ItemData.ItemType.KEY_ITEM
		FILTER_WEAPON:
			return false
		_:
			return true


func _update_category_tab_states() -> void:
	_apply_tab_button_style(tab_all_button, current_filter == FILTER_ALL)
	_apply_tab_button_style(tab_material_button, current_filter == FILTER_MATERIAL)
	_apply_tab_button_style(tab_consumable_button, current_filter == FILTER_CONSUMABLE)
	_apply_tab_button_style(tab_weapon_button, current_filter == FILTER_WEAPON)
	_apply_tab_button_style(tab_rune_button, current_filter == FILTER_RUNE)
	_apply_tab_button_style(tab_key_button, current_filter == FILTER_KEY)


func _show_tooltip_for_slot(slot_ui_) -> void:
	if slot_ui_ == null:
		return

	var payload_: Dictionary = slot_ui_.build_tooltip_payload()
	if payload_.is_empty():
		tooltip_panel.visible = false
		return

	tooltip_name_label.text = String(payload_.get("name", ""))
	tooltip_type_label.text = "類型: %s" % String(payload_.get("type", ""))
	tooltip_description_label.text = String(payload_.get("description", ""))
	tooltip_stats_label.text = String(payload_.get("stats", ""))
	tooltip_slot_label.text = String(payload_.get("slot_text", ""))
	tooltip_panel.visible = true
	_update_tooltip_position()


func _update_tooltip_position() -> void:
	var viewport_size_: Vector2 = get_viewport().get_visible_rect().size
	var desired_position_: Vector2 = get_viewport().get_mouse_position() + TOOLTIP_OFFSET
	var panel_size_: Vector2 = tooltip_panel.size
	if desired_position_.x + panel_size_.x > viewport_size_.x - 8.0:
		desired_position_.x = viewport_size_.x - panel_size_.x - 8.0
	if desired_position_.y + panel_size_.y > viewport_size_.y - 8.0:
		desired_position_.y = viewport_size_.y - panel_size_.y - 8.0

	tooltip_panel.position = desired_position_


func _on_category_tab_pressed(filter_id_: StringName) -> void:
	current_filter = filter_id_
	tooltip_delay_timer.stop()
	tooltip_panel.visible = false
	hovered_slot_ui = null
	refresh_all()


func _on_slot_hover_started(slot_ui_) -> void:
	if not visible or slot_ui_ == null or not slot_ui_.has_display_content():
		return

	hovered_slot_ui = slot_ui_
	tooltip_delay_timer.start()


func _on_slot_hover_ended(slot_ui_) -> void:
	if hovered_slot_ui != slot_ui_:
		return

	tooltip_delay_timer.stop()
	hovered_slot_ui = null
	tooltip_panel.visible = false


func _on_tooltip_delay_timeout() -> void:
	if hovered_slot_ui == null:
		return
	_show_tooltip_for_slot(hovered_slot_ui)


func _on_inventory_slot_changed(slot_index_: int) -> void:
	if slot_index_ >= 0 and slot_index_ < inventory_slot_uis.size():
		var slot_data_: InventorySlotResource = tracked_inventory.get_slot(slot_index_)
		inventory_slot_uis[slot_index_].setup_inventory_slot(slot_data_, _should_show_slot(slot_data_))

	for hotbar_index_ in range(hotbar_slot_uis.size()):
		if hotbar_manager.get_bound_inventory_index(hotbar_index_) != slot_index_:
			continue
		_refresh_hotbar_slot(hotbar_index_)

	if hovered_slot_ui == null:
		return
	if tooltip_panel.visible:
		_show_tooltip_for_slot(hovered_slot_ui)


func _on_hotbar_binding_changed(hotbar_index_: int, _inventory_index_: int) -> void:
	_refresh_hotbar_slot(hotbar_index_)
	if hovered_slot_ui == null:
		return
	if tooltip_panel.visible:
		_show_tooltip_for_slot(hovered_slot_ui)


func _get_hotbar_manager() -> Node:
	var tree_: SceneTree = get_tree()
	assert(tree_ != null and tree_.root != null, "InventoryUI requires SceneTree root")
	return tree_.root.get_node_or_null("HotbarRuntime")
#endregion
