class_name ChestUI
extends CanvasLayer

const InventoryResource = preload("res://game/scripts/inventory/Inventory.gd")
const ItemSlotUIScene = preload("res://game/scenes/ui/ItemSlotUI.tscn")

@export var slot_count: int = 20

const OPEN_ANIMATION_SECONDS: float = 0.16

var chest_inventory: InventoryResource = null
var player: PlayerController = null
var player_inventory_ui = null
var slot_uis: Array[ItemSlotUI] = []

@onready var backdrop: ColorRect = $Backdrop
@onready var main_panel: PanelContainer = $MainPanel
@onready var title_label: Label = $MainPanel/Margin/Root/TitleBar/TitleLabel
@onready var close_button: Button = $MainPanel/Margin/Root/TitleBar/CloseButton
@onready var chest_grid: GridContainer = $MainPanel/Margin/Root/ChestGrid

#region Core Lifecycle
func _ready() -> void:
	assert(backdrop != null, "ChestUI requires Backdrop")
	assert(main_panel != null, "ChestUI requires MainPanel")
	assert(title_label != null, "ChestUI requires TitleLabel")
	assert(close_button != null, "ChestUI requires CloseButton")
	assert(chest_grid != null, "ChestUI requires ChestGrid")

	layer = 11
	visible = false
	backdrop.visible = true
	title_label.text = "箱子"
	close_button.pressed.connect(close)
	_apply_style()
	_build_slot_ui()
#endregion

#region Public
func open(chest_inventory_: InventoryResource, player_: PlayerController, player_inventory_ui_ = null) -> void:
	_disconnect_chest_inventory()
	chest_inventory = chest_inventory_
	player = player_
	player_inventory_ui = player_inventory_ui_
	visible = true

	if chest_inventory != null and not chest_inventory.slot_changed.is_connected(_on_chest_slot_changed):
		chest_inventory.slot_changed.connect(_on_chest_slot_changed)

	_refresh_slots()
	_play_open_animation()


func close() -> void:
	visible = false
	_reset_open_animation_state()
	_disconnect_chest_inventory()
	chest_inventory = null
	player = null
	player_inventory_ui = null
	_refresh_slots()
#endregion

#region Helpers
func _build_slot_ui() -> void:
	for child_ in chest_grid.get_children():
		child_.queue_free()
	slot_uis.clear()

	for slot_index_ in range(maxi(slot_count, 0)):
		var slot_ui_ := ItemSlotUIScene.instantiate() as ItemSlotUI
		if slot_ui_ == null:
			continue

		chest_grid.add_child(slot_ui_)
		slot_ui_.configure_inventory_slot(chest_inventory, slot_index_)
		slot_ui_.slot_clicked.connect(_on_slot_clicked)
		slot_ui_.slot_shift_clicked.connect(_on_slot_shift_clicked)
		slot_uis.append(slot_ui_)


func _refresh_slots() -> void:
	for slot_index_ in range(slot_uis.size()):
		var slot_ui_ := slot_uis[slot_index_]
		slot_ui_.configure_inventory_slot(chest_inventory, slot_index_)
		var slot_data_ = chest_inventory.get_slot(slot_index_) if chest_inventory != null else null
		slot_ui_.setup_inventory_slot(slot_data_, true)


func _move_slot_to_player(slot_ui_: ItemSlotUI) -> void:
	if slot_ui_ == null or player == null or chest_inventory == null:
		return

	var slot_index_ := slot_ui_.slot_index
	if slot_index_ < 0:
		return

	var player_inventory_ = player.get_inventory()
	if player_inventory_ == null:
		return

	if not player.quick_move_from_inventory(chest_inventory, slot_index_, player_inventory_):
		return

	if player_inventory_ui != null and player_inventory_ui.has_method("refresh"):
		player_inventory_ui.refresh()


func _disconnect_chest_inventory() -> void:
	if chest_inventory != null and chest_inventory.slot_changed.is_connected(_on_chest_slot_changed):
		chest_inventory.slot_changed.disconnect(_on_chest_slot_changed)


func _apply_style() -> void:
	backdrop.color = Color(0.03, 0.03, 0.04, 0.18)
	var stylebox_ := StyleBoxFlat.new()
	stylebox_.bg_color = Color(0.10, 0.11, 0.13, 0.98)
	stylebox_.border_color = Color(0.82, 0.69, 0.42, 1.0)
	stylebox_.border_width_left = 3
	stylebox_.border_width_top = 3
	stylebox_.border_width_right = 3
	stylebox_.border_width_bottom = 3
	stylebox_.corner_radius_top_left = 4
	stylebox_.corner_radius_top_right = 4
	stylebox_.corner_radius_bottom_left = 4
	stylebox_.corner_radius_bottom_right = 4
	main_panel.add_theme_stylebox_override("panel", stylebox_)


func _on_slot_clicked(slot_ui_: ItemSlotUI) -> void:
	_move_slot_to_player(slot_ui_)


func _on_slot_shift_clicked(slot_ui_: ItemSlotUI) -> void:
	_move_slot_to_player(slot_ui_)


func _on_chest_slot_changed(_slot_index_: int) -> void:
	_refresh_slots()


func _play_open_animation() -> void:
	var tween_ := create_tween()
	tween_.set_parallel(true)
	main_panel.pivot_offset = main_panel.size * 0.5
	backdrop.modulate.a = 0.0
	main_panel.modulate.a = 0.0
	main_panel.scale = Vector2(0.98, 0.98)
	tween_.tween_property(backdrop, "modulate:a", 1.0, OPEN_ANIMATION_SECONDS)
	tween_.tween_property(main_panel, "modulate:a", 1.0, OPEN_ANIMATION_SECONDS)
	tween_.tween_property(main_panel, "scale", Vector2.ONE, OPEN_ANIMATION_SECONDS)


func _reset_open_animation_state() -> void:
	backdrop.modulate = Color.WHITE
	main_panel.modulate = Color.WHITE
	main_panel.scale = Vector2.ONE
