extends CanvasLayer
class_name StartScreen

# 开始游戏界面，包含游戏说明和道具说明。

signal start_game

@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var start_button: Button = $StartButton
@onready var help_button: Button = $HelpButton
@onready var help_panel: Control = $HelpPanel
@onready var close_help_button: Button = $HelpPanel/CloseHelpButton
@onready var logo: TextureRect = $Logo
@onready var bg_stars: Node2D = $BGStars
@onready var version_label: Label = $VersionLabel

var time: float = 0.0
var logo_base_scale: Vector2 = Vector2(0.5, 0.5)
var chinese_font: Font = null


func _ready() -> void:
	chinese_font = load("res://assets/fonts/NotoSansCJKsc-Regular.otf") as Font
	_setup_fonts()

	# 设置 Logo 初始缩放和 pivot
	if logo:
		logo.scale = logo_base_scale
		logo.pivot_offset = logo.size / 2.0

	start_button.pressed.connect(_on_start_pressed)
	help_button.pressed.connect(_on_help_pressed)
	close_help_button.pressed.connect(_on_close_help_pressed)
	help_panel.visible = false


func _setup_fonts() -> void:
	if chinese_font == null:
		push_error("Failed to load Chinese font!")
		return
	_apply_font(title_label, 48)
	_apply_font(subtitle_label, 18)
	_apply_font(start_button, 24)
	_apply_font(help_button, 24)
	_apply_font(version_label, 14)
	_apply_font(close_help_button, 22)
	_apply_font($HelpPanel/ScrollContainer/VBoxContainer/GameTitle, 24)
	_apply_font($HelpPanel/ScrollContainer/VBoxContainer/GameDesc, 16)
	_apply_font($HelpPanel/ScrollContainer/VBoxContainer/PickupTitle, 24)
	_apply_font($HelpPanel/ScrollContainer/VBoxContainer/PickupDesc, 16)
	_apply_font($HelpPanel/ScrollContainer/VBoxContainer/WeaponTitle, 24)
	_apply_font($HelpPanel/ScrollContainer/VBoxContainer/WeaponDesc, 16)


func _apply_font(node: Control, font_size: int) -> void:
	if node == null or chinese_font == null:
		return
	node.add_theme_font_override("font", chinese_font)
	node.add_theme_font_size_override("font_size", font_size)


func _process(delta: float) -> void:
	time += delta

	# 标题浮动动画
	if title_label:
		title_label.position.y = 400.0 + sin(time * 1.5) * 5.0

	# Logo 缩放和闪烁动画
	if logo:
		var scale_val = 1.0 + sin(time * 2.0) * 0.05
		logo.scale = logo_base_scale * scale_val
		# 闪烁效果（透明度变化）
		var alpha_val = 0.7 + sin(time * 3.0) * 0.3
		logo.modulate.a = alpha_val


func _on_start_pressed() -> void:
	if OS.has_feature("web"):
		var is_mobile = JavaScriptBridge.eval("/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);")
		if is_mobile:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			JavaScriptBridge.eval("if (screen.orientation && screen.orientation.lock) { screen.orientation.lock('landscape').catch(function(e) { console.log(e); }); }")
			
	start_game.emit()


func _on_help_pressed() -> void:
	help_panel.visible = true


func _on_close_help_pressed() -> void:
	help_panel.visible = false
