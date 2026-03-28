class_name HealthComponent
extends Node

signal health_changed(current_hp_: float, max_hp_: float)
signal died()

@export var max_hp: float = 100.0
@export_range(0.0, 5.0, 0.05) var temporary_hp_cap_ratio: float = 0.5

var current_hp: float = 0.0
var temporary_hp: float = 0.0

#region Core Lifecycle
func _ready() -> void:
	current_hp = max_hp
	temporary_hp = 0.0
#endregion

#region Public
func apply_damage(amount_: float) -> float:
	if amount_ <= 0.0 or current_hp <= 0.0:
		return 0.0

	var remaining_damage_: float = amount_
	var absorbed_damage_: float = 0.0
	if temporary_hp > 0.0:
		absorbed_damage_ = minf(temporary_hp, remaining_damage_)
		temporary_hp -= absorbed_damage_
		remaining_damage_ -= absorbed_damage_

	var next_hp_: float = maxf(current_hp - remaining_damage_, 0.0)
	var applied_damage_: float = absorbed_damage_ + (current_hp - next_hp_)

	current_hp = next_hp_
	health_changed.emit(current_hp, max_hp)

	if current_hp <= 0.0:
		died.emit()

	return applied_damage_


func heal(amount_: float) -> float:
	if amount_ <= 0.0 or current_hp >= max_hp:
		return 0.0

	var next_hp_: float = minf(current_hp + amount_, max_hp)
	var restored_hp_: float = next_hp_ - current_hp

	current_hp = next_hp_
	health_changed.emit(current_hp, max_hp)

	return restored_hp_


func add_temporary_hp(amount_: float) -> float:
	if amount_ <= 0.0:
		return 0.0

	var next_temporary_hp_: float = minf(temporary_hp + amount_, get_max_temporary_hp())
	var added_temporary_hp_: float = next_temporary_hp_ - temporary_hp
	if added_temporary_hp_ <= 0.0:
		return 0.0

	temporary_hp = next_temporary_hp_
	health_changed.emit(current_hp, max_hp)
	return added_temporary_hp_


func set_temporary_hp(amount_: float) -> void:
	temporary_hp = clampf(amount_, 0.0, get_max_temporary_hp())
	health_changed.emit(current_hp, max_hp)


func get_max_temporary_hp() -> float:
	return maxf(max_hp * temporary_hp_cap_ratio, 0.0)


func is_dead() -> bool:
	return current_hp <= 0.0
#endregion
