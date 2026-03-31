class_name DropComponent
extends Node

const GearDataResource = preload("res://game/scripts/data/GearData.gd")
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

	var owner_node_: Node2D = get_parent() as Node2D
	assert(owner_node_ != null, "DropComponent requires Node2D parent for on_death")

	var spawn_parent_: Node = owner_node_.get_parent()
	assert(spawn_parent_ != null, "DropComponent requires grandparent node for drop spawning")

	var rng_: RandomNumberGenerator = RandomNumberGenerator.new()
	rng_.randomize()

	var drops_ := loot_table.generate_drops()
	has_dropped = true
	var player_ = get_tree().get_first_node_in_group("player")

	for drop_ in drops_:
		if drop_.has("gold"):
			var gold_amount_: int = int(drop_.get("gold", 0))
			if player_ != null and gold_amount_ > 0:
				player_.add_gold(gold_amount_)
				player_.record_recent_pickup("金幣", gold_amount_)
			continue

		var pickup_item_: PickupItemResource = PickupItemScene.instantiate() as PickupItemResource
		if pickup_item_ == null:
			continue

		if drop_.has("weapon_instance"):
			pickup_item_.setup_from_weapon_instance(drop_["weapon_instance"])
		elif drop_.has("gear_instance"):
			pickup_item_.setup_from_gear_instance(drop_["gear_instance"])
		elif drop_.has("weapon_data"):
			pickup_item_.setup_from_weapon(drop_["weapon_data"] as WeaponData)
		elif drop_.has("gear_data"):
			pickup_item_.setup_from_gear(drop_["gear_data"] as GearDataResource)
		elif drop_.has("item_data"):
			pickup_item_.setup_from_item(drop_["item_data"], int(drop_.get("amount", 1)))
		else:
			pickup_item_.queue_free()
			continue

		spawn_parent_.add_child(pickup_item_)
		var random_offset_: Vector2 = Vector2(
			rng_.randf_range(-random_offset_radius, random_offset_radius),
			rng_.randf_range(-random_offset_radius, random_offset_radius)
		)
		pickup_item_.global_position = owner_node_.global_position + drop_offset + random_offset_
#endregion
