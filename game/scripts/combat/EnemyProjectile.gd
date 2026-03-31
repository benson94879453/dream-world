class_name EnemyProjectile
extends Area2D

@export var speed: float = 150.0
@export var lifetime: float = 3.0
@export var damage: float = 8.0
@export var hitstop_duration_ms: int = 90
@export var hitstop_scale: float = 0.0

var direction: Vector2 = Vector2.ZERO
var source_node: Node2D = null

@onready var lifetime_timer: Timer = $LifetimeTimer

#region Core Lifecycle
func _ready() -> void:
	assert(lifetime_timer != null, "EnemyProjectile requires LifetimeTimer")

	body_entered.connect(_on_body_entered)
	lifetime_timer.timeout.connect(queue_free)
	lifetime_timer.start(lifetime)


func _physics_process(delta_: float) -> void:
	global_position += direction * speed * delta_
#endregion

#region Public
func setup(direction_: Vector2, source_node_: Node2D) -> void:
	assert(source_node_ != null, "EnemyProjectile requires source_node")

	direction = direction_.normalized()
	source_node = source_node_
	rotation = direction.angle()
#endregion

#region Helpers
func _on_body_entered(body_: Node) -> void:
	var body_node_: Node2D = body_ as Node2D
	if body_node_ == null:
		queue_free()
		return

	if source_node != null and (body_node_ == source_node or source_node.is_ancestor_of(body_node_)):
		return

	var damage_receiver_: DamageReceiver = body_node_.get_node_or_null("DamageReceiver") as DamageReceiver
	if damage_receiver_ == null:
		queue_free()
		return

	var attack_context_: AttackContext = AttackContext.new()
	attack_context_.source_node = source_node
	attack_context_.attacker_node = source_node
	attack_context_.attacker_faction = &"enemy"
	attack_context_.base_damage = damage
	attack_context_.damage_type = &"physical"
	attack_context_.hitstop_duration_ms = hitstop_duration_ms
	attack_context_.hitstop_scale = hitstop_scale
	attack_context_.tags = [&"enemy", &"projectile"]

	damage_receiver_.receive_hit(attack_context_)
	queue_free()
#endregion
