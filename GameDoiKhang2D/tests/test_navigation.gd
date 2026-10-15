extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var game := (load("res://scenes/core/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	var menu := game.get_node_or_null("MainMenu")
	_check(menu != null, "Main menu không mở")
	if menu != null:
		menu.select_requested.emit("local")
	await process_frame
	var selection := game.get_node_or_null("CharacterSelect")
	_check(selection != null and selection.mode == "local", "Không mở chọn nhân vật local")
	if selection != null:
		selection.start_requested.emit("local", 6, 0)
	await process_frame
	var battle := game.get_node_or_null("Battle") as Battle
	_check(battle != null and battle.round_active, "Không vào được trận")
	if battle != null:
		_check(battle.p1.data.display_name == "Thanh Vân" and battle.p2.data.display_name == "Ngọc Vy", "Chọn nhân vật không truyền vào trận")
		battle._toggle_pause()
		_check(paused and battle._pause_panel.visible, "Pause menu không hiện")
		battle.settings_requested.emit()
	await process_frame
	var settings := game.get_node_or_null("Settings") as SettingsPanel
	_check(settings != null, "Nút settings trong pause không mở")
	if settings != null:
		settings._close()
	await process_frame
	if battle != null:
		battle._toggle_pause()
		battle.menu_requested.emit()
	await process_frame
	_check(game.get_node_or_null("MainMenu") != null, "Không quay về main menu")
	print("NAVIGATION_TEST_RESULT failures=", failures.size())
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
