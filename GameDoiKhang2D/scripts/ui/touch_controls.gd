class_name TouchControls
extends CanvasLayer

## Battle-only controls. The game still reads its normal InputMap actions.
## Call configure() after add_child(). Instantiate only while a battle is active.
signal pause_requested

const FONT: FontFile = preload("res://assets/fonts/DejaVuSans.ttf")
const ACTIONS: Array[String] = [
	"left", "right", "jump", "crouch", "punch", "kick", "skill", "ultimate", "block"
]
const NAMES := {
	"left": "←", "right": "→", "jump": "↑", "crouch": "↓",
	"punch": "ĐẤM", "kick": "ĐÁ", "skill": "KỸ\nNĂNG", "ultimate": "TUYỆT\nKỸ",
	"block": "ĐỠ"
}
const KEYS_P1 := {"punch": "J", "kick": "K", "skill": "L", "ultimate": "U", "block": "I"}
const KEYS_P2 := {"punch": "1", "kick": "2", "skill": "3", "ultimate": "4", "block": "5"}

@export var force_visible_for_test: bool = false:
	set(value):
		force_visible_for_test = value
		_refresh_visibility()

var player_slot: int = 1
var _root: Control
var _buttons: Dictionary = {}
var _labels: Dictionary = {}
var _joystick_ring: Panel
var _finger_actions: Dictionary = {} # touch index -> action suffix (or "pause")
var _hold_counts: Dictionary = {} # action suffix -> number of fingers
var _shown: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 15
	_root = Control.new()
	_root.name = "TouchControlsRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)
	_joystick_ring = Panel.new()
	_joystick_ring.name = "JoystickRing"
	_joystick_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joystick_ring.add_theme_stylebox_override("panel", _ring_style())
	_root.add_child(_joystick_ring)
	for suffix in ACTIONS:
		_make_button(suffix, Color("#50dfff") if suffix in ["left", "right", "jump", "crouch", "block"] else Color("#ff82cb"))
	_make_button("pause", Color("#ffdb76"))
	_update_labels()
	_root.resized.connect(_layout_buttons)
	_layout_buttons()
	_refresh_visibility()


func configure(slot: int = 1) -> void:
	if slot != 1 and slot != 2:
		push_warning("TouchControls supports player slots 1 and 2; using P1")
		slot = 1
	_release_all()
	player_slot = slot
	_update_labels()
	_refresh_visibility()


func _process(_delta: float) -> void:
	# A pause overlay must receive touches without the battle controls underneath it.
	_refresh_visibility()


func _input(event: InputEvent) -> void:
	if not _shown:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var had_action := _finger_actions.has(touch.index)
		if touch.pressed:
			_set_finger_action(touch.index, _hit_test(touch.position))
		else:
			_set_finger_action(touch.index, "")
		if had_action or _finger_actions.has(touch.index) or _hit_test(touch.position) != "":
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		var had_action := _finger_actions.has(drag.index)
		var action := _hit_test(drag.position)
		_set_finger_action(drag.index, action)
		if had_action or action != "":
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_release_all()


func _exit_tree() -> void:
	_release_all()


func _make_button(suffix: String, accent: Color) -> void:
	var panel := Panel.new()
	panel.name = "Touch_%s" % suffix
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_meta("accent", accent)
	panel.add_theme_stylebox_override("panel", _button_style(accent, false))
	_root.add_child(panel)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.clip_text = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(label)
	_buttons[suffix] = panel
	_labels[suffix] = label


func _button_style(accent: Color, held: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r * 0.16, accent.g * 0.16, accent.b * 0.22, 0.84 if held else 0.57)
	style.border_color = Color(accent.r, accent.g, accent.b, 1.0 if held else 0.76)
	style.set_border_width_all(4 if held else 3)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.38 if held else 0.19)
	style.shadow_size = 12 if held else 7
	return style


func _ring_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0a112b60")
	style.border_color = Color("#b8edff93")
	style.set_border_width_all(4)
	style.set_corner_radius_all(999)
	style.shadow_color = Color("#60b9ff40")
	style.shadow_size = 8
	return style


func _update_labels() -> void:
	if _labels.is_empty():
		return
	var keys: Dictionary = KEYS_P1 if player_slot == 1 else KEYS_P2
	for suffix in ACTIONS:
		var title: String = NAMES[suffix]
		if keys.has(suffix) and suffix not in ["left", "right", "jump", "crouch"]:
			title = "%s\n%s" % [keys[suffix], title]
		(_labels[suffix] as Label).text = title
	(_labels["pause"] as Label).text = "Ⅱ"


func _layout_buttons() -> void:
	if _buttons.is_empty():
		return
	var viewport_size := _root.size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var scale_factor := minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
	var diameter := 132.0 * scale_factor
	var safe := _safe_margins(viewport_size)
	var left := safe.x + 28.0 * scale_factor
	var right := viewport_size.x - safe.z - 28.0 * scale_factor
	var bottom := viewport_size.y - safe.w - 24.0 * scale_factor
	var stick_center := Vector2(left + 166.0 * scale_factor, bottom - 175.0 * scale_factor)
	_joystick_ring.position = stick_center - Vector2.ONE * 158.0 * scale_factor
	_joystick_ring.size = Vector2.ONE * 316.0 * scale_factor
	var dpad_centers := {
		"left": stick_center + Vector2(-99.0, 0.0) * scale_factor,
		"right": stick_center + Vector2(99.0, 0.0) * scale_factor,
		"jump": stick_center + Vector2(0.0, -99.0) * scale_factor,
		"crouch": stick_center + Vector2(0.0, 99.0) * scale_factor,
	}
	var attack_centers := {
		"punch": Vector2(right - 91.0 * scale_factor, bottom - 178.0 * scale_factor),
		"kick": Vector2(right - 286.0 * scale_factor, bottom - 93.0 * scale_factor),
		"skill": Vector2(right - 290.0 * scale_factor, bottom - 288.0 * scale_factor),
		"ultimate": Vector2(right - 100.0 * scale_factor, bottom - 367.0 * scale_factor),
		"block": Vector2(right - 472.0 * scale_factor, bottom - 197.0 * scale_factor),
	}
	for suffix in dpad_centers:
		_place(suffix, dpad_centers[suffix], 89.0 * scale_factor)
	for suffix in attack_centers:
		_place(suffix, attack_centers[suffix], diameter)
	_place("pause", Vector2(viewport_size.x * 0.5, bottom - 68.0 * scale_factor), diameter * 0.70)
	for label in _labels.values():
		(label as Label).add_theme_font_size_override("font_size", maxi(14, roundi(24.0 * scale_factor)))


func _place(suffix: String, center: Vector2, diameter: float) -> void:
	var panel := _buttons[suffix] as Control
	panel.position = center - Vector2.ONE * diameter * 0.5
	panel.size = Vector2.ONE * diameter
	panel.custom_minimum_size = Vector2.ONE * diameter


func _safe_margins(viewport_size: Vector2) -> Vector4:
	# Godot reports the Android cutout area in window pixels; scale it to UI coordinates.
	var margin := Vector4(42.0, 35.0, 42.0, 35.0) * minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
	if OS.get_name() == "Android":
		var window_size := Vector2(DisplayServer.window_get_size())
		var safe_rect := DisplayServer.get_display_safe_area()
		if window_size.x > 0.0 and window_size.y > 0.0 and safe_rect.size.x > 0 and safe_rect.size.y > 0:
			margin.x = maxf(margin.x, safe_rect.position.x * viewport_size.x / window_size.x)
			margin.y = maxf(margin.y, safe_rect.position.y * viewport_size.y / window_size.y)
			margin.z = maxf(margin.z, (window_size.x - safe_rect.end.x) * viewport_size.x / window_size.x)
			margin.w = maxf(margin.w, (window_size.y - safe_rect.end.y) * viewport_size.y / window_size.y)
	return margin


func _refresh_visibility() -> void:
	if not is_instance_valid(_root):
		return
	var should_show := (force_visible_for_test or OS.get_name() == "Android") and not get_tree().paused
	_root.visible = should_show
	if _shown == should_show:
		return
	_shown = should_show
	if not should_show:
		_release_all()


func _hit_test(point: Vector2) -> String:
	for suffix in _buttons:
		var rect := (_buttons[suffix] as Control).get_global_rect()
		if rect.get_center().distance_to(point) <= rect.size.x * 0.50:
			return suffix
	return ""


func _set_finger_action(index: int, suffix: String) -> void:
	var previous: String = _finger_actions.get(index, "")
	if previous == suffix:
		return
	if previous != "":
		_finger_actions.erase(index)
		if previous != "pause":
			var remaining: int = maxi(0, int(_hold_counts.get(previous, 0)) - 1)
			_hold_counts[previous] = remaining
			if remaining == 0:
				Input.action_release(_action_name(previous))
				_show_held(previous, false)
	if suffix == "":
		return
	_finger_actions[index] = suffix
	if suffix == "pause":
		pause_requested.emit()
		return
	var count: int = int(_hold_counts.get(suffix, 0))
	_hold_counts[suffix] = count + 1
	if count == 0:
		Input.action_press(_action_name(suffix))
		_show_held(suffix, true)


func _action_name(suffix: String) -> StringName:
	return StringName("p%d_%s" % [player_slot, suffix])


func _show_held(suffix: String, held: bool) -> void:
	if not _buttons.has(suffix):
		return
	var panel := _buttons[suffix] as Panel
	panel.add_theme_stylebox_override("panel", _button_style(panel.get_meta("accent") as Color, held))


func _release_all() -> void:
	for suffix in _hold_counts:
		if int(_hold_counts[suffix]) > 0:
			Input.action_release(_action_name(suffix))
			_show_held(suffix, false)
	_hold_counts.clear()
	_finger_actions.clear()
