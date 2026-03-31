class_name PickupItem
extends Node2D

const GearDataResource = preload("res://game/scripts/data/GearData.gd")
const GearInstanceResource = preload("res://game/scripts/data/GearInstance.gd")
const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")
const DefaultItemIcon = preload("res://game/assets/weapon/test_sword.png")

enum PickupType {
	ITEM,
	WEAPON,
	GEAR
}

@export var pickup_delay: float = 0.5
@export var lifetime: float = 30.0
@export var bob_height: float = 2.5
@export var bob_speed: float = 3.0

var pickup_type: PickupType = PickupType.ITEM
var pickup_enabled: bool = false
var pickup_delay_remaining: float = 0.0
var lifetime_remaining: float = 0.0
var bob_time: float = 0.0
var sprite_base_position: Vector2 = Vector2.ZERO

var _item_data: ItemDataResource = null
var _amount: int = 1
var _weapon_instance: WeaponInstanceResource = null
var _gear_instance: GearInstanceResource = null
var _suspend_auto_sync: bool = false

@export var item_data: ItemDataResource:
	get:
		return _item_data
	set(value_):
		if _suspend_auto_sync:
			_item_data = value_
			return
		_safely_apply_payload(PickupType.ITEM, value_, _amount, null, null)

@export var amount: int = 1:
	get:
		return _amount
	set(value_):
		_amount = maxi(value_, 1)
		if _suspend_auto_sync:
			return
		if pickup_type == PickupType.ITEM or (_weapon_instance == null and _gear_instance == null):
			pickup_type = PickupType.ITEM
		_refresh_sprite()

var weapon_instance: WeaponInstanceResource:
	get:
		return _weapon_instance
	set(value_):
		if _suspend_auto_sync:
			_weapon_instance = value_
			return
		_weapon_instance = value_
		if value_ == null:
			_sync_pickup_type_from_payload()
			return
		_safely_apply_payload(PickupType.WEAPON, null, 1, value_, null)

var gear_instance: GearInstanceResource:
	get:
		return _gear_instance
	set(value_):
		if _suspend_auto_sync:
			_gear_instance = value_
			return
		_gear_instance = value_
		if value_ == null:
			_sync_pickup_type_from_payload()
			return
		_safely_apply_payload(PickupType.GEAR, null, 1, null, value_)

@onready var sprite: Sprite2D = $Sprite2D
@onready var pickup_area: Area2D = $PickupArea

#region Core Lifecycle
func _ready() -> void:
	assert(sprite != null, "PickupItem requires Sprite2D")
	assert(pickup_area != null, "PickupItem requires PickupArea")

	pickup_delay_remaining = maxf(pickup_delay, 0.0)
	lifetime_remaining = maxf(lifetime, 0.0)
	pickup_enabled = pickup_delay_remaining <= 0.0
	sprite_base_position = sprite.position

	pickup_area.body_entered.connect(_on_pickup_area_entered)
	_sync_pickup_type_from_payload()


func _process(delta_: float) -> void:
	if not pickup_enabled:
		pickup_delay_remaining = maxf(pickup_delay_remaining - delta_, 0.0)
		if pickup_delay_remaining <= 0.0:
			pickup_enabled = true
			_try_pickup_overlaps()

	if lifetime > 0.0:
		lifetime_remaining = maxf(lifetime_remaining - delta_, 0.0)
		if lifetime_remaining <= 0.0:
			queue_free()
			return

	bob_time += delta_ * bob_speed
	sprite.position = sprite_base_position + Vector2(0.0, sin(bob_time) * bob_height)
#endregion

#region Public
func setup_from_item(item_data_: ItemDataResource, amount_: int = 1) -> void:
	_safely_apply_payload(PickupType.ITEM, item_data_, amount_, null, null)


func setup_from_weapon_instance(weapon_instance_: WeaponInstanceResource) -> void:
	if weapon_instance_ == null:
		push_warning("[PickupItem] setup_from_weapon_instance requires a valid WeaponInstance")
		return

	_safely_apply_payload(PickupType.WEAPON, null, 1, weapon_instance_, null)


func setup_from_gear_instance(gear_instance_: GearInstanceResource) -> void:
	if gear_instance_ == null:
		push_warning("[PickupItem] setup_from_gear_instance requires a valid GearInstance")
		return

	_safely_apply_payload(PickupType.GEAR, null, 1, null, gear_instance_)


func setup_from_weapon(weapon_data_: WeaponData) -> void:
	if weapon_data_ == null:
		push_warning("[PickupItem] setup_from_weapon requires a valid WeaponData")
		return

	setup_from_weapon_instance(WeaponInstanceResource.create_from_data(weapon_data_))


func setup_from_gear(gear_data_: GearDataResource) -> void:
	if gear_data_ == null:
		push_warning("[PickupItem] setup_from_gear requires a valid GearData")
		return

	setup_from_gear_instance(GearInstanceResource.create_from_data(gear_data_))


func get_pickup_display_text() -> String:
	match pickup_type:
		PickupType.WEAPON:
			return "[武器] %s" % _get_weapon_display_name()
		PickupType.GEAR:
			return "[裝備] %s" % _get_gear_display_name()
		_:
			return "%s x%d" % [_get_item_display_name(), amount]
#endregion

#region Helpers
func _safely_apply_payload(
	next_pickup_type_: PickupType,
	item_data_: ItemDataResource,
	amount_: int,
	weapon_instance_: WeaponInstanceResource,
	gear_instance_: GearInstanceResource
) -> void:
	_suspend_auto_sync = true
	_item_data = item_data_
	_amount = maxi(amount_, 1)
	_weapon_instance = weapon_instance_
	_gear_instance = gear_instance_
	pickup_type = next_pickup_type_
	_suspend_auto_sync = false
	_refresh_sprite()


func _sync_pickup_type_from_payload() -> void:
	if _weapon_instance != null:
		_safely_apply_payload(PickupType.WEAPON, null, 1, _weapon_instance, null)
		return

	if _gear_instance != null:
		_safely_apply_payload(PickupType.GEAR, null, 1, null, _gear_instance)
		return

	_safely_apply_payload(PickupType.ITEM, _item_data, _amount, null, null)


func _refresh_sprite() -> void:
	if sprite == null:
		return

	name = get_pickup_display_text()
	sprite.texture = _resolve_pickup_texture()


func _resolve_pickup_texture() -> Texture2D:
	match pickup_type:
		PickupType.WEAPON:
			var weapon_data_ := weapon_instance.weapon_data if weapon_instance != null else null
			if weapon_data_ != null and weapon_data_.weapon_sprite_texture != null:
				return weapon_data_.weapon_sprite_texture
		PickupType.GEAR:
			var gear_data_ := gear_instance.gear_data if gear_instance != null else null
			if gear_data_ != null and gear_data_.icon != null:
				return gear_data_.icon
		_:
			if item_data != null and item_data.icon != null:
				return item_data.icon

	return DefaultItemIcon


func _on_pickup_area_entered(body_: Node2D) -> void:
	if not pickup_enabled:
		return

	var player_: PlayerController = body_ as PlayerController
	if player_ == null:
		return

	var inventory_ := player_.get_inventory()
	if inventory_ == null:
		return

	match pickup_type:
		PickupType.ITEM:
			if item_data == null:
				return

			var remaining_amount_: int = inventory_.add_item(item_data, amount)
			var picked_amount_: int = amount - remaining_amount_
			if picked_amount_ > 0:
				player_.record_recent_pickup(item_data.display_name, picked_amount_)
				var quest_manager_: Node = _get_quest_manager()
				if quest_manager_ != null:
					quest_manager_.report_item_collected(item_data.item_id, picked_amount_)

			if remaining_amount_ <= 0:
				queue_free()
				return

			amount = remaining_amount_
		PickupType.WEAPON:
			if weapon_instance == null or not inventory_.add_weapon(weapon_instance):
				return

			player_.record_recent_pickup(_get_weapon_display_name(), 1)
			queue_free()
		PickupType.GEAR:
			if gear_instance == null or not inventory_.add_gear(gear_instance):
				return

			player_.record_recent_pickup(_get_gear_display_name(), 1)
			queue_free()


func _try_pickup_overlaps() -> void:
	for body_ in pickup_area.get_overlapping_bodies():
		var body_node_: Node2D = body_ as Node2D
		if body_node_ == null:
			continue

		_on_pickup_area_entered(body_node_)
		if is_queued_for_deletion():
			return


func _get_item_display_name() -> String:
	if item_data == null:
		return "未知物品"
	return item_data.display_name if not item_data.display_name.is_empty() else String(item_data.item_id)


func _get_weapon_display_name() -> String:
	if weapon_instance == null:
		return "未知武器"

	if weapon_instance.weapon_data != null and not weapon_instance.weapon_data.display_name.is_empty():
		return weapon_instance.weapon_data.display_name

	return String(weapon_instance.weapon_id)


func _get_gear_display_name() -> String:
	if gear_instance == null:
		return "未知裝備"

	if gear_instance.gear_data != null and not gear_instance.gear_data.display_name.is_empty():
		return gear_instance.gear_data.display_name

	return String(gear_instance.gear_id)


func _get_quest_manager() -> Node:
	var tree_: SceneTree = get_tree()
	if tree_ == null or tree_.root == null:
		return null
	return tree_.root.get_node_or_null("QuestManager")
#endregion
