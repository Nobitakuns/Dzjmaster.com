extends Control

const UI_FONT: FontFile = preload("res://assets/fonts/DejaVuSans.ttf")
const MENU_ART: Texture2D = preload("res://assets/backgrounds/menu_showdown.png")

signal select_requested(mode: String)
signal start_requested(mode: String, p1_id: int, p2_id: int)
signal settings_requested()

const WHITE := Color("#fff5ff")
const PINK := Color("#ff438b")
const CYAN := Color("#67eaff")
const MUTED := Color("#abb4d5")


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var art := TextureRect.new()
	art.texture = MENU_ART
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)

	var shade := ColorRect.new()
	shade.color = Color("#07031549")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var brand := _label("♛  QUEENS OF BATTLE", 24, WHITE)
	brand.position = Vector2(46, 34)
	add_child(brand)
	var edition := _label("ANIME FANTASY  •  NEON COMBAT  •  2D", 17, MUTED)
	edition.anchor_left = 1.0
	edition.anchor_right = 1.0
	edition.offset_left = -450.0
	edition.offset_right = -35.0
	edition.offset_top = 39.0
	add_child(edition)

	var center := PanelContainer.new()
	center.anchor_left = 0.295
	center.anchor_right = 0.705
	center.anchor_top = 0.105
	center.anchor_bottom = 0.91
	center.add_theme_stylebox_override("panel", _panel(Color("#080917cc"), Color("#bd4fff"), 3, 25))
	add_child(center)

	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 42)
	padding.add_theme_constant_override("margin_right", 42)
	padding.add_theme_constant_override("margin_top", 28)
	padding.add_theme_constant_override("margin_bottom", 28)
	center.add_child(padding)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 13)
	padding.add_child(stack)

	var crown := _label("♛", 63, Color("#ff6fca"))
	crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(crown)
	var title := _label("QUEENS OF\nBATTLE", 76, WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 7)
	title.add_theme_color_override("font_outline_color", Color("#230824"))
	stack.add_child(title)
	var tagline := _label("8 NỮ VÕ SĨ  ·  MỘT NGÔI VƯƠNG", 20, PINK)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(tagline)
	var space := Control.new()
	space.custom_minimum_size.y = 18
	stack.add_child(space)

	var play := _button("VÀO GAME  ❯", PINK, 84)
	play.add_theme_font_size_override("font_size", 30)
	play.pressed.connect(func() -> void: select_requested.emit("ai"))
	stack.add_child(play)

	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 14)
	stack.add_child(modes)
	var ai := _button("VS AI", CYAN, 65)
	ai.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ai.pressed.connect(func() -> void: select_requested.emit("ai"))
	modes.add_child(ai)
	var local := _button("LOCAL VS", Color("#ffa85e"), 65)
	local.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	local.pressed.connect(func() -> void: select_requested.emit("local"))
	modes.add_child(local)

	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 14)
	stack.add_child(tools)
	var roster := _button("CHỌN VÕ SĨ", Color("#bd8bff"), 59)
	roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster.pressed.connect(func() -> void: select_requested.emit("ai"))
	tools.add_child(roster)
	var settings := _button("CÀI ĐẶT", MUTED, 59)
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.pressed.connect(func() -> void: settings_requested.emit())
	tools.add_child(settings)

	var exit := _button("THOÁT", Color("#8f91ae"), 48)
	exit.pressed.connect(func() -> void: get_tree().quit())
	stack.add_child(exit)
	var help := "Cảm ứng: VS AI  •  LOCAL VS cần bàn phím ngoài" if OS.get_name() == "Android" else "A / D di chuyển  •  J / K tấn công  •  L kỹ năng  •  U tuyệt kỹ"
	var hint := _label(help, 16, MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(hint)


func _button(caption: String, accent: Color, height: float) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = height
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _panel(Color("#1b122eca"), accent.darkened(0.18), 2, 13))
	button.add_theme_stylebox_override("hover", _panel(accent.darkened(0.55), accent.lightened(0.2), 3, 13))
	button.add_theme_stylebox_override("pressed", _panel(accent.darkened(0.4), Color.WHITE, 3, 13))
	button.add_theme_stylebox_override("focus", _panel(Color.TRANSPARENT, accent, 2, 13))
	return button


func _label(value: String, size_px: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _panel(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color("#d81b83aa")
	style.shadow_size = 9
	return style
