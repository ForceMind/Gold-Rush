extends CanvasLayer
class_name GameUI

# 更新 HUD、游戏结束界面和 Roguelike 升级选择。
signal upgrade_selected(upgrade_id: String)
signal back_to_menu
signal restart_game

@onready var score_label: Label = $ScoreLabel
@onready var level_label: Label = $LevelLabel
@onready var weapon_label: Label = $WeaponLabel
@onready var game_over_panel: ColorRect = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/FinalScoreLabel
@onready var upgrade_panel: ColorRect = $UpgradePanel
@onready var option_buttons: Array[Button] = [
	$UpgradePanel/OptionButton1,
	$UpgradePanel/OptionButton2,
	$UpgradePanel/OptionButton3,
]
@onready var joystick: VirtualJoystick = $VirtualJoystick
@onready var mouse_toggle: Button = $MouseToggle
@onready var nova_cooldown_bar: ProgressBar = $SkillCooldowns/NovaCooldown
@onready var orb_cooldown_bar: ProgressBar = $SkillCooldowns/OrbCooldown
@onready var freeze_cooldown_bar: ProgressBar = $SkillCooldowns/FreezeCooldown

var current_choices: Array[Dictionary] = []
var player: Player
var chinese_font: Font = null


func _ready() -> void:
	chinese_font = load("res://assets/fonts/NotoSansCJKsc-Regular.otf") as Font
	_setup_fonts()

	for index in range(option_buttons.size()):
		option_buttons[index].pressed.connect(_on_option_pressed.bind(index))

	# 连接按钮
	$GameOverPanel/BackToMenuButton.pressed.connect(_on_back_to_menu_pressed)
	$GameOverPanel/RestartButton.pressed.connect(func(): restart_game.emit())

	# 检测是否为移动设备
	var is_mobile := OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")

	if is_mobile:
		# 移动设备显示摇杆
		joystick.show()
		mouse_toggle.hide()
	else:
		# PC设备显示鼠标切换按钮
		joystick.hide()
		mouse_toggle.visible = true
		mouse_toggle.pressed.connect(_on_mouse_toggle_pressed)

	# 连接摇杆信号
	joystick.input_changed.connect(_on_joystick_input)


func _setup_fonts() -> void:
	if chinese_font == null:
		push_error("Failed to load Chinese font!")
		return
	_apply_font(score_label, 34)
	_apply_font(level_label, 24)
	_apply_font(weapon_label, 22)
	_apply_font(mouse_toggle, 20)
	_apply_font($UpgradePanel/UpgradeTitleLabel, 48)
	_apply_font($UpgradePanel/UpgradeHintLabel, 24)
	_apply_font($GameOverPanel/GameOverLabel, 76)
	_apply_font($GameOverPanel/FinalScoreLabel, 38)
	_apply_font($GameOverPanel/RestartButton, 28)
	_apply_font($GameOverPanel/BackToMenuButton, 28)
	for btn in option_buttons:
		_apply_font(btn, 22)


func _apply_font(node: Control, font_size: int) -> void:
	if node == null or chinese_font == null:
		return
	node.add_theme_font_override("font", chinese_font)
	node.add_theme_font_size_override("font_size", font_size)


func set_player(player_node: Player) -> void:
	player = player_node


func _on_joystick_input(direction: Vector2) -> void:
	if player:
		player.set_joystick_direction(direction)


func _on_mouse_toggle_pressed() -> void:
	if player:
		var new_state := not player.use_mouse_control
		player.set_mouse_control(new_state)
		if new_state:
			mouse_toggle.text = "鼠标控制: 开"
			mouse_toggle.add_theme_color_override("font_color", Color(0.22, 0.95, 0.45, 1))
		else:
			mouse_toggle.text = "鼠标控制: 关"
			mouse_toggle.add_theme_color_override("font_color", Color(0.86, 0.94, 1, 1))


func set_score(value: int) -> void:
	score_label.text = "分数：%d" % value


func set_level(value: int, next_upgrade_score: int) -> void:
	level_label.text = "等级：%d  下次选择：%d 分" % [value, next_upgrade_score]


func set_weapon_stats(text: String) -> void:
	weapon_label.text = text


func show_game_over(final_score: int) -> void:
	final_score_label.text = "最终分数：%d" % final_score
	game_over_panel.show()


func hide_game_over() -> void:
	game_over_panel.hide()


func show_upgrade_choices(choices: Array[Dictionary]) -> void:
	current_choices = choices

	for index in range(option_buttons.size()):
		var button := option_buttons[index]
		if index < current_choices.size():
			var choice := current_choices[index]
			var desc: String = choice["description"]
			# 如果描述太长，添加换行
			if desc.length() > 15:
				var mid := desc.length() / 2
				# 找到中间的标点符号或空格进行换行
				var break_pos := desc.find("，", mid)
				if break_pos == -1:
					break_pos = desc.find("。", mid)
				if break_pos == -1:
					break_pos = desc.find(" ", mid)
				if break_pos == -1:
					break_pos = mid
				desc = desc.substr(0, break_pos + 1) + "\n" + desc.substr(break_pos + 1)
			button.text = "%s\n%s" % [choice["name"], desc]
			button.show()
		else:
			button.hide()

	upgrade_panel.show()


func hide_upgrade_choices() -> void:
	upgrade_panel.hide()


func _on_option_pressed(index: int) -> void:
	if index >= current_choices.size():
		return

	var choice := current_choices[index]
	hide_upgrade_choices()
	upgrade_selected.emit(str(choice["id"]))


func _on_back_to_menu_pressed() -> void:
	back_to_menu.emit()


func update_skill_cooldowns(nova_pct: float, orb_pct: float, freeze_pct: float) -> void:
	nova_cooldown_bar.value = nova_pct * 100.0
	orb_cooldown_bar.value = orb_pct * 100.0
	freeze_cooldown_bar.value = freeze_pct * 100.0

	# 只显示已解锁的技能进度条
	nova_cooldown_bar.get_parent().visible = nova_pct >= 0.0 or orb_pct >= 0.0 or freeze_pct >= 0.0
	nova_cooldown_bar.visible = nova_pct >= 0.0
	orb_cooldown_bar.visible = orb_pct >= 0.0
	freeze_cooldown_bar.visible = freeze_pct >= 0.0
