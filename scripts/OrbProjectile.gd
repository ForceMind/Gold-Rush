extends Area2D
class_name OrbProjectile

# 围绕玩家旋转的魔球，接触敌人时造成伤害，然后消失。

signal hit_enemy(enemy: Enemy)
signal orb_hit(orb: OrbProjectile)

@export var orbit_radius: float = 80.0
@export var orbit_speed: float = 3.0
@export var damage: int = 1
@export var lifetime: float = 10.0

var center_node: Node2D
var current_angle: float = 0.0
var _previous_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_previous_position = global_position


func setup(center: Node2D, start_angle: float, orb_damage: int, orb_radius: float, orb_speed: float, size_scale: float) -> void:
	center_node = center
	current_angle = start_angle
	damage = orb_damage
	orbit_radius = orb_radius
	orbit_speed = orb_speed
	scale = Vector2.ONE * size_scale


func _physics_process(delta: float) -> void:
	if not is_instance_valid(center_node):
		queue_free()
		return

	current_angle += orbit_speed * delta
	global_position = center_node.global_position + Vector2.from_angle(current_angle) * orbit_radius
	rotation = current_angle

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not area is Enemy:
		return

	area.take_damage(damage)
	hit_enemy.emit(area)
	orb_hit.emit(self)
	queue_free.call_deferred()
