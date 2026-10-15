extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _touch(controls: TouchControls, index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	controls._input(event)


func _drag(controls: TouchControls, index: int, point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = point
	controls._input(event)


func _center(controls: TouchControls, suffix: String) -> Vector2:
	return (controls._buttons[suffix] as Control).get_global_rect().get_center()


func _run() -> void:
	InputBindings.initialize()
	var desktop_controls := TouchControls.new()
	root.add_child(desktop_controls)
	await process_frame
	if OS.get_name() != "Android":
		_check(not desktop_controls._root.visible, "Touch controls appear by default on desktop")
	desktop_controls.queue_free()
	await process_frame
	var controls := TouchControls.new()
	controls.force_visible_for_test = true
	root.add_child(controls)
	controls.configure(1)
	await process_frame
	_check(controls._root.visible, "Touch controls are hidden in forced test mode")
	var left := _center(controls, "left")
	var right := _center(controls, "right")
	var punch := _center(controls, "punch")
	var kick := _center(controls, "kick")
	var pause := _center(controls, "pause")
	_check(left.x < right.x and punch.x > kick.x, "Touch layout is reversed")
	_touch(controls, 0, left, true)
	_touch(controls, 1, punch, true)
	_check(Input.is_action_pressed("p1_left") and Input.is_action_pressed("p1_punch"), "Simultaneous fingers did not press separate actions")
	_touch(controls, 2, left, true)
	_touch(controls, 0, left, false)
	_check(Input.is_action_pressed("p1_left"), "One released finger cancelled another finger's hold")
	_drag(controls, 2, right)
	_check(not Input.is_action_pressed("p1_left") and Input.is_action_pressed("p1_right"), "Drag did not transfer direction")
	_touch(controls, 2, right, false)
	_touch(controls, 1, punch, false)
	_check(not Input.is_action_pressed("p1_right") and not Input.is_action_pressed("p1_punch"), "Touch release left a held action")
	_touch(controls, 3, kick, true)
	controls.force_visible_for_test = false
	_check(not Input.is_action_pressed("p1_kick"), "Hiding controls did not release a held action")
	controls.force_visible_for_test = true
	controls.configure(2)
	_touch(controls, 4, punch, true)
	_check(Input.is_action_pressed("p2_punch") and not Input.is_action_pressed("p1_punch"), "P2 slot sent the wrong action")
	_touch(controls, 4, punch, false)
	var pauses := [0]
	controls.pause_requested.connect(func() -> void: pauses[0] += 1)
	_touch(controls, 5, pause, true)
	_check(pauses[0] == 1, "Pause button did not emit its signal")
	_touch(controls, 5, pause, false)
	controls.queue_free()
	await process_frame
	print("TOUCH_CONTROLS_TEST_RESULT failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
