class_name Battle
extends Node2D

signal menu_requested
signal select_requested(mode: String)
signal settings_requested

const ARENA_WIDTH := 1920.0
const FLOOR_Y := 850.0
const ROUND_SECONDS := 99.0

var round_active: bool = false
var round_number: int = 1
var time_left: float = ROUND_SECONDS
var wins: Array[int] = [0, 0]
var mode: String = "ai"
var ai_level: String = "normal"
var p1_id: int = 6
var p2_id: int = 0
var p1: Fighter
var p2: Fighter
var _hud: BattleHUD
var _touch_controls: TouchControls
var _arena: ArenaVisual
var _camera: Camera2D
var _pause_layer: CanvasLayer
var _pause_panel: Control
var _result_layer: CanvasLayer
var _result_panel: Control
var _round_delay: float = -1.0
var _match_over: bool = false
var _camera_shake: float = 0.0
var _ultimate_cutin: float = 0.0
var _effect_count: int = 0
var _reduced_fx: bool = false
var _sounds: Dictionary = {}
var _font: Font

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = load("res://assets/fonts/DejaVuSans.ttf") as Font
	_arena = ArenaVisual.new()
	_arena.name = "NeonUndergroundArena"
	_arena.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_arena)
	_build_ground()
	_camera = Camera2D.new()
	_camera.name = "BattleCamera"
	_camera.position = Vector2(960, 540)
	_camera.enabled = true
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 4.5
	add_child(_camera)
	_build_pause_menu()
	_build_result_menu()
	_touch_controls = TouchControls.new()
	_touch_controls.name = "TouchControls"
	add_child(_touch_controls)
	_touch_controls.configure(1)
	_touch_controls.pause_requested.connect(_toggle_pause)
	_load_sounds()

func start_match(new_mode: String = "ai", fighter1: int = 6, fighter2: int = 0, difficulty: String = "normal", reduced_fx: bool = false) -> void:
	mode = new_mode
	p1_id = fighter1
	p2_id = fighter2
	ai_level = difficulty
	_reduced_fx = reduced_fx
	if p1 != null:
		p1.queue_free()
	if p2 != null:
		p2.queue_free()
	p1 = Fighter.new()
	p1.name = "Player1"
	p1.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(p1)
	p1.configure(FighterRoster.get_fighter(p1_id), 1, self)
	p2 = Fighter.new()
	p2.name = "Player2"
	p2.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(p2)
	p2.configure(FighterRoster.get_fighter(p2_id), 2, self, mode == "ai", ai_level)
	p1.opponent = p2
	p2.opponent = p1
	p1.hit_landed.connect(_on_hit_landed)
	p2.hit_landed.connect(_on_hit_landed)
	_hud = BattleHUD.new()
	_hud.name = "BattleHUD"
	_hud.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_hud)
	_hud.configure(p1.data, p2.data, mode)
	wins = [0, 0]
	round_number = 1
	_match_over = false
	_start_round()

func _build_ground() -> void:
	var floor := StaticBody2D.new()
	floor.name = "GroundCollision"
	floor.collision_layer = 1
	floor.collision_mask = 0
	floor.position = Vector2(960, 910)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ARENA_WIDTH + 300, 120)
	shape.shape = rect
	floor.add_child(shape)
	add_child(floor)
	for wall_x in [65.0, 1855.0]:
		var wall := StaticBody2D.new()
		wall.collision_layer = 1
		wall.collision_mask = 0
		wall.position = Vector2(wall_x, 500)
		var wall_shape := CollisionShape2D.new()
		var wall_rect := RectangleShape2D.new()
		wall_rect.size = Vector2(60, 850)
		wall_shape.shape = wall_rect
		wall.add_child(wall_shape)
		add_child(wall)

func _start_round() -> void:
	get_tree().paused = false
	round_active = true
	_round_delay = -1.0
	time_left = ROUND_SECONDS
	_result_panel.hide()
	p1.reset_round()
	p2.reset_round()
	p1.position = Vector2(600, FLOOR_Y - 1)
	p2.position = Vector2(1320, FLOOR_Y - 1)
	p1.facing = 1
	p2.facing = -1
	for effect in get_tree().get_nodes_in_group("combat_effect"):
		if is_ancestor_of(effect):
			effect.queue_free()
	_hud.show_announcement("ROUND %d — FIGHT!" % round_number, 1.25)
	_sync_hud()

func _physics_process(delta: float) -> void:
	if get_tree().paused or p1 == null or p2 == null:
		return
	if round_active:
		time_left = maxf(0.0, time_left - delta)
		if time_left <= 0.0:
			_resolve_timeout()
		_sync_hud()
	elif _round_delay >= 0.0:
		_round_delay -= delta
		if _round_delay <= 0.0:
			if _match_over:
				_show_result()
			else:
				round_number += 1
				_start_round()
	if _ultimate_cutin > 0.0:
		_ultimate_cutin -= delta
		if _ultimate_cutin <= 0.0:
			_hud.hide_ultimate()

func _process(delta: float) -> void:
	if get_tree().paused or p1 == null or p2 == null:
		return
	var center_x := clampf((p1.position.x + p2.position.x) * 0.5, 850.0, 1070.0)
	var distance := absf(p1.position.x - p2.position.x)
	var target_zoom := clampf(remap(distance, 450.0, 1600.0, 1.10, 1.0), 1.0, 1.10)
	if _ultimate_cutin > 0.0:
		target_zoom = maxf(target_zoom, 1.16)
	_camera.zoom = _camera.zoom.lerp(Vector2.ONE * target_zoom, minf(1.0, delta * 4.0))
	_camera.position = _camera.position.lerp(Vector2(center_x, 540), minf(1.0, delta * 3.5))
	if _camera_shake > 0.0 and not _reduced_fx:
		_camera.offset = Vector2(randf_range(-_camera_shake, _camera_shake), randf_range(-_camera_shake, _camera_shake))
		_camera_shake = maxf(0.0, _camera_shake - delta * 35.0)
	else:
		_camera.offset = Vector2.ZERO
	_arena.set_camera_offset(_camera.position - Vector2(960, 540))

func _sync_hud() -> void:
	if _hud != null:
		_hud.update_state(p1.hp, p2.hp, p1.energy, p2.energy, time_left, round_number, wins[0], wins[1])

func _on_hit_landed(attacker: Fighter, defender: Fighter, damage: int, combo: int, blocked: bool) -> void:
	if not blocked:
		_hud.show_combo(attacker.slot, combo, attacker.combo_damage)
	spawn_impact(defender.global_position + Vector2(0, -125), attacker.data.accent, attacker.data.style)
	_camera_shake = 4.0 if blocked else 7.0 + minf(7.0, damage / 40.0)
	_play_sound("block" if blocked else "hit")
	_sync_hud()

func on_fighter_ko(loser: Fighter) -> void:
	if not round_active:
		return
	_finish_round(p1 if loser == p2 else p2, "K.O.")

func _resolve_timeout() -> void:
	if p1.hp > p2.hp:
		_finish_round(p1, "TIME OVER")
	elif p2.hp > p1.hp:
		_finish_round(p2, "TIME OVER")
	else:
		_finish_round(null, "DRAW — đánh lại round")

func _finish_round(winner: Fighter, reason: String) -> void:
	if not round_active:
		return
	round_active = false
	_round_delay = 2.5
	if winner == null:
		_hud.show_announcement(reason, 2.2)
	else:
		wins[winner.slot - 1] += 1
		var loser := p2 if winner == p1 else p1
		winner.state = "victory"
		loser.state = "defeat"
		_hud.show_announcement("%s — %s thắng!" % [reason, winner.data.display_name], 2.2)
		_match_over = wins[winner.slot - 1] >= 2
	_play_sound("ko")
	_sync_hud()

func begin_ultimate(fighter: Fighter) -> void:
	_ultimate_cutin = 0.65
	_hud.show_ultimate(fighter.data)
	p1.hitstop_frames = maxi(p1.hitstop_frames, 8)
	p2.hitstop_frames = maxi(p2.hitstop_frames, 8)
	_camera_shake = 16.0
	_play_sound("ultimate")

func spawn_special(fighter: Fighter, move: MoveData) -> void:
	var style := fighter.data.style
	var spec := {}
	var spawn_position := fighter.global_position + Vector2(fighter.facing * 150.0, -145.0)
	if move.key == "skill":
		match style:
			"shadow": spec = {"kind": "projectile", "speed": 690.0, "size": Vector2(180, 150), "lifetime": 92, "hits": 2, "interval": 12, "damage_factor": 0.53}
			"holy":
				spec = {"kind": "wave", "speed": 990.0, "size": Vector2(250, 125), "lifetime": 73, "hits": 1}
				fighter.hp = mini(Fighter.MAX_HP, fighter.hp + 55)
				fighter.health_changed.emit(fighter)
			"butterfly":
				spec = {"kind": "field", "size": Vector2(330, 230), "lifetime": 43, "hits": 3, "interval": 12, "damage_factor": 0.36}
				spawn_position = fighter.global_position + Vector2(fighter.facing * 110.0, -135.0)
			"sakura": spec = {"kind": "tornado", "speed": 245.0, "size": Vector2(270, 250), "lifetime": 65, "hits": 3, "interval": 15, "damage_factor": 0.36}
			"prism":
				var original_facing := fighter.facing
				fighter.position.x = clampf(fighter.opponent.position.x + original_facing * 165.0, 130.0, 1790.0)
				fighter.facing = -original_facing
				spec = {"kind": "portal", "size": Vector2(220, 250), "lifetime": 26, "hits": 1}
				spawn_position = fighter.opponent.global_position + Vector2(0, -125)
			"thunder":
				spec = {"kind": "lightning", "size": Vector2(185, 620), "lifetime": 36, "delay": 12, "hits": 2, "interval": 10, "damage_factor": 0.55}
				spawn_position = fighter.opponent.global_position + Vector2(0, -350)
			"solar":
				spec = {"kind": "sun", "size": Vector2(330, 320), "lifetime": 33, "delay": 7, "hits": 1}
				spawn_position = fighter.global_position + Vector2(0, -155)
			_:
				spec = {"kind": "projectile", "speed": 780.0, "size": Vector2(185, 130), "lifetime": 75, "hits": 1}
	else:
		match style:
			"shadow": spec = {"kind": "field", "size": Vector2(600, 460), "lifetime": 78, "delay": 5, "hits": 5, "interval": 12, "damage_factor": 0.23}
			"fire": spec = {"kind": "wave", "speed": 490.0, "size": Vector2(480, 310), "lifetime": 85, "hits": 4, "interval": 12, "damage_factor": 0.29}
			"butterfly": spec = {"kind": "field", "size": Vector2(570, 500), "lifetime": 73, "hits": 5, "interval": 11, "damage_factor": 0.23}
			"sakura": spec = {"kind": "tornado", "speed": 110.0, "size": Vector2(540, 480), "lifetime": 80, "hits": 5, "interval": 12, "damage_factor": 0.23}
			"prism": spec = {"kind": "portal", "size": Vector2(580, 450), "lifetime": 76, "hits": 5, "interval": 12, "damage_factor": 0.23}
			"thunder": spec = {"kind": "lightning", "size": Vector2(550, 720), "lifetime": 75, "delay": 12, "hits": 6, "interval": 10, "damage_factor": 0.20}
			"holy": spec = {"kind": "beam", "size": Vector2(1080, 420), "lifetime": 72, "hits": 5, "interval": 10, "damage_factor": 0.23}
			"solar": spec = {"kind": "sun", "size": Vector2(590, 590), "lifetime": 73, "delay": 9, "hits": 5, "interval": 11, "damage_factor": 0.23}
		if style in ["shadow", "butterfly", "prism", "thunder", "solar"]:
			spawn_position = fighter.opponent.global_position + Vector2(0, -185.0 if style != "thunder" else -390.0)
		elif style == "holy":
			spawn_position = fighter.global_position + Vector2(fighter.facing * 590.0, -170.0)
		elif style == "sakura":
			spawn_position = fighter.global_position + Vector2(fighter.facing * 300.0, -180.0)
	if spec.is_empty():
		return
	var effect := CombatEffect.new()
	effect.name = "%s_%s" % [style, move.key]
	effect.process_mode = Node.PROCESS_MODE_PAUSABLE
	effect.configure(fighter, move, spec)
	add_child(effect)
	effect.global_position = spawn_position
	_camera_shake = 13.0 if move.key == "ultimate" else 5.0
	_play_sound("skill")

func spawn_impact(location: Vector2, color: Color, style: String) -> void:
	if _reduced_fx and _effect_count % 2 == 0:
		_effect_count += 1
		return
	_effect_count += 1
	var fx := ImpactFX.new()
	fx.accent = color
	fx.style = style
	fx.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(fx)
	fx.global_position = location

func _input(event: InputEvent) -> void:
	if get_parent() != null and get_parent().get_node_or_null("Settings") != null:
		return
	if event.is_action_pressed("pause") and not event.is_echo() and p1 != null and not _match_over:
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	_pause_panel.visible = paused

func _build_pause_menu() -> void:
	_pause_layer = CanvasLayer.new()
	_pause_layer.name = "PauseMenu"
	_pause_layer.layer = 20
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)
	_pause_panel = _make_overlay("TẠM DỪNG")
	_pause_layer.add_child(_pause_panel)
	_add_overlay_button(_pause_panel, "TIẾP TỤC", func() -> void: _toggle_pause())
	_add_overlay_button(_pause_panel, "CHƠI LẠI ROUND", func() -> void: _toggle_pause(); _start_round())
	_add_overlay_button(_pause_panel, "CÀI ĐẶT", func() -> void: settings_requested.emit())
	_add_overlay_button(_pause_panel, "CHỌN NHÂN VẬT", func() -> void: get_tree().paused = false; select_requested.emit(mode))
	_add_overlay_button(_pause_panel, "MENU CHÍNH", func() -> void: get_tree().paused = false; menu_requested.emit())
	_pause_panel.hide()

func _build_result_menu() -> void:
	_result_layer = CanvasLayer.new()
	_result_layer.name = "MatchResult"
	_result_layer.layer = 19
	_result_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_result_layer)
	_result_panel = _make_overlay("KẾT THÚC TRẬN")
	_result_layer.add_child(_result_panel)
	_add_overlay_button(_result_panel, "ĐẤU LẠI", func() -> void: wins = [0, 0]; round_number = 1; _match_over = false; _start_round())
	_add_overlay_button(_result_panel, "CHỌN NHÂN VẬT", func() -> void: select_requested.emit(mode))
	_add_overlay_button(_result_panel, "MENU CHÍNH", func() -> void: menu_requested.emit())
	_result_panel.hide()

func _show_result() -> void:
	_round_delay = -1.0
	_result_panel.show()
	var title := _result_panel.get_node("Center/Panel/Items/Title") as Label
	var winner := p1 if wins[0] >= 2 else p2
	title.text = "%s CHIẾN THẮNG" % winner.data.display_name.to_upper()

func _make_overlay(title_text: String) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.09, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(530, 0)
	center.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.16, 0.95)
	style.border_color = Color(0.58, 0.32, 0.92)
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", style)
	var items := VBoxContainer.new()
	items.name = "Items"
	items.add_theme_constant_override("separation", 17)
	panel.add_child(items)
	var title := Label.new()
	title.name = "Title"
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.93, 0.92, 1.0))
	items.add_child(title)
	return overlay

func _add_overlay_button(overlay: Control, label_text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(450, 62)
	button.add_theme_font_override("font", _font)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(action)
	overlay.get_node("Center/Panel/Items").add_child(button)

func _load_sounds() -> void:
	for key in ["hit", "block", "skill", "ultimate", "ko"]:
		var path := "res://assets/audio/%s.wav" % key
		if ResourceLoader.exists(path):
			var player := AudioStreamPlayer.new()
			player.stream = load(path)
			add_child(player)
			_sounds[key] = player

func _exit_tree() -> void:
	for player in _sounds.values():
		if is_instance_valid(player):
			(player as AudioStreamPlayer).stop()

func _play_sound(key: String) -> void:
	if _sounds.has(key):
		(_sounds[key] as AudioStreamPlayer).play()
