extends Area2D
class_name OrbProjectile

# 围绕玩家旋转的魔球，接触敌人时造成伤害，然后消失。
signal hit_enemy(enemy: Enemy)

var damage: int = 1
var orbit_radius: float = 80.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)


func setup(_center: Node2D, _start_angle: float, orb_damage: int, orb_radius: float, _orb_speed: float, size_scale: float) -> void:
	damage = orb_damage
	orbit_radius = orb_radius
	scale = Vector2.ONE * size_scale


func update_orbit(center_pos: Vector2, angle: float) -> void:
	global_position = center_pos + Vector2.from_angle(angle) * orbit_radius
	rotation = angle


func _on_area_entered(area: Area2D) -> void:
	if not area is Enemy:
		return

	area.take_damage(damage)
	hit_enemy.emit(area)
	queue_free.call_deferred()
