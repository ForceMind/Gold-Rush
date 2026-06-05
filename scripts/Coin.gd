extends Area2D
class_name Coin

# 玩家碰到金币时发出收集信号。
signal collected(coin: Coin)

@export var value: int = 1

var was_collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if was_collected:
		return

	if body is Player:
		was_collected = true
		collected.emit(self)
