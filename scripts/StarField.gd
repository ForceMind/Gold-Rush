extends Node2D
class_name StarField

# 星星背景动画

var stars: Array = []
var time: float = 0.0
var screen_width: float = 1280.0
var screen_height: float = 720.0


func _ready() -> void:
	# 获取实际屏幕尺寸
	screen_width = get_viewport_rect().size.x
	screen_height = get_viewport_rect().size.y
	_create_stars()


func _create_stars() -> void:
	for i in range(50):
		var star := Vector2(
			randf_range(0, screen_width),
			randf_range(0, screen_height)
		)
		var star_data := {
			"pos": star,
			"speed": randf_range(0.3, 1.5),
			"size": randf_range(1.0, 3.0),
			"brightness": randf_range(0.3, 1.0)
		}
		stars.append(star_data)


func _process(delta: float) -> void:
	time += delta

	for star in stars:
		star["pos"].y += star["speed"] * 20.0 * delta
		if star["pos"].y > screen_height:
			star["pos"].y = 0
			star["pos"].x = randf_range(0, screen_width)

	queue_redraw()


func _draw() -> void:
	for star in stars:
		var alpha = star["brightness"] * (0.5 + 0.5 * sin(time * star["speed"] * 3.0))
		var color = Color(1, 0.9, 0.6, alpha)
		draw_circle(star["pos"], star["size"], color)
