extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _frames(count: int) -> void:
	for i in count:
		await physics_frame

func _touch(controls: TouchControls, finger: int, suffix: String, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = finger
	event.position = (controls._buttons[suffix] as Control).get_global_rect().get_center()
	event.pressed = pressed
	controls._input(event)

func _run() -> void:
	InputBindings.initialize()
	var battle := (load("res://scenes/battle/battle.tscn") as PackedScene).instantiate() as Battle
	root.add_child(battle)
	battle.start_match("ai", 6, 0, "easy")
	var controls := battle._touch_controls
	controls.force_visible_for_test = true
	await _frames(5)
	var start_x := battle.p1.position.x
	_touch(controls, 0, "right", true)
	await _frames(14)
	_touch(controls, 0, "right", false)
	_check(battle.p1.position.x > start_x + 55.0, "Nút di chuyển cảm ứng không điều khiển P1")
	battle.p1.position.x = 760
	battle.p2.position.x = 950
	await _frames(4)
	_touch(controls, 1, "punch", true)
	await _frames(3)
	_touch(controls, 1, "punch", false)
	await _frames(25)
	_check(battle.p2.hp < 2000, "Nút đấm cảm ứng không gây sát thương")
	_touch(controls, 2, "pause", true)
	await process_frame
	_check(paused and battle._pause_panel.visible, "Nút tạm dừng cảm ứng không mở menu")
	battle._toggle_pause()
	_check(not paused, "Không thể tiếp tục sau pause cảm ứng")
	print("ANDROID_BATTLE_TEST_RESULT failures=", failures.size())
	battle.queue_free()
	await process_frame
	await create_timer(0.12).timeout
	quit(0 if failures.is_empty() else 1)
