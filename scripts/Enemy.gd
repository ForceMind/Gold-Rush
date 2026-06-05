extends Area2D
class_name Enemy

# 朝玩家移动，承受魔弹伤害，并汇报碰撞和死亡。
signal hit_player
signal died(enemy: Enemy)

@export var speed: float = 150.0
@export var max_health: int = 2

@onready var health_back: ColorRect = $HealthBack
@onready var health_fill: ColorRect = $HealthBack/HealthFill
@onready var sprite: Sprite2D = $Sprite2D

var target: Node2D
var health: int = 2
var base_speed: float = 150.0
var is_frozen: bool = false
var freeze_timer: float = 0.0
var original_modulate: Color


func _ready() -> void:
	health = max_health
	body_entered.connect(_on_body_entered)
	refresh_health_bar()
	original_modulate = sprite.modulate


func _physics_process(delta: float) -> void:
	# 冰冻状态
	if is_frozen:
		freeze_timer -= delta
		if freeze_timer <= 0.0:
			_unfreeze()
		return

	if target == null or not is_instance_valid(target):
		return

	var direction := global_position.direction_to(target.global_position)
	if direction == Vector2.ZERO:
		return

	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if is_frozen:
		return
	if body is Player:
		hit_player.emit()


func configure(target_node: Node2D, move_speed: float, enemy_health: int, texture: Texture2D, visual_scale: float, modulate_color: Color = Color.WHITE) -> void:
	target = target_node
	speed = move_speed
	base_speed = move_speed
	max_health = enemy_health
	health = max_health
	scale = Vector2.ONE * visual_scale
	$Sprite2D.texture = texture
	$Sprite2D.modulate = modulate_color
	original_modulate = modulate_color
	refresh_health_bar()


func take_damage(amount: int) -> void:
	health -= amount
	refresh_health_bar()

	if health <= 0:
		died.emit(self)
		queue_free.call_deferred()


func freeze(duration: float) -> void:
	is_frozen = true
	freeze_timer = duration
	speed = 0.0
	sprite.modulate = Color(0.5, 0.8, 1.0, 0.9)

	# 添加冰冻粒子效果
	var frozen_indicator := ColorRect.new()
	frozen_indicator.size = Vector2(8, 8)
	frozen_indicator.position = Vector2(-4, -4)
	frozen_indicator.color = Color(0.3, 0.6, 1.0, 0.8)
	frozen_indicator.name = "FrozenIndicator"
	add_child(frozen_indicator)


func _unfreeze() -> void:
	is_frozen = false
	speed = base_speed
	sprite.modulate = original_modulate

	var frozen_indicator := get_node_or_null("FrozenIndicator")
	if frozen_indicator:
		frozen_indicator.queue_free()


func refresh_health_bar() -> void:
	if not is_node_ready():
		return

	var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	health_back.visible = max_health > 1
	health_fill.size = Vector2(48.0 * ratio, 5.0)
