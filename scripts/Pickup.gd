extends Area2D
class_name Pickup

# 地图上可拾取的道具，玩家碰到后触发效果。

signal collected(pickup: Pickup)

enum Type {
	MAGNET,
	SHIELD,
	SPEED_BOOST,
	BOMB,
	DOUBLE_COIN,
}

const MAGNET_TEXTURE: Texture2D = preload("res://assets/pickup_magnet.svg")
const SHIELD_TEXTURE: Texture2D = preload("res://assets/pickup_shield.svg")
const SPEED_TEXTURE: Texture2D = preload("res://assets/pickup_speed.svg")
const BOMB_TEXTURE: Texture2D = preload("res://assets/pickup_bomb.svg")
const DOUBLE_TEXTURE: Texture2D = preload("res://assets/pickup_double.svg")

@export var lifetime: float = 30.0

var pickup_type: Type = Type.MAGNET
var was_collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_visual()


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

	# 闪烁效果（剩余5秒时开始）
	if lifetime < 5.0:
		visible = fmod(lifetime, 0.3) > 0.15


func setup(type: Type, spawn_position: Vector2) -> void:
	pickup_type = type
	global_position = spawn_position


func _apply_visual() -> void:
	var sprite := $Sprite2D as Sprite2D
	if sprite == null:
		return

	match pickup_type:
		Type.MAGNET:
			sprite.texture = MAGNET_TEXTURE
		Type.SHIELD:
			sprite.texture = SHIELD_TEXTURE
		Type.SPEED_BOOST:
			sprite.texture = SPEED_TEXTURE
		Type.BOMB:
			sprite.texture = BOMB_TEXTURE
		Type.DOUBLE_COIN:
			sprite.texture = DOUBLE_TEXTURE


func _on_body_entered(body: Node) -> void:
	if was_collected:
		return

	if body is Player:
		was_collected = true
		set_deferred("monitoring", false)
		collected.emit(self)


func get_type_name() -> String:
	match pickup_type:
		Type.MAGNET:
			return "磁力"
		Type.SHIELD:
			return "护盾"
		Type.SPEED_BOOST:
			return "加速鞋"
		Type.BOMB:
			return "炸弹"
		Type.DOUBLE_COIN:
			return "双倍金币"
	return "未知"
