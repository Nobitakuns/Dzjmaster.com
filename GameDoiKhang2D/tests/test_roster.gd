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
	var scene := load("res://scenes/battle/battle.tscn") as PackedScene
	for fighter_id in 8:
		var battle := scene.instantiate() as Battle
		root.add_child(battle)
		battle.start_match("local", fighter_id, (fighter_id + 1) % 8)
		battle.p1.position = Vector2(700, 849)
		battle.p2.position = Vector2(900, 849)
		await _frames(5)
		var data := battle.p1.data
		_check(data.display_name != "" and data.style != "", "Dữ liệu nhân vật %d thiếu" % fighter_id)
		battle.p1.add_energy(100)
		_check(battle.p1.request_move("skill"), "Skill nhân vật %d không khởi động" % fighter_id)
		await _frames(110)
		_check(battle.p2.hp < 2000, "Skill nhân vật %d không gây sát thương" % fighter_id)
		_check(battle.p1.energy <= 100, "Energy nhân vật %d vượt 100" % fighter_id)
		battle._start_round()
		battle.p1.position = Vector2(700, 849)
		battle.p2.position = Vector2(900, 849)
		await _frames(5)
		battle.p1.add_energy(100)
		_check(battle.p1.request_move("ultimate"), "Ultimate nhân vật %d không khởi động" % fighter_id)
		await _frames(125)
		_check(battle.p2.hp < 2000, "Ultimate nhân vật %d không gây sát thương" % fighter_id)
		_check(battle.p1.energy < 100, "Ultimate nhân vật %d không tốn năng lượng" % fighter_id)
		print("ROSTER fighter=", data.display_name, " skill+ultimate=checked")
		battle.queue_free()
		await process_frame
	print("ROSTER_TEST_RESULT failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
