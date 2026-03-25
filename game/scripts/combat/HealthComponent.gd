class_name HealthComponent
extends Node

signal health_changed(current_hp_: float, max_hp_: float)
signal died()

@export var max_hp: float = 100.0

var current_hp: float = 0.0

#region Core Lifecycle
func _ready() -> void:
	current_hp = max_hp
#endregion

#region Public
func apply_damage(amount_: float) -> float:
	if amount_ <= 0.0 or current_hp <= 0.0:
		return 0.0

	var next_hp_: float = maxf(current_hp - amount_, 0.0)
	var applied_damage_: float = current_hp - next_hp_

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


func is_dead() -> bool:
	return current_hp <= 0.0
#endregion
