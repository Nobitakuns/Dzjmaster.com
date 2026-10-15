extends Control

const UI_FONT: FontFile = preload("res://assets/fonts/DejaVuSans.ttf")
const ARENA_ART: Texture2D = preload("res://assets/backgrounds/neon_sakura_arena.png")

signal start_requested(mode: String, p1_id: int, p2_id: int)
signal back_requested()
signal settings_requested()

const FIGHTERS := [
	{"name": "NGỌC VY", "title": "SHADOW QUEEN", "power": "BÓNG TỐI", "color": "#8428D8", "icon": "✦", "stats": [79, 58, 80, 90], "moves": ["Shadow Jab", "Dark Crescent", "Phantom Claw", "Shadow Wave", "Queen of Shadows"]},
	{"name": "MAI ANH", "title": "CRIMSON STRIKER", "power": "LỬA", "color": "#FF3038", "icon": "◆", "stats": [91, 59, 86, 76], "moves": ["Flame Punch", "Burning Kick", "Crimson Combo", "Fire Dragon Dash", "Inferno Dragon"]},
	{"name": "HUYỀN CHI", "title": "BLOOD BUTTERFLY", "power": "HUYẾT ĐIỆP", "color": "#B80D35", "icon": "✧", "stats": [83, 64, 78, 87], "moves": ["Butterfly Slash", "Crimson Wing", "Scarlet Dance", "Blood Butterfly Storm", "Blood Moon Eclipse"]},
	{"name": "HỒNG NHI", "title": "SAKURA DANCER", "power": "HOA ANH ĐÀO", "color": "#FF8CCB", "icon": "✿", "stats": [72, 62, 93, 84], "moves": ["Sakura Palm", "Blossom Kick", "Petal Dance", "Sakura Tornado", "Eternal Sakura Bloom"]},
	{"name": "BẢO CHÂU", "title": "PRISM MIRAGE", "power": "QUANG PHỔ", "color": "#23DDE8", "icon": "◇", "stats": [74, 68, 89, 94], "moves": ["Prism Strike", "Rainbow Kick", "Mirage Combo", "Prism Portal", "Rainbow Dimension"]},
	{"name": "TỬ ANH", "title": "THUNDER EMPRESS", "power": "SẤM SÉT", "color": "#A05BFF", "icon": "ϟ", "stats": [87, 61, 88, 92], "moves": ["Electric Jab", "Thunder Kick", "Lightning Rush", "Thunder Spear", "Empress Thunderstorm"]},
	{"name": "THANH VÂN", "title": "HOLY GUARDIAN", "power": "THÁNH QUANG", "color": "#DDF5FF", "icon": "✧", "stats": [76, 91, 69, 86], "moves": ["Holy Palm", "Angel Kick", "Divine Combo", "Holy Light Wave", "Seraph Awakening"]},
	{"name": "ÁNH DƯƠNG", "title": "SOLAR VALKYRIE", "power": "MẶT TRỜI", "color": "#FFC928", "icon": "☼", "stats": [89, 75, 75, 86], "moves": ["Solar Punch", "Sun Kick", "Golden Rush", "Solar Flare", "Radiant Sun Goddess"]},
]

const PANEL := Color("#0b0b1fe6")
const CYAN := Color("#58ebff")
const PINK := Color("#ff79bd")
const MUTED := Color("#b1b8d4")

var mode := "ai"
var p1_id := 6
var p2_id := 0
var _focus_player := 1
var _cards: Array[Button] = []
var _status_labels: Array[Label] = []
var _player_buttons: Array[Button] = []
var _mode_label: Label
var _detail_name: Label
var _detail_title: Label
var _detail_power: Label
var _detail_portrait: FighterPortrait
var _stat_bars: Array[ProgressBar] = []
var _move_labels: Array[Label] = []


func set_mode(next_mode: String) -> void:
	mode = "local" if next_mode == "local" else "ai"
	_refresh_selection()


func _ready() -> void:
	_build_ui()
	_refresh_selection()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back_requested.emit()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			_focus_player = 2 if _focus_player == 1 else 1
			_refresh_selection()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
			var selected := p1_id if _focus_player == 1 else p2_id
			var step := -1 if event.keycode == KEY_LEFT else 1
			if event.keycode == KEY_UP:
				step = -4
			elif event.keycode == KEY_DOWN:
				step = 4
			_choose_fighter(posmod(selected + step, FIGHTERS.size()))
			get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var art := TextureRect.new()
	art.texture = ARENA_ART
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.modulate = Color(0.66, 0.58, 0.78, 1.0)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var veil := ColorRect.new()
	veil.color = Color("#0707139c")
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 43)
	margin.add_theme_constant_override("margin_right", 43)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 82
	layout.add_child(header)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	heading.add_child(_label("♛   CHOOSE YOUR FIGHTER", 43, Color.WHITE))
	heading.add_child(_label("CHỌN VÕ SĨ  •  8 NỮ CHIẾN BINH  •  2D NEON ARENA", 18, PINK))
	_mode_label = _label("VS AI", 25, CYAN)
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_mode_label)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 13)
	layout.add_child(grid)
	for index in FIGHTERS.size():
		var card := _build_card(index)
		grid.add_child(card)
		_cards.append(card)

	var details := PanelContainer.new()
	details.custom_minimum_size.y = 205
	details.add_theme_stylebox_override("panel", _panel_style(PANEL, Color("#aa50ec"), 2, 15))
	layout.add_child(details)
	var detail_pad := MarginContainer.new()
	detail_pad.add_theme_constant_override("margin_left", 16)
	detail_pad.add_theme_constant_override("margin_right", 20)
	detail_pad.add_theme_constant_override("margin_top", 11)
	detail_pad.add_theme_constant_override("margin_bottom", 11)
	details.add_child(detail_pad)
	var detail_row := HBoxContainer.new()
	detail_row.add_theme_constant_override("separation", 20)
	detail_pad.add_child(detail_row)
	_detail_portrait = FighterPortrait.new()
	_detail_portrait.custom_minimum_size = Vector2(190, 177)
	detail_row.add_child(_detail_portrait)
	var identity := VBoxContainer.new()
	identity.custom_minimum_size.x = 310
	identity.add_theme_constant_override("separation", 7)
	detail_row.add_child(identity)
	identity.add_child(_label("HỒ SƠ VÕ SĨ", 17, CYAN))
	_detail_name = _label("", 33, Color.WHITE)
	identity.add_child(_detail_name)
	_detail_title = _label("", 18, MUTED)
	identity.add_child(_detail_title)
	_detail_power = _label("", 19, CYAN)
	identity.add_child(_detail_power)
	var stat_stack := VBoxContainer.new()
	stat_stack.custom_minimum_size.x = 400
	stat_stack.add_theme_constant_override("separation", 5)
	detail_row.add_child(stat_stack)
	stat_stack.add_child(_label("CHỈ SỐ CHIẾN ĐẤU", 17, CYAN))
	for stat_name in ["ATTACK", "DEFENSE", "SPEED", "SKILL"]:
		var stat_row := HBoxContainer.new()
		stat_row.add_theme_constant_override("separation", 9)
		stat_stack.add_child(stat_row)
		var stat_label := _label(stat_name, 16, MUTED)
		stat_label.custom_minimum_size.x = 100
		stat_row.add_child(stat_label)
		var bar := ProgressBar.new()
		bar.max_value = 100
		bar.show_percentage = false
		bar.custom_minimum_size.y = 13
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.add_theme_stylebox_override("background", _panel_style(Color("#28304c"), Color.TRANSPARENT, 0, 5))
		stat_row.add_child(bar)
		_stat_bars.append(bar)
	var moves := VBoxContainer.new()
	moves.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	moves.add_theme_constant_override("separation", 3)
	detail_row.add_child(moves)
	moves.add_child(_label("BỘ CHIÊU", 17, CYAN))
	for move_index in 5:
		var move_label := _label("", 15, Color.WHITE)
		moves.add_child(move_label)
		_move_labels.append(move_label)

	var footer := HBoxContainer.new()
	footer.custom_minimum_size.y = 72
	footer.add_theme_constant_override("separation", 16)
	layout.add_child(footer)
	var back := _button("‹  QUAY LẠI", MUTED, 180)
	back.pressed.connect(func() -> void: back_requested.emit())
	footer.add_child(back)
	for player in [1, 2]:
		var player_button := _button("", CYAN if player == 1 else PINK, 270)
		player_button.pressed.connect(_set_focus.bind(player))
		footer.add_child(player_button)
		_player_buttons.append(player_button)
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(fill)
	var start := _button("BẮT ĐẦU TRẬN  ❯", Color("#ff3575"), 365)
	start.add_theme_font_size_override("font_size", 25)
	start.pressed.connect(func() -> void: start_requested.emit(mode, p1_id, p2_id))
	footer.add_child(start)


func _build_card(index: int) -> Button:
	var info: Dictionary = FIGHTERS[index]
	var accent := Color(info["color"])
	var card := Button.new()
	card.custom_minimum_size = Vector2(300, 255)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("normal", _panel_style(PANEL, accent.darkened(0.3), 2, 12))
	card.add_theme_stylebox_override("hover", _panel_style(Color("#32153ce8"), accent, 4, 12))
	card.add_theme_stylebox_override("pressed", _panel_style(Color("#4e1f56ee"), accent, 4, 12))
	card.add_theme_stylebox_override("focus", _panel_style(Color.TRANSPARENT, accent, 3, 12))
	card.pressed.connect(_choose_fighter.bind(index))
	var card_pad := MarginContainer.new()
	card_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_pad.add_theme_constant_override("margin_left", 7)
	card_pad.add_theme_constant_override("margin_right", 7)
	card_pad.add_theme_constant_override("margin_top", 7)
	card_pad.add_theme_constant_override("margin_bottom", 7)
	card_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(card_pad)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_pad.add_child(content)
	var portrait := FighterPortrait.new()
	portrait.set_fighter(index)
	portrait.custom_minimum_size.y = 177
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(portrait)
	var name_row := HBoxContainer.new()
	content.add_child(name_row)
	var name := _label(info["name"], 20, Color.WHITE)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name)
	var status := _label("", 18, CYAN)
	name_row.add_child(status)
	_status_labels.append(status)
	var title := _label(info["title"], 14, accent)
	content.add_child(title)
	return card


func _set_focus(player: int) -> void:
	_focus_player = player
	_refresh_selection()


func _choose_fighter(index: int) -> void:
	if _focus_player == 1:
		p1_id = index
	else:
		p2_id = index
	_refresh_selection()


func _refresh_selection() -> void:
	if not is_node_ready() or _mode_label == null:
		return
	_mode_label.text = "LOCAL VS" if mode == "local" else "VS AI"
	for index in _cards.size():
		var accent := Color(FIGHTERS[index]["color"])
		var outline := accent.darkened(0.4)
		var assigned := ""
		if index == p1_id:
			outline = CYAN
			assigned = "P1"
		if index == p2_id:
			outline = PINK if index != p1_id else Color.WHITE
			assigned = "P2" if assigned.is_empty() else "P1 · P2"
		_status_labels[index].text = assigned
		_status_labels[index].add_theme_color_override("font_color", outline)
		_cards[index].add_theme_stylebox_override("normal", _panel_style(PANEL, outline, 4 if not assigned.is_empty() else 2, 12))
	for player in [1, 2]:
		var selected := p1_id if player == 1 else p2_id
		var accent := CYAN if player == 1 else PINK
		var caption: String = ("P1  " if player == 1 else ("AI  " if mode == "ai" else "P2  ")) + str(FIGHTERS[selected]["name"])
		var button := _player_buttons[player - 1]
		button.text = caption
		button.add_theme_stylebox_override("normal", _panel_style(Color("#342249"), accent if _focus_player == player else accent.darkened(0.55), 3 if _focus_player == player else 2, 10))
	var focused := p1_id if _focus_player == 1 else p2_id
	var info: Dictionary = FIGHTERS[focused]
	var color := Color(info["color"])
	_detail_portrait.set_fighter(focused)
	_detail_name.text = info["name"]
	_detail_title.text = info["title"]
	_detail_power.text = "HỆ  •  " + info["power"]
	_detail_power.add_theme_color_override("font_color", color)
	for stat_index in 4:
		_stat_bars[stat_index].value = info["stats"][stat_index]
		_stat_bars[stat_index].add_theme_stylebox_override("fill", _panel_style(color, Color.TRANSPARENT, 0, 5))
	for move_index in 5:
		var prefix: String = ["1", "2", "3", "SKILL", "ULTIMATE"][move_index]
		_move_labels[move_index].text = "%s   %s" % [prefix, info["moves"][move_index]]
		_move_labels[move_index].add_theme_color_override("font_color", color if move_index >= 3 else Color.WHITE)


func _button(caption: String, accent: Color, width: float) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(width, 65)
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _panel_style(Color("#1a1530ec"), accent, 2, 10))
	button.add_theme_stylebox_override("hover", _panel_style(accent.darkened(0.5), accent.lightened(0.2), 3, 10))
	button.add_theme_stylebox_override("pressed", _panel_style(accent.darkened(0.35), Color.WHITE, 3, 10))
	return button


func _label(value: String, point_size: int, color: Color) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size", point_size)
	node.add_theme_font_override("font", UI_FONT)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _panel_style(fill: Color, outline: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color("#ae35d566")
	style.shadow_size = 5
	return style
