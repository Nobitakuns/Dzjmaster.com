class_name InputBindings
extends RefCounted

const SAVE_PATH := "user://keybindings.json"
const DEFAULTS := {
	"p1_left": KEY_A, "p1_right": KEY_D, "p1_jump": KEY_W, "p1_crouch": KEY_S,
	"p1_punch": KEY_J, "p1_kick": KEY_K, "p1_skill": KEY_L, "p1_ultimate": KEY_U, "p1_block": KEY_I,
	"p2_left": KEY_LEFT, "p2_right": KEY_RIGHT, "p2_jump": KEY_UP, "p2_crouch": KEY_DOWN,
	"p2_punch": KEY_1, "p2_kick": KEY_2, "p2_skill": KEY_3, "p2_ultimate": KEY_4, "p2_block": KEY_5,
	"pause": KEY_ESCAPE,
}

static func initialize() -> void:
	var saved := {}
	if FileAccess.file_exists(SAVE_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if parsed is Dictionary:
			saved = parsed
	for action in DEFAULTS:
		var code: int = int(saved.get(action, DEFAULTS[action]))
		_bind(action, code)

static func rebind(action: String, code: int) -> void:
	if not DEFAULTS.has(action) or code == KEY_NONE:
		return
	_bind(action, code)
	var saved := {}
	for name in DEFAULTS:
		saved[name] = get_key(name)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(saved, "\t"))

static func get_key(action: String) -> int:
	if not InputMap.has_action(action):
		return 0
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.physical_keycode
	return 0

static func _bind(action: String, code: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var key := InputEventKey.new()
	key.physical_keycode = code
	InputMap.action_add_event(action, key)
