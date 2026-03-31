class_name LootEntryData
extends Resource

const GearDataResource = preload("res://game/scripts/data/GearData.gd")
const ItemDataResource = preload("res://game/scripts/data/ItemData.gd")

@export var item_data: ItemDataResource = null
@export var gear_data: GearDataResource = null
@export var weapon_data: WeaponData = null
@export var min_amount: int = 1
@export var max_amount: int = 1
@export_range(0.0, 1.0, 0.01) var drop_chance: float = 1.0
