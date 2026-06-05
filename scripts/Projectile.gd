extends Area2D
class_name Projectile

# 简单魔弹：向前飞行，并伤害碰到的妖怪。
@export var speed: float = 620.0
@export var damage: int = 1
@export var pierce: int = 0
@export var lifetime: float = 1.8

var direction: Vector2 = Vector2.RIGHT
var hit_targets: Dictionary = {}


func setup(start_position: Vector2, move_direction: Vector2, projectile_speed: float, projectile_damage: int, projectile_pierce: int, size_scale: float) -> void:
	global_position = start_position
	direction = move_direction.normalized()
	speed = projectile_speed
	damage = projectile_damage
	pierce = projectile_pierce
	scale = Vector2.ONE * size_scale
	rotation = direction.angle()


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not area is Enemy:
		return

	var enemy_id := area.get_instance_id()
	if hit_targets.has(enemy_id):
		return

	hit_targets[enemy_id] = true
	area.take_damage(damage)
	var _am = get_node_or_null("/root/AudioManager")
	if _am: _am.play_enemy_hit()
	pierce -= 1

	if pierce < 0:
		queue_free.call_deferred()
