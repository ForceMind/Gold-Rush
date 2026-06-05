extends CharacterBody2D
class_name Player

# 处理键盘、鼠标、摇杆移动，并把玩家限制在地图区域内。
@export var speed: float = 360.0
@export var edge_padding: float = 28.0

var play_area: Rect2 = Rect2(Vector2.ZERO, Vector2(1280, 720))
var joystick_direction: Vector2 = Vector2.ZERO
var use_mouse_control: bool = false
var mouse_target: Vector2 = Vector2.ZERO

# 道具状态
var base_speed: float = 360.0
var has_magnet: bool = false
var magnet_timer: float = 0.0
var magnet_range: float = 200.0
var has_shield: bool = false
var shield_timer: float = 0.0
var speed_boost_timer: float = 0.0
var has_double_coin: bool = false
var double_coin_timer: float = 0.0
var shield_visual: Node2D = null


func reset_pickups() -> void:
	has_magnet = false
	magnet_timer = 0.0
	has_shield = false
	shield_timer = 0.0
	speed_boost_timer = 0.0
	has_double_coin = false
	double_coin_timer = 0.0
	speed = base_speed
	_remove_shield_visual()

func _physics_process(delta: float) -> void:
	var direction := _read_movement_input()

	if use_mouse_control and _is_mouse_in_play_area():
		mouse_target = get_global_mouse_position()
		var to_mouse := mouse_target - global_position
		if to_mouse.length() > 10.0:
			direction = to_mouse.normalized()
		else:
			direction = Vector2.ZERO

	velocity = direction * speed
	move_and_slide()
	_keep_inside_play_area()
	_update_pickup_effects(delta)


func _read_movement_input() -> Vector2:
	# 优先使用摇杆输入
	if joystick_direction != Vector2.ZERO:
		return joystick_direction

	# 键盘输入
	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0

	return direction.normalized() if direction.length_squared() > 0.0 else Vector2.ZERO


func _is_mouse_in_play_area() -> bool:
	var mouse_pos := get_global_mouse_position()
	return play_area.has_point(mouse_pos)


func set_joystick_direction(direction: Vector2) -> void:
	joystick_direction = direction


func set_mouse_control(enabled: bool) -> void:
	use_mouse_control = enabled


func _keep_inside_play_area() -> void:
	var min_pos := play_area.position + Vector2(edge_padding, edge_padding)
	var max_pos := play_area.position + play_area.size - Vector2(edge_padding, edge_padding)

	global_position.x = clampf(global_position.x, min_pos.x, max_pos.x)
	global_position.y = clampf(global_position.y, min_pos.y, max_pos.y)


func _update_pickup_effects(delta: float) -> void:
	# 磁力计时
	if has_magnet:
		magnet_timer -= delta
		if magnet_timer <= 0.0:
			has_magnet = false

	# 护盾计时
	if has_shield:
		shield_timer -= delta
		if shield_timer <= 0.0:
			has_shield = false
			_remove_shield_visual()

	# 加速计时
	if speed_boost_timer > 0.0:
		speed_boost_timer -= delta
		if speed_boost_timer <= 0.0:
			speed = base_speed

	# 双倍金币计时
	if has_double_coin:
		double_coin_timer -= delta
		if double_coin_timer <= 0.0:
			has_double_coin = false


func apply_pickup_magnet(duration: float, range_value: float) -> void:
	has_magnet = true
	magnet_timer = duration
	magnet_range = range_value


func apply_pickup_shield(duration: float) -> void:
	has_shield = true
	shield_timer = duration
	_create_shield_visual()


func apply_pickup_speed_boost(duration: float, multiplier: float) -> void:
	speed = base_speed * multiplier
	speed_boost_timer = duration


func apply_pickup_double_coin(duration: float) -> void:
	has_double_coin = true
	double_coin_timer = duration


func use_shield() -> bool:
	if has_shield:
		has_shield = false
		shield_timer = 0.0
		_remove_shield_visual()
		return true
	return false


func _create_shield_visual() -> void:
	if shield_visual != null:
		shield_visual.queue_free()

	shield_visual = ShieldVisual.new()
	shield_visual.name = "ShieldVisual"
	add_child(shield_visual)


func _remove_shield_visual() -> void:
	if shield_visual != null:
		shield_visual.queue_free()
		shield_visual = null
