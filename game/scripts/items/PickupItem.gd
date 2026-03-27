class_name PickupItem
extends Node2D

const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")
const WeaponInstanceResource = preload("res://game/scripts/data/WeaponInstance.gd")
const DefaultItemIcon = preload("res://game/assets/weapon/test_sword.png")

@export var pickup_delay: float = 0.5
@export var lifetime: float = 30.0
@export var bob_height: float = 2.5
@export var bob_speed: float = 3.0

var item_data: ItemDataResource = null
var amount: int = 1
var weapon_data: WeaponData = null
var weapon_instance: WeaponInstanceResource = null
var pickup_enabled: bool = false
var pickup_delay_remaining: float = 0.0
var lifetime_remaining: float = 0.0
var bob_time: float = 0.0
var sprite_base_position: Vector2 = Vector2.ZERO

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
	_refresh_sprite()


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
func setup_from_item(item_data_: ItemDataResource, amount_: int) -> void:
	item_data = item_data_
	amount = maxi(amount_, 1)
	weapon_data = null
	weapon_instance = null
	_refresh_sprite()


func setup_from_weapon(weapon_data_: WeaponData) -> void:
	weapon_data = weapon_data_
	weapon_instance = WeaponInstanceResource.create_from_data(weapon_data_) if weapon_data_ != null else null
	item_data = null
	amount = 1
	_refresh_sprite()
#endregion

#region Helpers
func _refresh_sprite() -> void:
	if sprite == null:
		return

	if item_data != null:
		sprite.texture = item_data.icon if item_data.icon != null else DefaultItemIcon
		return

	if weapon_data != null:
		sprite.texture = weapon_data.weapon_sprite_texture if weapon_data.weapon_sprite_texture != null else DefaultItemIcon
		return

	sprite.texture = DefaultItemIcon


func _on_pickup_area_entered(body_: Node2D) -> void:
	if not pickup_enabled:
		return

	var player_ := body_ as PlayerController
	if player_ == null:
		return

	var inventory_ := player_.get_inventory()
	if inventory_ == null:
		return

	if item_data != null:
		var remaining_amount_: int = inventory_.add_item(item_data, amount)
		var picked_amount_: int = amount - remaining_amount_
		if picked_amount_ > 0:
			player_.record_recent_pickup(item_data.display_name, picked_amount_)

		if remaining_amount_ <= 0:
			queue_free()
			return

		amount = remaining_amount_
		return

	if weapon_instance != null and inventory_.add_weapon(weapon_instance):
		var weapon_name_ := weapon_data.display_name if weapon_data != null else String(weapon_instance.weapon_id)
		player_.record_recent_pickup(weapon_name_, 1)
		queue_free()


func _try_pickup_overlaps() -> void:
	for body_ in pickup_area.get_overlapping_bodies():
		var body_node_ := body_ as Node2D
		if body_node_ == null:
			continue

		_on_pickup_area_entered(body_node_)
		if is_queued_for_deletion():
			return
#endregion
