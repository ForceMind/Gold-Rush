extends Node2D
class_name ShieldVisual

# 护盾视觉效果，显示在玩家周围

var pulse_time: float = 0.0


func _process(delta: float) -> void:
	pulse_time += delta * 3.0
	queue_redraw()


func _draw() -> void:
	# 绘制保护罩
	var shield_color := Color(0.3, 0.8, 1.0, 0.2 + sin(pulse_time) * 0.1)
	var shield_border := Color(0.5, 1.0, 1.0, 0.6 + sin(pulse_time) * 0.2)
	draw_circle(Vector2.ZERO, 40.0, shield_color)
	draw_arc(Vector2.ZERO, 40.0, 0, TAU, 64, shield_border, 3.0)
	draw_arc(Vector2.ZERO, 45.0, 0, TAU, 64, Color(0.8, 1.0, 1.0, 0.3 + sin(pulse_time) * 0.1), 2.0)
