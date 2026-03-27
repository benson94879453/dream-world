class_name WeaponAttackProfile
extends Resource

@export var startup_frames: int = 0
@export var active_frames: int = 5
@export var recovery_frames: int = 10
@export var cooldown_seconds: float = 0.5

@export var animation_name: String = "attack"
@export var muzzle_flash_scene: PackedScene = null
@export var hit_effect_scene: PackedScene = null

@export var startup_audio: AudioStream = null
@export var hit_audio: AudioStream = null
