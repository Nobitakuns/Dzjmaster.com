class_name SettingsPanel
extends Control

signal closed
signal settings_changed(ai_level: String, reduced_fx: bool)

const FONT: FontFile = preload("res://assets/fonts/DejaVuSans.ttf")
const INK := Color("#080c1c")
const PANEL := Color("#111936")
const EDGE := Color("#7246b9")
const CYAN := Color("#4be7ff")
const MUTED := Color("#aab9da")
const WARNING := Color("#ffc16b")

const ACTIONS := [
	["p1_left", "Trái"], ["p1_right", "Phải"], ["p1_jump", "Nhảy"],
	["p1_crouch", "Ngồi"], ["p1_punch", "Đấm"], ["p1_kick", "Đá"],
	["p1_skill", "Kỹ năng"], ["p1_ultimate", "Tuyệt kỹ"], ["p1_block", "Đỡ đòn"],
	["p2_left", "Trái"], ["p2_right", "Phải"], ["p2_jump", "Nhảy"],
	["p2_crouch", "Ngồi"], ["p2_punch", "Đấm"], ["p2_kick", "Đá"],
	["p2_skill", "Kỹ năng"], ["p2_ultimate", "Tuyệt kỹ"], ["p2_block", "Đỡ đòn"],
]

var _ai_level := "normal"
var _reduced_fx := false
var _listening_action := ""
var _binding_buttons: Dictionary = {}
var _difficulty: OptionButton
var _reduced_fx_check: CheckBox
var _fullscreen_check: CheckBox
var _status: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func open(current_ai: String, current_reduced_fx: bool) -> void:
	_ai_level = current_ai if current_ai in ["easy", "normal", "hard"] else "normal"
	_reduced_fx = current_reduced_fx
	_difficulty.select(["easy", "normal", "hard"].find(_ai_level))
	_reduced_fx_check.set_pressed_no_signal(_reduced_fx)
	_fullscreen_check.set_pressed_no_signal(_is_fullscreen())
	_status.text = "Chọn một phím để thay đổi điều khiển. Esc hủy thao tác."
	_status.add_theme_color_override("font_color", MUTED)
	visible = true


func _input(event: InputEvent) -> void:
	if _listening_action.is_empty() or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if event.physical_keycode == KEY_ESCAPE:
			_cancel_rebind()
			return
		var code: int = event.physical_keycode
		if code == KEY_NONE:
			_status.text = "Không nhận được mã phím vật lý. Thử phím khác."
			_status.add_theme_color_override("font_color", WARNING)
			return
		for action in InputBindings.DEFAULTS:
			if action != _listening_action and InputBindings.get_key(action) == code:
				_status.text = "Phím %s đang được dùng cho %s. Chọn phím khác." % [_key_name(code), _action_name(action)]
				_status.add_theme_color_override("font_color", WARNING)
				return
		InputBindings.rebind(_listening_action, code)
		_binding_buttons[_listening_action].text = _key_name(code)
		_status.text = "%s: %s" % [_action_name(_listening_action), _key_name(code)]
		_status.add_theme_color_override("font_color", CYAN)
		_listening_action = ""


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.10, 0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1260, 930)
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL, EDGE, 3))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)

	var header := HBoxContainer.new()
	content.add_child(header)
	var heading := _label("CÀI ĐẶT", 41, CYAN)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var close_button := _button("QUAY LẠI", 20)
	close_button.custom_minimum_size = Vector2(170, 54)
	close_button.pressed.connect(_close)
	header.add_child(close_button)

	content.add_child(_label("THIẾT LẬP TRẬN ĐẤU", 22, MUTED))
	var settings_row := HBoxContainer.new()
	settings_row.add_theme_constant_override("separation", 30)
	content.add_child(settings_row)
	var difficulty_group := VBoxContainer.new()
	difficulty_group.custom_minimum_size.x = 340
	settings_row.add_child(difficulty_group)
	difficulty_group.add_child(_label("ĐỘ KHÓ AI", 20, Color.WHITE))
	_difficulty = OptionButton.new()
	_difficulty.custom_minimum_size = Vector2(320, 58)
	_difficulty.add_theme_font_override("font", FONT)
	_difficulty.add_theme_font_size_override("font_size", 20)
	_difficulty.add_item("Dễ", 0)
	_difficulty.add_item("Thường", 1)
	_difficulty.add_item("Khó", 2)
	_difficulty.item_selected.connect(_on_ai_selected)
	difficulty_group.add_child(_difficulty)
	_reduced_fx_check = _checkbox("Giảm hiệu ứng")
	_reduced_fx_check.toggled.connect(_on_reduced_fx_toggled)
	settings_row.add_child(_reduced_fx_check)
	_fullscreen_check = _checkbox("Toàn màn hình")
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	settings_row.add_child(_fullscreen_check)

	var rule := HSeparator.new()
	content.add_child(rule)
	var bindings_header := HBoxContainer.new()
	content.add_child(bindings_header)
	var bindings_title := _label("ĐIỀU KHIỂN BÀN PHÍM", 23, CYAN)
	bindings_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bindings_header.add_child(bindings_title)
	var reset_button := _button("ĐẶT LẠI PHÍM", 17)
	reset_button.custom_minimum_size = Vector2(205, 46)
	reset_button.pressed.connect(_reset_bindings)
	bindings_header.add_child(reset_button)

	var players := HBoxContainer.new()
	players.size_flags_vertical = Control.SIZE_EXPAND_FILL
	players.add_theme_constant_override("separation", 55)
	content.add_child(players)
	for player in [1, 2]:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 7)
		players.add_child(column)
		column.add_child(_label("NGƯỜI CHƠI %d" % player, 23, CYAN if player == 1 else Color("#ff949d")))
		for entry in ACTIONS:
			var action: String = entry[0]
			if not action.begins_with("p%d_" % player):
				continue
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			column.add_child(row)
			var caption := _label(entry[1], 18, Color.WHITE)
			caption.custom_minimum_size.x = 185
			caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(caption)
			var key_button := _button(_key_name(InputBindings.get_key(action)), 18)
			key_button.custom_minimum_size = Vector2(155, 42)
			key_button.pressed.connect(_start_rebind.bind(action))
			row.add_child(key_button)
			_binding_buttons[action] = key_button

	_status = _label("Chọn một phím để thay đổi điều khiển. Esc hủy thao tác.", 18, MUTED)
	content.add_child(_status)
	content.add_child(_label("Phím số của người chơi 2 dùng hàng số phía trên chữ cái.", 16, MUTED))


func _on_ai_selected(index: int) -> void:
	_ai_level = ["easy", "normal", "hard"][index]
	settings_changed.emit(_ai_level, _reduced_fx)


func _on_reduced_fx_toggled(enabled: bool) -> void:
	_reduced_fx = enabled
	settings_changed.emit(_ai_level, _reduced_fx)


func _on_fullscreen_toggled(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)


func _is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]


func _start_rebind(action: String) -> void:
	_cancel_rebind()
	_listening_action = action
	_binding_buttons[action].text = "NHẤN PHÍM…"
	_status.text = "Đang đổi %s. Nhấn phím mới hoặc Esc để hủy." % _action_name(action)
	_status.add_theme_color_override("font_color", CYAN)


func _cancel_rebind() -> void:
	if _listening_action.is_empty():
		return
	_binding_buttons[_listening_action].text = _key_name(InputBindings.get_key(_listening_action))
	_listening_action = ""
	_status.text = "Đã hủy đổi phím."
	_status.add_theme_color_override("font_color", MUTED)


func _reset_bindings() -> void:
	_cancel_rebind()
	for action in _binding_buttons:
		InputBindings.rebind(action, InputBindings.DEFAULTS[action])
		_binding_buttons[action].text = _key_name(InputBindings.get_key(action))
	_status.text = "Đã đặt lại phím mặc định cho hai người chơi."
	_status.add_theme_color_override("font_color", CYAN)


func _close() -> void:
	_cancel_rebind()
	visible = false
	closed.emit()


func _action_name(action: String) -> String:
	if action == "pause":
		return "Tạm dừng"
	for entry in ACTIONS:
		if entry[0] == action:
			return "%s (P%s)" % [entry[1], action.substr(1, 1)]
	return action


func _key_name(code: int) -> String:
	return OS.get_keycode_string(code) if code != KEY_NONE else "—"


func _checkbox(caption: String) -> CheckBox:
	var check := CheckBox.new()
	check.text = caption
	check.custom_minimum_size.y = 60
	check.add_theme_font_override("font", FONT)
	check.add_theme_font_size_override("font_size", 20)
	check.add_theme_color_override("font_color", Color.WHITE)
	return check


func _label(caption: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(caption: String, size: int) -> Button:
	var button := Button.new()
	button.text = caption
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", CYAN)
	button.add_theme_stylebox_override("normal", _panel_style(Color("#1b2846"), Color("#465f98"), 2))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#253959"), CYAN, 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#172640"), CYAN, 2))
	return button


func _panel_style(fill: Color, edge: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(9)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
