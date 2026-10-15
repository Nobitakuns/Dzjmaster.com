extends Node

const MENU_SCENE := preload("res://scenes/main_menu/main_menu.tscn")
const SELECT_SCENE := preload("res://scenes/character_select/character_select.tscn")
const BATTLE_SCENE := preload("res://scenes/battle/battle.tscn")
const SETTINGS_PATH := "user://game_settings.json"

var _screen: Node
var _settings: SettingsPanel
var _ai_level: String = "normal"
var _reduced_fx: bool = false

func _ready() -> void:
	InputBindings.initialize()
	_load_settings()
	_show_menu()

func _replace_screen(scene: PackedScene) -> Node:
	get_tree().paused = false
	if _settings != null:
		_close_settings()
	if _screen != null:
		_screen.queue_free()
	_screen = scene.instantiate()
	add_child(_screen)
	return _screen

func _show_menu() -> void:
	var menu := _replace_screen(MENU_SCENE)
	menu.select_requested.connect(_show_select)
	menu.settings_requested.connect(_open_settings)

func _show_select(mode: String = "ai") -> void:
	var selection := _replace_screen(SELECT_SCENE)
	selection.set_mode(mode)
	selection.start_requested.connect(_start_battle)
	selection.back_requested.connect(_show_menu)

func _start_battle(mode: String, p1_id: int, p2_id: int) -> void:
	var battle := _replace_screen(BATTLE_SCENE) as Battle
	battle.menu_requested.connect(_show_menu)
	battle.select_requested.connect(_show_select)
	battle.settings_requested.connect(_open_settings)
	battle.start_match(mode, p1_id, p2_id, _ai_level, _reduced_fx)

func _open_settings() -> void:
	if _settings != null:
		return
	_settings = SettingsPanel.new()
	_settings.name = "Settings"
	_settings.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_settings)
	_settings.closed.connect(_close_settings)
	_settings.settings_changed.connect(_on_settings_changed)
	_settings.open(_ai_level, _reduced_fx)

func _close_settings() -> void:
	if _settings != null:
		_settings.queue_free()
		_settings = null

func _on_settings_changed(level: String, reduced: bool) -> void:
	_ai_level = level
	_reduced_fx = reduced
	if _screen is Battle:
		(_screen as Battle)._reduced_fx = reduced
		if (_screen as Battle).mode == "ai":
			(_screen as Battle).p2.ai_controller = AIController.new(level)
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"ai_level": _ai_level, "reduced_fx": _reduced_fx}))

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	if parsed is Dictionary:
		var level := str(parsed.get("ai_level", "normal"))
		_ai_level = level if level in ["easy", "normal", "hard"] else "normal"
		_reduced_fx = bool(parsed.get("reduced_fx", false))
