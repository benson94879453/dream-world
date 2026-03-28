class_name EnemyData
extends Resource

const LootTableResource = preload("res://game/scripts/data/LootTableData.gd")

@export var enemy_id: StringName = &""
@export var display_name: String = ""
@export var max_hp: int = 50
@export var move_speed: float = 60.0
@export var chase_speed: float = 100.0
@export var detection_radius: float = 200.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.5
@export var dash_attack_range: float = 0.0
@export var dash_cooldown: float = 0.0
@export var charge_duration: float = 0.8
@export var charge_animation_fps: float = 15.0
@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.3
@export var enemy_scene: PackedScene = null
@export var loot_table: LootTableResource = null
