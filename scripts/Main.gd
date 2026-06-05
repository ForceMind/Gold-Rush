extends Node2D

# 管理游戏主循环：生成、计分、升级选择、游戏结束和重开。
@export var play_area_size: Vector2 = Vector2(1280, 720)
@export var player_speed: float = 360.0
@export var enemy_speed: float = 120.0
@export var coin_spawn_interval: float = 1.0
@export var enemy_spawn_interval: float = 2.0
@export var max_coins: int = 10
@export var spawn_margin: float = 48.0
@export var initial_enemy_count: int = 1
@export var first_upgrade_score: int = 5
@export var upgrade_score_step_growth: int = 8
@export var max_coins_growth_per_level: int = 1
@export var base_max_enemies: int = 10
@export var max_enemies_growth_per_level: int = 4
@export var min_enemy_spawn_interval: float = 0.4
@export var enemy_spawn_interval_decrease_per_level: float = 0.1
@export var min_coin_spawn_interval: float = 0.3
@export var coin_spawn_interval_decrease_per_level: float = 0.05
@export var enemy_speed_growth_per_level: float = 0.12
@export var enemy_health_growth_per_level: float = 0.35
@export var enemy_flat_health_every_levels: int = 3
@export var coin_drop_chance: float = 0.25
@export var pickup_drop_chance: float = 0.15
@export var magnet_duration: float = 8.0
@export var magnet_range: float = 200.0
@export var shield_duration: float = 8.0
@export var speed_boost_duration: float = 6.0
@export var speed_boost_multiplier: float = 1.5
@export var double_coin_duration: float = 10.0
@export var bomb_radius: float = 250.0
@export var bomb_damage: int = 5

const COIN_SCENE: PackedScene = preload("res://scenes/Coin.tscn")
const PICKUP_SCENE: PackedScene = preload("res://scenes/Pickup.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/Enemy.tscn")
const START_SCREEN_SCENE: PackedScene = preload("res://scenes/StartScreen.tscn")
const MONSTER_SLIME_TEXTURE: Texture2D = preload("res://assets/monster_slime.svg")
const MONSTER_WISP_TEXTURE: Texture2D = preload("res://assets/monster_wisp.svg")
const MONSTER_BRUTE_TEXTURE: Texture2D = preload("res://assets/monster_brute.svg")

@onready var player: Player = $Player
@onready var coins: Node2D = $Coins
@onready var enemies: Node2D = $Enemies
@onready var projectiles: Node2D = $Projectiles
@onready var pickups: Node2D = $Pickups
@onready var weapon_controller: WeaponController = $WeaponController
@onready var coin_timer: Timer = $CoinTimer
@onready var enemy_timer: Timer = $EnemyTimer
@onready var ui: GameUI = $UI

var score: int = 0
var level: int = 1
var next_upgrade_score: int = 6
var current_upgrade_step: int = 6
var is_game_over: bool = false
var is_choosing_upgrade: bool = false
var start_screen: StartScreen = null


func _ready() -> void:
	randomize()
	coin_timer.timeout.connect(_on_coin_timer_timeout)
	enemy_timer.timeout.connect(_on_enemy_timer_timeout)
	ui.upgrade_selected.connect(_on_upgrade_selected)
	ui.back_to_menu.connect(_on_back_to_menu)
	ui.restart_game.connect(start_game)
	ui.set_player(player)
	_show_start_screen()


func _show_start_screen() -> void:
	start_screen = START_SCREEN_SCENE.instantiate() as StartScreen
	add_child(start_screen)
	start_screen.start_game.connect(_on_start_game)
	_set_world_running(false)
	player.hide()


func _on_start_game() -> void:
	if start_screen != null:
		start_screen.queue_free()
		start_screen = null
	start_game()


func _process(delta: float) -> void:
	_process_magnet_effect(delta)
	_update_skill_cooldown_bars()


func _unhandled_input(event: InputEvent) -> void:
	# 开始界面显示时不允许按 R 键
	if start_screen != null:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			start_game()

	if is_game_over and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			start_game()


func start_game() -> void:
	score = 0
	level = 1
	current_upgrade_step = first_upgrade_score
	next_upgrade_score = current_upgrade_step
	is_game_over = false
	is_choosing_upgrade = false
	_clear_container(coins)
	_clear_container(enemies)
	_clear_container(projectiles)
	_clear_container(pickups)

	player.speed = player_speed
	player.base_speed = player_speed
	player.play_area = Rect2(Vector2.ZERO, play_area_size)
	player.global_position = play_area_size * 0.5
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	player.show()

	weapon_controller.player = player
	weapon_controller.enemies = enemies
	weapon_controller.projectiles = projectiles
	weapon_controller.reset()

	ui.set_score(score)
	ui.set_level(level, next_upgrade_score)
	ui.set_weapon_stats(weapon_controller.get_stats_text())
	ui.hide_game_over()
	ui.hide_upgrade_choices()

	_apply_progression_values()

	spawn_coin()
	for _i in range(initial_enemy_count):
		spawn_enemy()


func spawn_coin() -> void:
	if is_game_over or coins.get_child_count() >= _get_current_max_coins():
		return

	var coin := COIN_SCENE.instantiate() as Coin
	coin.position = _random_point_away_from_player(96.0)
	coin.collected.connect(_on_coin_collected)
	coins.add_child(coin)


func spawn_enemy() -> void:
	if is_game_over or enemies.get_child_count() >= _get_current_max_enemies():
		return

	var spawn_position := _random_edge_point_away_from_player(150.0)
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.position = spawn_position
	var enemy_data := _pick_enemy_data()
	enemy.set_meta("speed_scale", float(enemy_data["speed_scale"]))
	enemy.set_meta("base_health", int(enemy_data["base_health"]))
	enemy.set_meta("score", int(enemy_data["score"]))
	enemy.configure(
		player,
		_get_enemy_speed(enemy_data),
		_get_enemy_health(enemy_data),
		enemy_data["texture"] as Texture2D,
		float(enemy_data.get("scale", 1.0)),
		enemy_data.get("modulate", Color.WHITE)
	)
	enemy.hit_player.connect(_on_player_hit)
	enemy.died.connect(_on_enemy_died)
	enemies.add_child(enemy)


func _on_coin_timer_timeout() -> void:
	spawn_coin()


func _on_enemy_timer_timeout() -> void:
	spawn_enemy()


func spawn_pickup(spawn_position: Vector2) -> void:
	if is_game_over:
		return

	var pickup := PICKUP_SCENE.instantiate() as Pickup
	var pickup_type := _random_pickup_type()
	pickup.setup(pickup_type, spawn_position)
	pickup.collected.connect(_on_pickup_collected)
	pickups.add_child(pickup)


func _random_pickup_type() -> Pickup.Type:
	var types: Array[Pickup.Type] = [
		Pickup.Type.MAGNET,
		Pickup.Type.SHIELD,
		Pickup.Type.SPEED_BOOST,
		Pickup.Type.BOMB,
		Pickup.Type.DOUBLE_COIN,
	]
	return types[randi() % types.size()]


func _on_pickup_collected(pickup: Pickup) -> void:
	if is_game_over:
		return

	match pickup.pickup_type:
		Pickup.Type.MAGNET:
			player.apply_pickup_magnet(magnet_duration, magnet_range)
		Pickup.Type.SHIELD:
			player.apply_pickup_shield(shield_duration)
		Pickup.Type.SPEED_BOOST:
			player.apply_pickup_speed_boost(speed_boost_duration, speed_boost_multiplier)
		Pickup.Type.BOMB:
			_activate_bomb()
		Pickup.Type.DOUBLE_COIN:
			player.apply_pickup_double_coin(double_coin_duration)

	var _am = get_node_or_null("/root/AudioManager")
	if _am: _am.play_pickup_collect()
	pickup.queue_free()


func _activate_bomb() -> void:
	for enemy in enemies.get_children():
		if not enemy is Enemy:
			continue

		var distance := player.global_position.distance_to(enemy.global_position)
		if distance <= bomb_radius:
			enemy.take_damage(bomb_damage)

	var _am = get_node_or_null("/root/AudioManager")
	if _am: _am.play_explosion()


func _process_magnet_effect(delta: float) -> void:
	if not player.has_magnet:
		return

	for coin in coins.get_children():
		if not coin is Coin:
			continue

		var distance = player.global_position.distance_to(coin.global_position)
		if distance <= player.magnet_range:
			var direction = coin.global_position.direction_to(player.global_position)
			coin.global_position += direction * 400.0 * delta


func _on_coin_collected(coin: Coin) -> void:
	if is_game_over:
		return

	var coin_value := coin.value
	if player.has_double_coin:
		coin_value *= 2
	score += coin_value
	ui.set_score(score)
	coin.queue_free()
	var _am = get_node_or_null("/root/AudioManager")
	if _am: _am.play_coin_collect()
	spawn_coin()

	if score >= next_upgrade_score:
		_open_upgrade_choices()


func _on_player_hit() -> void:
	if is_game_over:
		return

	# 检查护盾
	if player.use_shield():
		var _am = get_node_or_null("/root/AudioManager")
		if _am: _am.play_shield_block()
		return

	is_game_over = true
	coin_timer.stop()
	enemy_timer.stop()
	player.velocity = Vector2.ZERO
	_set_world_running(false)
	var _am = get_node_or_null("/root/AudioManager")
	if _am: _am.play_game_over()

	ui.show_game_over(score)


func _on_enemy_died(enemy: Enemy) -> void:
	if is_game_over:
		return

	var enemy_score := int(enemy.get_meta("score", 1))
	score += enemy_score
	ui.set_score(score)
	var _am = get_node_or_null("/root/AudioManager")
	if _am: _am.play_enemy_die()

	if randf() < coin_drop_chance:
		spawn_coin()

	if randf() < pickup_drop_chance:
		spawn_pickup(enemy.global_position)

	if score >= next_upgrade_score:
		_open_upgrade_choices()


func _open_upgrade_choices() -> void:
	if is_game_over or is_choosing_upgrade:
		return

	level += 1
	current_upgrade_step += upgrade_score_step_growth
	next_upgrade_score += current_upgrade_step
	is_choosing_upgrade = true
	_apply_progression_values()
	_set_world_running(false)
	ui.set_level(level, next_upgrade_score)
	var _am = get_node_or_null("/root/AudioManager")
	if _am: _am.play_upgrade_select()
	ui.show_upgrade_choices(weapon_controller.get_random_upgrade_choices(3))


func _on_upgrade_selected(upgrade_id: String) -> void:
	if is_game_over:
		return

	weapon_controller.apply_upgrade(upgrade_id)
	ui.set_weapon_stats(weapon_controller.get_stats_text())
	is_choosing_upgrade = false

	# 延迟一秒后恢复游戏，避免鼠标控制影响移动方向
	await get_tree().create_timer(1.0).timeout
	_apply_progression_values()
	_set_world_running(true)


func _random_point_inside() -> Vector2:
	return Vector2(
		randf_range(spawn_margin, play_area_size.x - spawn_margin),
		randf_range(spawn_margin, play_area_size.y - spawn_margin)
	)


func _random_point_away_from_player(min_distance: float) -> Vector2:
	var point := Vector2.ZERO

	for _attempt in range(12):
		point = _random_point_inside()
		if point.distance_to(player.global_position) >= min_distance:
			return point

	return point


func _random_edge_point() -> Vector2:
	match randi() % 4:
		0:
			return Vector2(randf_range(spawn_margin, play_area_size.x - spawn_margin), spawn_margin)
		1:
			return Vector2(randf_range(spawn_margin, play_area_size.x - spawn_margin), play_area_size.y - spawn_margin)
		2:
			return Vector2(spawn_margin, randf_range(spawn_margin, play_area_size.y - spawn_margin))
		_:
			return Vector2(play_area_size.x - spawn_margin, randf_range(spawn_margin, play_area_size.y - spawn_margin))


func _random_edge_point_away_from_player(min_distance: float) -> Vector2:
	var point := Vector2.ZERO

	for _attempt in range(12):
		point = _random_edge_point()
		if point.distance_to(player.global_position) >= min_distance:
			return point

	return point


func _pick_enemy_data() -> Dictionary:
	var enemy_pool: Array[Dictionary] = [
		{
			"texture": MONSTER_SLIME_TEXTURE,
			"speed_scale": 0.85,
			"base_health": 3,
			"scale": 0.9,
			"weight": 60,
			"score": 1,
			"modulate": Color.WHITE
		},
		{
			"texture": MONSTER_WISP_TEXTURE,
			"speed_scale": 1.3,
			"base_health": 2,
			"scale": 0.8,
			"weight": 30,
			"score": 2,
			"modulate": Color.WHITE
		},
	]

	if level >= 3:
		enemy_pool.append({
			"texture": MONSTER_BRUTE_TEXTURE,
			"speed_scale": 0.65,
			"base_health": 6,
			"scale": 1.1,
			"weight": 15 + min(20, (level - 3) * 3),
			"score": 3,
			"modulate": Color.WHITE
		})

	if level >= 5:
		enemy_pool.append({
			"texture": MONSTER_SLIME_TEXTURE,
			"speed_scale": 0.5,
			"base_health": 20,
			"scale": 1.8,
			"weight": 5 + (level - 5) * 2,
			"score": 5,
			"modulate": Color(0.3, 1.0, 0.4) # Green/Purple tint equivalent
		})

	if level >= 8:
		enemy_pool.append({
			"texture": MONSTER_WISP_TEXTURE,
			"speed_scale": 1.8,
			"base_health": 3,
			"scale": 0.6,
			"weight": 5 + (level - 8) * 2,
			"score": 3,
			"modulate": Color(0.8, 0.1, 0.2) # Dark/Red tint
		})

	if level >= 12:
		enemy_pool.append({
			"texture": MONSTER_BRUTE_TEXTURE,
			"speed_scale": 0.8,
			"base_health": 45,
			"scale": 1.5,
			"weight": 3 + (level - 12) * 2,
			"score": 10,
			"modulate": Color(1.0, 0.2, 0.2) # Crimson tint
		})

	var total_weight := 0
	for enemy_data in enemy_pool:
		total_weight += int(enemy_data["weight"])

	var roll := randi_range(1, total_weight)
	var accumulated := 0

	for enemy_data in enemy_pool:
		accumulated += int(enemy_data["weight"])
		if roll <= accumulated:
			return enemy_data

	return enemy_pool[0]


func _apply_progression_values() -> void:
	coin_timer.wait_time = _get_current_coin_spawn_interval()
	enemy_timer.wait_time = _get_current_enemy_spawn_interval()
	_refresh_existing_enemy_values()
	coin_timer.start()
	enemy_timer.start()


func _get_level_step() -> int:
	return max(0, level - 1)


func _get_current_max_coins() -> int:
	return max_coins + _get_level_step() * max_coins_growth_per_level


func _get_current_max_enemies() -> int:
	return base_max_enemies + _get_level_step() * max_enemies_growth_per_level


func _get_current_enemy_spawn_interval() -> float:
	return max(min_enemy_spawn_interval, enemy_spawn_interval - float(_get_level_step()) * enemy_spawn_interval_decrease_per_level)


func _get_current_coin_spawn_interval() -> float:
	return max(min_coin_spawn_interval, coin_spawn_interval - float(_get_level_step()) * coin_spawn_interval_decrease_per_level)


func _get_enemy_speed(enemy_data: Dictionary) -> float:
	var speed_scale := 1.0 + float(_get_level_step()) * enemy_speed_growth_per_level
	return enemy_speed * float(enemy_data["speed_scale"]) * speed_scale


func _get_enemy_health(enemy_data: Dictionary) -> int:
	return _calculate_enemy_health(int(enemy_data["base_health"]))


func _calculate_enemy_health(base_health: int) -> int:
	var scale_bonus := int(ceil(float(base_health) * float(_get_level_step()) * enemy_health_growth_per_level))
	var flat_bonus := 0

	if enemy_flat_health_every_levels > 0:
		flat_bonus = int(floor(float(_get_level_step()) / float(enemy_flat_health_every_levels)))

	return max(base_health, base_health + scale_bonus + flat_bonus)


func _refresh_existing_enemy_values() -> void:
	var speed_level_scale := 1.0 + float(_get_level_step()) * enemy_speed_growth_per_level

	for enemy in enemies.get_children():
		if not enemy is Enemy:
			continue

		var base_health := int(enemy.get_meta("base_health", enemy.max_health))
		var speed_scale := float(enemy.get_meta("speed_scale", 1.0))
		var new_max_health := _calculate_enemy_health(base_health)
		var health_gain: int = maxi(0, new_max_health - enemy.max_health)

		enemy.max_health = new_max_health
		enemy.health += health_gain
		enemy.speed = enemy_speed * speed_scale * speed_level_scale
		enemy.refresh_health_bar()


func _set_world_running(value: bool) -> void:
	player.set_physics_process(value)
	weapon_controller.set_active(value)

	for enemy in enemies.get_children():
		enemy.set_physics_process(value)

	for projectile in projectiles.get_children():
		projectile.set_physics_process(value)

	if value:
		coin_timer.start()
		enemy_timer.start()
	else:
		coin_timer.stop()
		enemy_timer.stop()


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.free()


func _on_back_to_menu() -> void:
	is_game_over = false
	is_choosing_upgrade = false
	_clear_container(coins)
	_clear_container(enemies)
	_clear_container(projectiles)
	_clear_container(pickups)
	player.hide()
	ui.hide_game_over()
	ui.hide_upgrade_choices()
	coin_timer.stop()
	enemy_timer.stop()
	_show_start_screen()


func _update_skill_cooldown_bars() -> void:
	var nova_pct := -1.0
	var orb_pct := -1.0
	var freeze_pct := -1.0

	if weapon_controller.has_nova_blast:
		nova_pct = weapon_controller.nova_timer / weapon_controller.nova_cooldown if weapon_controller.nova_cooldown > 0 else 0.0
	if weapon_controller.has_orbit_balls:
		orb_pct = weapon_controller.orbit_timer / weapon_controller.orbit_cooldown if weapon_controller.orbit_cooldown > 0 else 0.0
	if weapon_controller.has_freeze_field:
		freeze_pct = weapon_controller.freeze_timer / weapon_controller.freeze_cooldown if weapon_controller.freeze_cooldown > 0 else 0.0

	ui.update_skill_cooldowns(nova_pct, orb_pct, freeze_pct)
