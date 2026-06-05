@tool
extends Control
class_name VirtualJoystick

# 虚拟摇杆组件

signal input_changed(direction: Vector2)

@export var joystick_radius: float = 70.0
@export var dead_zone: float = 0.15
@export var base_color: Color = Color(0.2, 0.2, 0.2, 0.4)
@export var knob_color: Color = Color(0.8, 0.8, 0.8, 0.7)

var is_pressed: bool = false
var touch_index: int = -1
var input_direction: Vector2 = Vector2.ZERO
var base_center: Vector2 = Vector2.ZERO

var base_rect: Rect2
var knob_position: Vector2


func _ready() -> void:
	base_center = Vector2(joystick_radius, joystick_radius)
	size = Vector2(joystick_radius * 2, joystick_radius * 2)
	knob_position = base_center
	base_rect = Rect2(Vector2.ZERO, size)

	# 连接输入事件
	gui_input.connect(_on_gui_input)


func _draw() -> void:
	# 绘制底座
	draw_circle(base_center, joystick_radius, base_color)
	draw_arc(base_center, joystick_radius, 0, TAU, 64, base_color.lightened(0.3), 2.0)

	# 绘制摇杆按钮
	draw_circle(knob_position, joystick_radius * 0.4, knob_color)
	draw_arc(knob_position, joystick_radius * 0.4, 0, TAU, 32, knob_color.lightened(0.3), 2.0)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_pressed = true
				_update_joystick(event.position)
			else:
				_reset_joystick()

	elif event is InputEventMouseMotion:
		if is_pressed:
			_update_joystick(event.position)

	elif event is InputEventScreenTouch:
		if event.pressed:
			is_pressed = true
			touch_index = event.index
			_update_joystick(event.position)
		elif event.index == touch_index:
			_reset_joystick()

	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			_update_joystick(event.position)


func _update_joystick(input_position: Vector2) -> void:
	var local_pos := input_position - base_center
	var dist := local_pos.length()

	if dist > joystick_radius:
		local_pos = local_pos.normalized() * joystick_radius

	# 更新摇杆按钮位置
	knob_position = base_center + local_pos

	# 计算输入方向
	var normalized := local_pos / joystick_radius
	if normalized.length() < dead_zone:
		input_direction = Vector2.ZERO
	else:
		input_direction = normalized

	queue_redraw()
	input_changed.emit(input_direction)


func _reset_joystick() -> void:
	is_pressed = false
	touch_index = -1
	input_direction = Vector2.ZERO
	knob_position = base_center
	queue_redraw()
	input_changed.emit(Vector2.ZERO)


func get_input_direction() -> Vector2:
	return input_direction
