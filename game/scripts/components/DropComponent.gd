class_name DropComponent
extends Node

const LootTableResource = preload("res://game/scripts/data/LootTableData.gd")
const PickupItemResource = preload("res://game/scripts/items/PickupItem.gd")
const PickupItemScene = preload("res://game/scenes/items/PickupItem.tscn")

@export var loot_table: LootTableResource = null
@export var drop_offset: Vector2 = Vector2.ZERO
@export var random_offset_radius: float = 12.0

var has_dropped: bool = false

#region Public
func on_death() -> void:
	if has_dropped or loot_table == null:
		return

	var owner_node_ := get_parent() as Node2D
	if owner_node_ == null:
		return

	var spawn_parent_ := owner_node_.get_parent()
	if spawn_parent_ == null:
		return

	var rng_ := RandomNumberGenerator.new()
	rng_.randomize()

	var drops_ := loot_table.generate_drops()
	has_dropped = true

	for drop_ in drops_:
		var pickup_item_ := PickupItemScene.instantiate() as PickupItemResource
		if pickup_item_ == null:
			continue

		if drop_.has("weapon_data"):
			pickup_item_.setup_from_weapon(drop_["weapon_data"] as WeaponData)
		elif drop_.has("item_data"):
			pickup_item_.setup_from_item(drop_["item_data"], int(drop_.get("amount", 1)))
		else:
			pickup_item_.queue_free()
			continue

		spawn_parent_.add_child(pickup_item_)
		var random_offset_ := Vector2(
			rng_.randf_range(-random_offset_radius, random_offset_radius),
			rng_.randf_range(-random_offset_radius, random_offset_radius)
		)
		pickup_item_.global_position = owner_node_.global_position + drop_offset + random_offset_
#endregion
