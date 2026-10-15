class_name BattleHUD
extends CanvasLayer

## Battle-only presentation. Combat rules and timing stay in the battle controller.
const UI_FONT: FontFile = preload("res://assets/fonts/DejaVuSans.ttf")
const MAX_HP := 2000
const MAX_ENERGY := 100
const INK := Color("#080d20")
const MUTED := Color("#aab9da")
const CYAN := Color("#54e8ff")
const GOLD := Color("#ffd36b")

var _p1_data: FighterData
var _p2_data: FighterData
var _mode := "ai"
var _root: Control
var _name_labels: Array[Label] = []
var _portrait_labels: Array[Label] = []
var _portrait_panels: Array[PanelContainer] = []
var _portrait_images: Array[FighterPortrait] = []
var _element_labels: Array[Label] = []
var _hp_labels: Array[Label] = []
var _hp_bars: Array[ProgressBar] = []
var _energy_labels: Array[Label] = []
var _energy_bars: Array[ProgressBar] = []
var _ready_labels: Array[Label] = []
var _win_labels: Array[Label] = []
var _combo_panels: Array[PanelContainer] = []
var _combo_labels: Array[Label] = []
var _combo_timers: Array[Timer] = []
var _timer_label: Label
var _round_label: Label
var _controls_label: Label
var _controls_panel: PanelContainer
var _announcement_panel: PanelContainer
var _announcement_label: Label
var _announcement_timer: Timer
var _ultimate_panel: PanelContainer
var _ultimate_label: Label


func _ready() -> void:
	_build_ui()
	_refresh_fighters()
	update_state(MAX_HP, MAX_HP, 0, 0, 99.0, 1, 0, 0)


func configure(p1: FighterData, p2: FighterData, mode: String) -> void:
	_p1_data = p1
	_p2_data = p2
	_mode = mode
	if is_instance_valid(_root):
		_refresh_fighters()


func update_state(p1_hp: int, p2_hp: int, p1_energy: int, p2_energy: int,
		time_left: float, round_number: int, p1_wins: int, p2_wins: int) -> void:
	if not is_instance_valid(_root):
		return
	var health := [p1_hp, p2_hp]
	var energy := [p1_energy, p2_energy]
	var wins := [p1_wins, p2_wins]
	for slot in 2:
		var hp_value: int = clampi(health[slot], 0, MAX_HP)
		var energy_value: int = clampi(energy[slot], 0, MAX_ENERGY)
		_hp_bars[slot].value = hp_value
		_energy_bars[slot].value = energy_value
		_hp_labels[slot].text = "%d / %d HP" % [hp_value, MAX_HP]
		_energy_labels[slot].text = "NĂNG LƯỢNG  %d%%" % energy_value
		_ready_labels[slot].visible = energy_value >= MAX_ENERGY
		_win_labels[slot].text = "THẮNG  %s" % ("●".repeat(clampi(wins[slot], 0, 2)) + "○".repeat(2 - clampi(wins[slot], 0, 2)))
	_timer_label.text = "%02d" % ceili(maxf(time_left, 0.0))
	_round_label.text = "ROUND %d  •  BO3" % round_number


func show_combo(slot: int, hits: int, damage: int) -> void:
	if slot < 1 or slot > 2 or not is_instance_valid(_root):
		return
	var index := slot - 1
	_combo_timers[index].stop()
	_combo_panels[index].visible = hits >= 2
	if hits >= 2:
		_combo_labels[index].text = "%d HIT COMBO\n%d DAMAGE" % [hits, damage]
		_combo_timers[index].start()


func show_announcement(message: String, duration: float = 1.5) -> void:
	if not is_instance_valid(_announcement_panel):
		return
	_announcement_timer.stop()
	_announcement_label.text = message
	_announcement_panel.visible = not message.is_empty()
	if duration > 0.0 and not message.is_empty():
		_announcement_timer.start(duration)


func show_ultimate(data: FighterData) -> void:
	if not is_instance_valid(_ultimate_panel):
		return
	var accent := CYAN if data == null else data.accent
	var fighter_name := "VÕ SĨ" if data == null else data.display_name.to_upper()
	var move_name := "ULTIMATE" if data == null else data.ultimate_name.to_upper()
	_ultimate_panel.add_theme_stylebox_override("panel", _panel_style(INK, accent, 3))
	_ultimate_label.add_theme_color_override("font_color", accent)
	_ultimate_label.text = "✦  TUYỆT KỸ  ✦\n%s  •  %s" % [fighter_name, move_name]
	_ultimate_panel.visible = true


func hide_ultimate() -> void:
	if is_instance_valid(_ultimate_panel):
		_ultimate_panel.visible = false


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "BattleHUDRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var top := HBoxContainer.new()
	top.anchor_right = 1.0
	top.offset_left = 42.0
	top.offset_top = 20.0
	top.offset_right = -42.0
	top.offset_bottom = 205.0
	top.add_theme_constant_override("separation", 18)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(top)

	top.add_child(_fighter_panel(0))
	var center := PanelContainer.new()
	center.custom_minimum_size.x = 246
	center.add_theme_stylebox_override("panel", _panel_style(Color("#10152d"), CYAN, 2))
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(center)
	var center_stack := VBoxContainer.new()
	center_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	center_stack.add_theme_constant_override("separation", 1)
	center.add_child(center_stack)
	_round_label = _label("ROUND 1  •  BO3", 18, MUTED)
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_stack.add_child(_round_label)
	_timer_label = _label("99", 64, Color.WHITE)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_stack.add_child(_timer_label)
	var vs_label := _label("QUEENS OF BATTLE", 15, CYAN)
	vs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_stack.add_child(vs_label)
	top.add_child(_fighter_panel(1))

	for slot in 2:
		var combo := PanelContainer.new()
		combo.anchor_left = 0.0 if slot == 0 else 1.0
		combo.anchor_right = 0.0 if slot == 0 else 1.0
		combo.offset_left = 45.0 if slot == 0 else -445.0
		combo.offset_right = 445.0 if slot == 0 else -45.0
		combo.offset_top = 234.0
		combo.offset_bottom = 332.0
		combo.add_theme_stylebox_override("panel", _panel_style(Color("#10152de8"), CYAN, 2))
		combo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		combo.visible = false
		_root.add_child(combo)
		_combo_panels.append(combo)
		var combo_label := _label("", 25, GOLD)
		combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if slot == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		combo.add_child(combo_label)
		_combo_labels.append(combo_label)
		var combo_timer := Timer.new()
		combo_timer.one_shot = true
		combo_timer.wait_time = 1.5
		combo_timer.timeout.connect(_hide_combo.bind(slot))
		add_child(combo_timer)
		_combo_timers.append(combo_timer)

	_ultimate_panel = PanelContainer.new()
	_ultimate_panel.anchor_left = 0.26
	_ultimate_panel.anchor_right = 0.74
	_ultimate_panel.offset_top = 230.0
	_ultimate_panel.offset_bottom = 332.0
	_ultimate_panel.add_theme_stylebox_override("panel", _panel_style(INK, GOLD, 3))
	_ultimate_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ultimate_panel.visible = false
	_root.add_child(_ultimate_panel)
	_ultimate_label = _label("", 25, GOLD)
	_ultimate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ultimate_panel.add_child(_ultimate_label)

	_announcement_panel = PanelContainer.new()
	_announcement_panel.anchor_left = 0.25
	_announcement_panel.anchor_right = 0.75
	_announcement_panel.anchor_top = 0.39
	_announcement_panel.anchor_bottom = 0.50
	_announcement_panel.add_theme_stylebox_override("panel", _panel_style(Color("#080d20df"), GOLD, 3))
	_announcement_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_announcement_panel.visible = false
	_root.add_child(_announcement_panel)
	_announcement_label = _label("", 53, Color.WHITE)
	_announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announcement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_announcement_panel.add_child(_announcement_label)
	_announcement_timer = Timer.new()
	_announcement_timer.one_shot = true
	_announcement_timer.timeout.connect(func() -> void: _announcement_panel.visible = false)
	add_child(_announcement_timer)

	var controls := PanelContainer.new()
	_controls_panel = controls
	controls.anchor_left = 0.08
	controls.anchor_right = 0.92
	controls.anchor_top = 1.0
	controls.anchor_bottom = 1.0
	controls.offset_top = -68.0
	controls.offset_bottom = -14.0
	controls.add_theme_stylebox_override("panel", _panel_style(Color("#0d1630d8"), Color("#546789"), 1))
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(controls)
	_controls_label = _label("", 17, MUTED)
	_controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls.add_child(_controls_label)
	_controls_panel.visible = OS.get_name() != "Android"


func _fighter_panel(slot: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#111a38ee"), CYAN, 2))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 3)
	panel.add_child(stack)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	stack.add_child(heading)
	var portrait := PanelContainer.new()
	portrait.custom_minimum_size = Vector2(70, 70)
	portrait.add_theme_stylebox_override("panel", _panel_style(Color("#151c3b"), CYAN, 2))
	heading.add_child(portrait)
	_portrait_panels.append(portrait)
	var portrait_image := FighterPortrait.new()
	portrait.add_child(portrait_image)
	_portrait_images.append(portrait_image)
	var portrait_label := _label("✦", 33, CYAN)
	portrait_label.visible = false
	portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait.add_child(portrait_label)
	_portrait_labels.append(portrait_label)
	var name_label := _label("", 27, Color.WHITE)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(name_label)
	_name_labels.append(name_label)
	var win_label := _label("THẮNG  ○○", 18, GOLD)
	heading.add_child(win_label)
	_win_labels.append(win_label)
	var element_label := _label("", 16, MUTED)
	stack.add_child(element_label)
	_element_labels.append(element_label)
	var hp_bar := _meter(MAX_HP, Color("#ff5783"), 27)
	stack.add_child(hp_bar)
	_hp_bars.append(hp_bar)
	var hp_label := _label("2000 / 2000 HP", 17, Color.WHITE)
	stack.add_child(hp_label)
	_hp_labels.append(hp_label)
	var energy_row := HBoxContainer.new()
	energy_row.add_theme_constant_override("separation", 10)
	stack.add_child(energy_row)
	var energy_bar := _meter(MAX_ENERGY, CYAN, 15)
	energy_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	energy_row.add_child(energy_bar)
	_energy_bars.append(energy_bar)
	var ready_label := _label("ULT READY", 15, GOLD)
	ready_label.visible = false
	energy_row.add_child(ready_label)
	_ready_labels.append(ready_label)
	var energy_label := _label("NĂNG LƯỢNG  0%", 16, MUTED)
	stack.add_child(energy_label)
	_energy_labels.append(energy_label)
	return panel


func _refresh_fighters() -> void:
	if not is_instance_valid(_root):
		return
	var data_list: Array[FighterData] = [_p1_data, _p2_data]
	for slot in 2:
		var data := data_list[slot]
		var accent := CYAN if data == null else data.accent
		_portrait_images[slot].set_fighter(0 if data == null else data.fighter_id)
		_portrait_labels[slot].text = ["☾", "◆", "✧", "✿", "◇", "ϟ", "✦", "☼"][data.fighter_id] if data != null else "✦"
		_portrait_labels[slot].add_theme_color_override("font_color", accent)
		_portrait_panels[slot].add_theme_stylebox_override("panel", _panel_style(Color("#151c3b"), accent, 2))
		_name_labels[slot].text = ("P1" if slot == 0 else "P2") + "  " + ("VÕ SĨ" if data == null else data.display_name.to_upper())
		_name_labels[slot].add_theme_color_override("font_color", accent)
		_element_labels[slot].text = "HỆ SỨC MẠNH  •  " + ("—" if data == null else data.element.to_upper())
		_energy_bars[slot].add_theme_stylebox_override("fill", _panel_style(accent, accent, 0))
		_combo_labels[slot].add_theme_color_override("font_color", accent)
	_controls_label.text = "P1  A/D đi  W nhảy  S ngồi  J đấm  K đá  L kỹ năng  U tuyệt kỹ  I đỡ   •   ESC tạm dừng"
	if _mode == "local":
		_controls_label.text = "P1  A/D/W/S + J/K/L/U/I     •     P2  ←/→/↑/↓ + 1/2/3/4/5     •     ESC tạm dừng"


func _hide_combo(slot: int) -> void:
	_combo_panels[slot].visible = false


func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _meter(maximum: int, color: Color, height: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = maximum
	bar.value = maximum
	bar.show_percentage = false
	bar.custom_minimum_size.y = height
	bar.add_theme_stylebox_override("background", _panel_style(Color("#25314a"), Color("#4a5c7e"), 1))
	bar.add_theme_stylebox_override("fill", _panel_style(color, color, 0))
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


func _panel_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style
