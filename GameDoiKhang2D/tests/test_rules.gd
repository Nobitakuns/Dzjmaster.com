extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _frames(count: int) -> void:
	for i in count:
		await physics_frame

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _run() -> void:
	InputBindings.initialize()
	var battle := (load("res://scenes/battle/battle.tscn") as PackedScene).instantiate() as Battle
	root.add_child(battle)
	battle.start_match("local", 6, 0)
	await _frames(5)
	battle.p1.position.x = 820
	battle.p2.position.x = 1120
	Input.action_press("p1_right")
	Input.action_press("p2_left")
	await _frames(35)
	Input.action_release("p1_right")
	Input.action_release("p2_left")
	_check(battle.p1.position.x < battle.p2.position.x, "Hai nhân vật đi xuyên qua nhau")
	_check(battle.p2.position.x - battle.p1.position.x >= 74.0, "Va chạm thân nhân vật không giữ khoảng cách")
	battle._start_round()
	await _frames(4)
	var p1_x := battle.p1.position.x
	var p2_x := battle.p2.position.x
	Input.action_press("p1_left")
	Input.action_press("p2_right")
	await _frames(14)
	Input.action_release("p1_left")
	Input.action_release("p2_right")
	_check(battle.p1.position.x < p1_x - 50.0 and battle.p2.position.x > p2_x + 50.0, "P1/P2 không di chuyển độc lập")
	battle._start_round()
	battle.p1.position.x = 850
	battle.p2.position.x = 1020
	await _frames(4)
	Input.action_press("p2_punch")
	await _frames(2)
	Input.action_release("p2_punch")
	await _frames(25)
	_check(battle.p1.hp < 2000, "P2 không thể tấn công P1")
	battle._start_round()
	await _frames(5)
	Input.action_press("p1_jump")
	await _frames(3)
	Input.action_release("p1_jump")
	_check(battle.p1.velocity.y < 0 and not battle.p1.is_on_floor(), "Nhảy không rời sàn")
	await _frames(70)
	_check(battle.p1.is_on_floor() and absf(battle.p1.position.y - 850.0) <= 2.0, "Nhảy không tiếp đất")
	battle._start_round()
	battle.p1.position.x = 700
	battle.p2.position.x = 880
	await _frames(5)
	battle.p1.request_move("attack1")
	battle.p1.request_move("attack2")
	await _frames(12)
	_check(battle.p1.current_move != null and battle.p1.current_move.key == "attack2", "Attack1 không cancel sang Attack2")
	battle.p1.request_move("attack1")
	await _frames(17)
	_check(battle.p1.current_move != null and battle.p1.current_move.key == "attack3", "Attack2 không cancel sang Attack3")
	battle._start_round()
	await _frames(4)
	battle.p1.add_energy(100)
	battle.p1.request_move("skill")
	await _frames(55)
	_check(not battle.p1.request_move("skill"), "Skill bỏ qua cooldown")
	battle._start_round()
	await _frames(4)
	battle.time_left = 0.01
	await _frames(3)
	_check(not battle.round_active and battle.wins == [0, 0], "Draw khi hết giờ tính sai")
	await _frames(162)
	_check(battle.round_active and battle.round_number == 2 and battle.p1.hp == 2000, "Round draw không reset")
	var frozen_time := battle.time_left
	battle._toggle_pause()
	await _frames(10)
	_check(absf(battle.time_left - frozen_time) < 0.001, "Pause không dừng timer")
	battle._toggle_pause()
	battle.queue_free()
	await process_frame
	var ai_battle := (load("res://scenes/battle/battle.tscn") as PackedScene).instantiate() as Battle
	root.add_child(ai_battle)
	ai_battle.start_match("ai", 6, 0, "normal")
	await _frames(210)
	_check(ai_battle.p2.position.x < 1320.0, "AI không tiếp cận đối thủ")
	print("RULES_TEST_RESULT failures=", failures.size(), " ai_x=", ai_battle.p2.position.x)
	ai_battle.queue_free()
	await process_frame
	await create_timer(0.12).timeout
	quit(0 if failures.is_empty() else 1)
