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

func _run() -> void:
	InputBindings.initialize()
	var battle := (load("res://scenes/battle/battle.tscn") as PackedScene).instantiate() as Battle
	root.add_child(battle)
	battle.start_match("local", 6, 0)
	await _frames(5)
	_check(battle.p1.hp == 2000 and battle.p2.hp == 2000, "HP khởi đầu sai")
	_check(battle.p1.is_on_floor() and battle.p2.is_on_floor(), "Nhân vật không đứng trên sàn")
	var start_x := battle.p1.position.x
	Input.action_press("p1_right")
	await _frames(12)
	Input.action_release("p1_right")
	_check(battle.p1.position.x > start_x + 40.0, "P1 không di chuyển")
	_check(battle.p2.position.x == 1320.0, "P2 di chuyển theo P1")
	battle._start_round()
	await _frames(4)
	battle.p1.position.x = 600.0
	battle.p2.position.x = 1320.0
	_check(battle.p1.request_move("attack1"), "Không thể ra đòn")
	await _frames(32)
	_check(battle.p2.hp == 2000, "Đòn hụt vẫn gây sát thương")
	battle.p1.position.x = 820.0
	battle.p2.position.x = 980.0
	await _frames(4)
	_check(battle.p1.request_move("attack1"), "Không thể ra đòn trúng")
	await _frames(32)
	var normal_damage := 2000 - battle.p2.hp
	_check(normal_damage > 0 and normal_damage < 200, "Hitbox không gây sát thương đúng: %d" % normal_damage)
	_check(battle.p1.combo_count == 1, "Combo đòn đầu không đúng")
	battle._start_round()
	battle.p1.position.x = 820.0
	battle.p2.position.x = 980.0
	await _frames(4)
	Input.action_press("p2_block")
	await _frames(3)
	battle.p1.request_move("attack1")
	await _frames(32)
	Input.action_release("p2_block")
	var block_damage := 2000 - battle.p2.hp
	_check(block_damage > 0 and block_damage < normal_damage, "Block không giảm sát thương: %d vs %d" % [block_damage, normal_damage])
	battle._start_round()
	battle.p1.position.x = 700.0
	battle.p2.position.x = 1150.0
	await _frames(4)
	_check(not battle.p1.request_move("ultimate"), "Ultimate dùng được khi không đủ năng lượng")
	battle.p1.add_energy(100)
	_check(battle.p1.request_move("skill"), "Skill không kích hoạt")
	await _frames(90)
	_check(battle.p2.hp < 2000, "Holy Light Wave không trúng")
	_check(battle.p1.energy <= 100, "Năng lượng vượt giới hạn")
	await _frames(25)
	battle.p1.add_energy(100)
	_check(battle.p1.request_move("ultimate"), "Ultimate không kích hoạt dù đủ năng lượng")
	await _frames(100)
	_check(battle.p1.energy < 100, "Ultimate không tốn năng lượng")
	battle._start_round()
	battle.p1.position.x = 820.0
	battle.p2.position.x = 980.0
	battle.p2.hp = 1
	await _frames(4)
	battle.p1.request_move("attack1")
	await _frames(25)
	_check(not battle.round_active and battle.wins[0] == 1, "KO/round không hoạt động")
	await _frames(165)
	_check(battle.round_active and battle.round_number == 2 and battle.p2.hp == 2000, "Round 2 không reset")
	battle.p1.position.x = 820.0
	battle.p2.position.x = 980.0
	battle.p2.hp = 1
	await _frames(4)
	battle.p1.request_move("attack1")
	await _frames(170)
	_check(battle.wins[0] == 2 and battle._match_over and battle._result_panel.visible, "Best-of-3 không kết thúc trận")
	print("BATTLE_TEST_RESULT failures=", failures.size(), " hp=", battle.p2.hp, " wins=", battle.wins)
	battle.queue_free()
	await process_frame
	await create_timer(0.12).timeout
	quit(0 if failures.is_empty() else 1)
