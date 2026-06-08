extends Node2D
class_name WeaponController

# 自动发射魔弹，并保存 Roguelike 武器升级。
@export var base_fire_interval: float = 0.65
@export var base_projectile_speed: float = 620.0
@export var base_damage: int = 1
@export var base_pierce: int = 0
@export var base_projectile_count: int = 1
@export var base_projectile_scale: float = 1.0
@export var quick_cast_reduce_percent: int = 14
@export var heavy_bolt_damage_bonus: int = 1
@export var split_bolt_count_bonus: int = 1
@export var piercing_bolt_bonus: int = 1
@export var swift_bolt_speed_bonus: float = 100.0
@export var large_bolt_scale_bonus_percent: int = 12
@export var nova_cooldown_base: float = 8.0
@export var nova_bolts_base: int = 12
@export var orbit_cooldown_base: float = 5.0
@export var orbit_balls_base: int = 3
@export var orbit_radius_base: float = 80.0
@export var orbit_speed_base: float = 3.0
@export var orbit_damage_multiplier: float = 2.0
@export var freeze_cooldown_base: float = 12.0
@export var freeze_duration_base: float = 2.5
@export var freeze_radius_base: float = 250.0

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/Projectile.tscn")
const ORB_PROJECTILE_SCENE: PackedScene = preload("res://scenes/OrbProjectile.tscn")

var player: Node2D
var enemies: Node2D
var projectiles: Node2D
var active: bool = true

var fire_interval: float
var projectile_speed: float
var damage: int
var pierce: int
var projectile_count: int
var projectile_scale: float
var spread_angle: float
var cooldown: float = 0.0

# 新技能
var has_nova_blast: bool = false
var nova_cooldown: float = 0.0
var nova_timer: float = 0.0
var nova_bolts: int = 12

var has_orbit_balls: bool = false
var orbit_cooldown: float = 0.0
var orbit_timer: float = 0.0
var orbit_balls: int = 3
var orbit_radius: float = 80.0
var orbit_speed: float = 3.0
var global_orbit_angle: float = 0.0
var orb_slots: Array[OrbProjectile] = []
var orb_restore_timers: Array[float] = []

var has_freeze_field: bool = false
var freeze_cooldown: float = 0.0
var freeze_timer: float = 0.0
var freeze_duration: float = 2.5
var freeze_radius: float = 250.0


func reset() -> void:
	fire_interval = base_fire_interval
	projectile_speed = base_projectile_speed
	damage = base_damage
	pierce = base_pierce
	projectile_count = base_projectile_count
	projectile_scale = base_projectile_scale
	spread_angle = 0.18
	cooldown = 0.2
	active = true

	has_nova_blast = false
	nova_cooldown = nova_cooldown_base
	nova_timer = 0.0
	nova_bolts = nova_bolts_base

	has_orbit_balls = false
	orbit_cooldown = orbit_cooldown_base
	orbit_timer = 0.0
	orbit_balls = orbit_balls_base
	orbit_radius = orbit_radius_base
	orbit_speed = orbit_speed_base
	for orb in orb_slots:
		if is_instance_valid(orb):
			orb.queue_free()
	orb_slots.clear()
	orb_restore_timers.clear()
	global_orbit_angle = 0.0

	has_freeze_field = false
	freeze_cooldown = freeze_cooldown_base
	freeze_timer = 0.0
	freeze_duration = freeze_duration_base
	freeze_radius = freeze_radius_base


func set_active(value: bool) -> void:
	active = value


func _physics_process(delta: float) -> void:
	if not active or player == null or enemies == null or projectiles == null:
		return

	# 普通射击
	cooldown -= delta
	if cooldown <= 0.0:
		var target := _find_nearest_enemy()
		if target != null:
			_fire_at(target.global_position)
			cooldown = fire_interval

	# 新星爆发（自动触发）
	if has_nova_blast:
		nova_timer -= delta
		if nova_timer <= 0.0:
			_fire_nova()
			nova_timer = nova_cooldown

	# 环绕球（常驻状态，固定槽位以保证均匀分布）
	if has_orbit_balls:
		while orb_slots.size() < orbit_balls:
			orb_slots.append(null)
			orb_restore_timers.append(0.0)

		global_orbit_angle += orbit_speed * delta
		var angle_step := TAU / float(orbit_balls)

		for i in range(orbit_balls):
			var orb := orb_slots[i]
			if orb != null:
				if is_instance_valid(orb):
					orb.update_orbit(player.global_position, global_orbit_angle + angle_step * float(i))
				else:
					orb_slots[i] = null
					orb_restore_timers[i] = orbit_cooldown

			if orb_slots[i] == null:
				orb_restore_timers[i] -= delta
				if orb_restore_timers[i] <= 0.0:
					_spawn_orb_in_slot(i)

	# 冰冻领域（自动触发）
	if has_freeze_field:
		freeze_timer -= delta
		if freeze_timer <= 0.0:
			_activate_freeze_field()
			freeze_timer = freeze_cooldown


func get_random_upgrade_choices(count: int) -> Array[Dictionary]:
	var pool := _get_upgrade_pool()
	pool.shuffle()
	var choices: Array[Dictionary] = []

	for index in range(min(count, pool.size())):
		choices.append(pool[index])

	return choices


func apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"quick_cast":
			var multiplier := 1.0 - float(quick_cast_reduce_percent) / 100.0
			fire_interval = max(0.18, fire_interval * multiplier)
		"heavy_bolt":
			damage += heavy_bolt_damage_bonus
		"split_bolt":
			projectile_count += split_bolt_count_bonus
		"piercing_bolt":
			pierce += piercing_bolt_bonus
		"swift_bolt":
			projectile_speed += swift_bolt_speed_bonus
		"large_bolt":
			projectile_scale += float(large_bolt_scale_bonus_percent) / 100.0
		"nova_blast":
			has_nova_blast = true
			nova_bolts = nova_bolts_base
		"nova_upgrade":
			nova_bolts += 4
			nova_cooldown = max(3.0, nova_cooldown - 1.0)
		"orbit_balls":
			has_orbit_balls = true
			orbit_balls = orbit_balls_base
			orbit_radius = orbit_radius_base
			orbit_speed = orbit_speed_base
		"orbit_upgrade":
			orbit_balls += 2
			orbit_cooldown = max(2.0, orbit_cooldown - 0.5)
			orbit_radius += 10.0
			orbit_speed += 0.3
		"freeze_field":
			has_freeze_field = true
			freeze_duration = freeze_duration_base
			freeze_radius = freeze_radius_base
		"freeze_upgrade":
			freeze_duration += 0.8
			freeze_radius += 50.0
			freeze_cooldown = max(5.0, freeze_cooldown - 1.5)


func get_stats_text() -> String:
	var text := "武器：魔弹  伤害 %d  数量 %d  穿透 %d  间隔 %.2f 秒" % [
		damage,
		projectile_count,
		pierce,
		fire_interval,
	]
	if has_nova_blast:
		text += "\n新星爆发：%d 发 / %.1f 秒" % [nova_bolts, nova_cooldown]
	if has_orbit_balls:
		text += "\n环绕球：%d 个 / %.0f 范围" % [orbit_balls, orbit_radius]
	if has_freeze_field:
		text += "\n冰冻领域：%.1f 秒 / %.0f 范围" % [freeze_duration, freeze_radius]
	return text


func _get_upgrade_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = [
		{"id": "quick_cast", "name": "疾速施法", "description": "射击间隔缩短 %d%%。" % quick_cast_reduce_percent},
		{"id": "heavy_bolt", "name": "重击魔弹", "description": "魔弹伤害 +%d。" % heavy_bolt_damage_bonus},
		{"id": "split_bolt", "name": "分裂魔弹", "description": "每次多发射 %d 枚魔弹。" % split_bolt_count_bonus},
		{"id": "piercing_bolt", "name": "穿透魔弹", "description": "魔弹额外穿透 %d 个妖怪。" % piercing_bolt_bonus},
		{"id": "swift_bolt", "name": "迅捷魔弹", "description": "魔弹速度 +%d。" % int(swift_bolt_speed_bonus)},
		{"id": "large_bolt", "name": "巨型魔弹", "description": "魔弹尺寸 +%d%%。" % large_bolt_scale_bonus_percent},
	]

	if not has_nova_blast:
		pool.append({"id": "nova_blast", "name": "新星爆发", "description": "每 %.1f 秒向四周发射 %d 枚魔弹。" % [nova_cooldown_base, nova_bolts_base]})
	else:
		pool.append({"id": "nova_upgrade", "name": "新星强化", "description": "新星 +4 发，冷却 -1 秒。"})

	if not has_orbit_balls:
		pool.append({"id": "orbit_balls", "name": "环绕魔球", "description": "生成 %d 个环绕魔球。" % orbit_balls_base})
	else:
		pool.append({"id": "orbit_upgrade", "name": "环绕强化", "description": "环绕球 +2 个，恢复时间 -0.5 秒。"})

	if not has_freeze_field:
		pool.append({"id": "freeze_field", "name": "冰冻领域", "description": "每 %.1f 秒冻住周围怪物 %.1f 秒。" % [freeze_cooldown_base, freeze_duration_base]})
	else:
		pool.append({"id": "freeze_upgrade", "name": "冰冻强化", "description": "冰冻 +0.8 秒，范围 +50，冷却 -1.5 秒。"})

	return pool


func _find_nearest_enemy() -> Enemy:
	var nearest: Enemy = null
	var nearest_distance := INF

	for enemy in enemies.get_children():
		if not enemy is Enemy:
			continue

		var distance := player.global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy

	return nearest


func _fire_at(target_position: Vector2) -> void:
	var base_direction := player.global_position.direction_to(target_position)
	if base_direction == Vector2.ZERO:
		base_direction = Vector2.RIGHT

	var angle_step := TAU / float(projectile_count) if projectile_count > 1 else 0.0

	for index in range(projectile_count):
		var angle_offset := angle_step * float(index)
		var direction := base_direction.rotated(angle_offset)
		var projectile := PROJECTILE_SCENE.instantiate() as Projectile
		projectiles.add_child(projectile)
		projectile.setup(
			player.global_position + direction * 34.0,
			direction,
			projectile_speed,
			damage,
			pierce,
			projectile_scale
		)

	var _am = get_node_or_null("/root/AudioManager")
	if _am: _am.play_shoot()


func _fire_nova() -> void:
	var angle_step := TAU / float(nova_bolts)

	for index in range(nova_bolts):
		var angle := angle_step * float(index)
		var direction := Vector2.from_angle(angle)
		var projectile := PROJECTILE_SCENE.instantiate() as Projectile
		projectiles.add_child(projectile)
		projectile.setup(
			player.global_position + direction * 34.0,
			direction,
			projectile_speed * 0.8,
			damage,
			pierce + 1,
			projectile_scale * 1.2
		)

	var _am = get_node_or_null("/root/AudioManager")
	if _am: _am.play_enemy_die()


func _on_orb_hit_enemy(_enemy: Enemy, orb: OrbProjectile) -> void:
	var _am = get_node_or_null("/root/AudioManager")
	if _am: _am.play_enemy_hit()

	var index := orb_slots.find(orb)
	if index != -1:
		orb_slots[index] = null
		orb_restore_timers[index] = orbit_cooldown


func _spawn_orb_in_slot(index: int) -> void:
	var orb := ORB_PROJECTILE_SCENE.instantiate() as OrbProjectile
	projectiles.add_child(orb)
	orb.setup(
		player,
		0.0,
		int(damage * orbit_damage_multiplier),
		orbit_radius,
		orbit_speed,
		projectile_scale * 1.2
	)
	orb.hit_enemy.connect(_on_orb_hit_enemy)
	orb_slots[index] = orb


func _activate_freeze_field() -> void:
	for enemy in enemies.get_children():
		if not enemy is Enemy:
			continue

		var distance := player.global_position.distance_to(enemy.global_position)
		if distance <= freeze_radius:
			enemy.freeze(freeze_duration)

	var _am = get_node_or_null("/root/AudioManager")
	if _am: _am.play_freeze()
