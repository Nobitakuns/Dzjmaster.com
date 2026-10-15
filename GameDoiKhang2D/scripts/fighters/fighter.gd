class_name Fighter
extends CharacterBody2D

signal health_changed(fighter: Fighter)
signal energy_changed(fighter: Fighter)
signal hit_landed(attacker: Fighter, defender: Fighter, damage: int, combo: int, blocked: bool)
signal move_started(fighter: Fighter, move: MoveData)

const MAX_HP := 2000
const MAX_ENERGY := 100
const GRAVITY := 2200.0
const JUMP_SPEED := -950.0

var data: FighterData
var moves: Dictionary = {}
var opponent: Fighter
var battle: Node2D
var slot: int = 1
var is_ai: bool = false
var ai_controller: AIController
var hp: int = MAX_HP
var energy: int = 0
var facing: int = 1
var state: String = "neutral"
var state_frames: int = 0
var current_move: MoveData
var move_frame: int = 0
var cooldowns := {"skill": 0, "ultimate": 0}
var hitstop_frames: int = 0
var invulnerable_frames: int = 0
var combo_count: int = 0
var combo_damage: int = 0
var combo_last_frame: int = -1000
var combo_target_id: int = 0
var landed_this_move: bool = false
var queued_action: String = ""
var combo_sequence_stage: int = 0
var action_serial: int = 0
var hit_targets: Dictionary = {}
var _special_spawned: bool = false
var _blocking: bool = false
var _crouching: bool = false
var _last_horizontal: float = 0.0
var _visual: Node2D
var _animation_player: AnimationPlayer
var _hitbox: Area2D
var _hitbox_shape: CollisionShape2D
var _hurtbox: Area2D
var _body_shape: CollisionShape2D
var _animation_clock: float = 0.0

func _ready() -> void:
	_build_collision()
	_visual = FighterVisual.new()
	_visual.name = "FighterVisual"
	add_child(_visual)
	_build_animations()
	if data != null:
		_visual.configure(data.display_name, data.accent)

func _build_animations() -> void:
	_animation_player = AnimationPlayer.new()
	_animation_player.name = "AnimationPlayer"
	add_child(_animation_player)
	var library := AnimationLibrary.new()
	var poses := {
		"idle": [0.75, Vector2(1.012, 0.991), true],
		"walk_forward": [0.34, Vector2(1.0, 0.975), true],
		"walk_backward": [0.42, Vector2(1.0, 0.982), true],
		"jump": [0.35, Vector2(0.98, 1.03), false],
		"fall": [0.35, Vector2(1.02, 0.99), false],
		"crouch": [0.3, Vector2(1.04, 0.94), true],
		"block": [0.25, Vector2(1.02, 0.98), true],
		"attack1": [0.35, Vector2(1.045, 0.99), false],
		"attack2": [0.5, Vector2(1.06, 0.98), false],
		"attack3": [0.6, Vector2(1.075, 0.98), false],
		"skill": [0.8, Vector2(1.05, 1.02), false],
		"ultimate": [1.6, Vector2(1.08, 1.04), false],
		"hit_reaction": [0.32, Vector2(0.94, 0.97), false],
		"knockdown": [0.7, Vector2(1.08, 0.94), false],
		"get_up": [0.3, Vector2(0.98, 1.03), false],
		"victory": [0.75, Vector2(1.02, 1.01), true],
		"defeat": [0.75, Vector2(1.0, 0.94), false],
	}
	for pose in poses:
		var spec: Array = poses[pose]
		var animation := Animation.new()
		animation.length = float(spec[0])
		animation.loop_mode = Animation.LOOP_LINEAR if bool(spec[2]) else Animation.LOOP_NONE
		var track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath("FighterVisual:scale"))
		animation.track_insert_key(track, 0.0, Vector2.ONE)
		animation.track_insert_key(track, animation.length * 0.5, spec[1])
		animation.track_insert_key(track, animation.length, Vector2.ONE)
		library.add_animation(pose, animation)
	_animation_player.add_animation_library("", library)

func configure(fighter_data: FighterData, player_slot: int, owner_battle: Node2D, computer: bool = false, ai_level: String = "normal") -> void:
	data = fighter_data
	moves = MoveCatalog.create(data)
	slot = player_slot
	battle = owner_battle
	is_ai = computer
	if computer:
		ai_controller = AIController.new(ai_level)
	if is_node_ready() and _visual != null:
		_visual.configure(data.display_name, data.accent)
	reset_round()

func _build_collision() -> void:
	collision_layer = 1
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	floor_snap_length = 6.0
	_body_shape = CollisionShape2D.new()
	_body_shape.name = "BodyCollision"
	var body_rect := RectangleShape2D.new()
	body_rect.size = Vector2(76, 232)
	_body_shape.shape = body_rect
	_body_shape.position = Vector2(0, -116)
	add_child(_body_shape)
	_hurtbox = Area2D.new()
	_hurtbox.name = "Hurtbox"
	_hurtbox.collision_layer = 2
	_hurtbox.collision_mask = 0
	_hurtbox.monitorable = true
	_hurtbox.monitoring = false
	_hurtbox.position = Vector2(0, -116)
	var hurt_shape := CollisionShape2D.new()
	var hurt_rect := RectangleShape2D.new()
	hurt_rect.size = Vector2(90, 228)
	hurt_shape.shape = hurt_rect
	_hurtbox.add_child(hurt_shape)
	add_child(_hurtbox)
	_hitbox = Area2D.new()
	_hitbox.name = "Hitbox"
	_hitbox.collision_layer = 4
	_hitbox.collision_mask = 2
	_hitbox.monitoring = true
	_hitbox.monitorable = false
	_hitbox_shape = CollisionShape2D.new()
	var hit_rect := RectangleShape2D.new()
	hit_rect.size = Vector2(100, 100)
	_hitbox_shape.shape = hit_rect
	_hitbox_shape.disabled = true
	_hitbox.add_child(_hitbox_shape)
	add_child(_hitbox)
	_hitbox.area_entered.connect(_on_hitbox_area_entered)

func reset_round() -> void:
	hp = MAX_HP
	energy = 0
	state = "neutral"
	state_frames = 0
	current_move = null
	move_frame = 0
	velocity = Vector2.ZERO
	hitstop_frames = 0
	invulnerable_frames = 0
	combo_count = 0
	combo_damage = 0
	combo_last_frame = -1000
	queued_action = ""
	combo_sequence_stage = 0
	hit_targets.clear()
	cooldowns = {"skill": 0, "ultimate": 0}
	_blocking = false
	_crouching = false
	if _hitbox_shape != null:
		_hitbox_shape.set_deferred("disabled", true)
	health_changed.emit(self)
	energy_changed.emit(self)

func _physics_process(delta: float) -> void:
	if battle == null:
		return
	_animation_clock += delta
	if not battle.round_active:
		_update_visual({})
		return
	for key in cooldowns:
		cooldowns[key] = maxi(0, int(cooldowns[key]) - 1)
	if invulnerable_frames > 0:
		invulnerable_frames -= 1
	if hitstop_frames > 0:
		hitstop_frames -= 1
		_update_visual({})
		return
	if opponent != null and absf(opponent.global_position.x - global_position.x) > 4.0:
		facing = 1 if opponent.global_position.x > global_position.x else -1
	var intent := _read_intent()
	if state in ["hit", "blockstun", "knockdown", "getup"]:
		_tick_stun()
	elif current_move != null:
		_tick_move(intent)
	else:
		_tick_neutral(intent)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	move_and_slide()
	position.x = clampf(position.x, 105.0, 1815.0)
	_update_visual(intent)

func _read_intent() -> Dictionary:
	if is_ai and ai_controller != null:
		return ai_controller.get_intent(self, opponent)
	var prefix := "p%d_" % slot
	return {
		"horizontal": Input.get_axis(prefix + "left", prefix + "right"),
		"jump": Input.is_action_just_pressed(prefix + "jump"),
		"crouch": Input.is_action_pressed(prefix + "crouch"),
		"block": Input.is_action_pressed(prefix + "block"),
		"punch": Input.is_action_just_pressed(prefix + "punch"),
		"kick": Input.is_action_just_pressed(prefix + "kick"),
		"skill": Input.is_action_just_pressed(prefix + "skill"),
		"ultimate": Input.is_action_just_pressed(prefix + "ultimate"),
	}

func _tick_neutral(intent: Dictionary) -> void:
	state = "neutral"
	_blocking = bool(intent.get("block", false)) and is_on_floor()
	_crouching = bool(intent.get("crouch", false)) and is_on_floor()
	_last_horizontal = float(intent.get("horizontal", 0.0))
	if _blocking or _crouching:
		velocity.x = move_toward(velocity.x, 0.0, 95.0)
	else:
		velocity.x = _last_horizontal * data.speed
	if bool(intent.get("jump", false)) and is_on_floor() and not _blocking:
		velocity.y = JUMP_SPEED
	if _blocking:
		return
	if bool(intent.get("ultimate", false)) and request_move("ultimate"):
		return
	if bool(intent.get("skill", false)) and request_move("skill"):
		return
	if bool(intent.get("kick", false)) and request_move("attack2"):
		return
	if bool(intent.get("punch", false)):
		request_move("attack1")

func request_move(key: String) -> bool:
	if data == null or battle == null or not battle.round_active or state in ["hit", "blockstun", "knockdown", "getup", "defeat", "victory"]:
		return false
	if current_move != null:
		if current_move.key == "attack1" and key == "attack2":
			queued_action = "attack2"
			return true
		if current_move.key == "attack2" and key == "attack1" and combo_sequence_stage == 2:
			queued_action = "attack3"
			return true
		return false
	var move: MoveData = moves.get(key)
	if move == null:
		return false
	if energy < move.energy_cost or int(cooldowns.get(key, 0)) > 0:
		return false
	_start_move(move)
	return true

func _start_move(move: MoveData) -> void:
	var previous_key := current_move.key if current_move != null else ""
	var previous_landed := landed_this_move
	if move.key == "attack1":
		combo_sequence_stage = 1
	elif move.key == "attack2":
		combo_sequence_stage = 2 if previous_key == "attack1" and previous_landed else 0
	elif move.key == "attack3":
		combo_sequence_stage = 3 if previous_key == "attack2" and previous_landed and combo_sequence_stage == 2 else 0
	else:
		combo_sequence_stage = 0
	current_move = move
	state = "attack"
	move_frame = 0
	velocity.x = 0.0
	_blocking = false
	_crouching = false
	queued_action = ""
	landed_this_move = false
	_special_spawned = false
	action_serial += 1
	hit_targets.clear()
	if move.energy_cost > 0:
		add_energy(-move.energy_cost)
	if move.cooldown_frames > 0:
		cooldowns[move.key] = move.cooldown_frames
	if move.key == "ultimate":
		battle.begin_ultimate(self)
	move_started.emit(self, move)

func _tick_move(intent: Dictionary) -> void:
	if current_move == null:
		return
	if bool(intent.get("kick", false)) and current_move.key == "attack1":
		queued_action = "attack2"
	elif bool(intent.get("punch", false)) and current_move.key == "attack2" and combo_sequence_stage == 2:
		queued_action = "attack3"
	move_frame += 1
	var start_active: int = current_move.startup
	var end_active: int = current_move.startup + current_move.active
	var active_now := move_frame >= start_active and move_frame < end_active
	if active_now:
		if current_move.key in ["attack1", "attack2", "attack3"] or current_move.kind == "dash":
			_set_hitbox(true)
			if current_move.kind == "dash":
				velocity.x = facing * 1150.0
		else:
			_set_hitbox(false)
			if not _special_spawned:
				battle.spawn_special(self, current_move)
				_special_spawned = true
	else:
		_set_hitbox(false)
		velocity.x = move_toward(velocity.x, 0.0, 95.0)
	if queued_action != "" and landed_this_move and move_frame >= end_active - 1 and move_frame < current_move.duration() - 2:
		var followup: MoveData = moves.get(queued_action)
		if followup != null:
			_start_move(followup)
			return
	if move_frame >= current_move.duration():
		current_move = null
		state = "neutral"
		queued_action = ""
		_set_hitbox(false)

func _set_hitbox(enabled: bool) -> void:
	if _hitbox_shape == null:
		return
	if not enabled:
		_hitbox_shape.set_deferred("disabled", true)
		return
	if current_move == null:
		return
	var rect := _hitbox_shape.shape as RectangleShape2D
	rect.size = Vector2(current_move.range_px, current_move.height_px)
	_hitbox.position = Vector2(facing * (42.0 + current_move.range_px * 0.5), -120.0)
	_hitbox_shape.set_deferred("disabled", not enabled)
	if enabled:
		for area in _hitbox.get_overlapping_areas():
			_on_hitbox_area_entered(area)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if current_move == null or move_frame < current_move.startup or move_frame >= current_move.startup + current_move.active:
		return
	var target := area.get_parent() as Fighter
	if target == null or target == self or target.hp <= 0 or hit_targets.has(target.get_instance_id()):
		return
	hit_targets[target.get_instance_id()] = true
	var dealt := target.receive_hit(current_move, self)
	if dealt >= 0:
		landed_this_move = true

func receive_hit(move: MoveData, attacker: Fighter, damage_factor: float = 1.0) -> int:
	if hp <= 0 or invulnerable_frames > 0 or not battle.round_active:
		return -1
	var attack_direction := 1 if attacker.global_position.x > global_position.x else -1
	var can_block := _blocking and is_on_floor() and facing == attack_direction and state == "neutral"
	var counter := state == "attack" and current_move != null and move_frame < current_move.startup
	var scale := 1.0 if can_block else attacker.register_combo_hit(self)
	var base_damage := float(move.damage) * attacker.data.attack / data.defense * damage_factor * scale
	if counter:
		base_damage *= 1.16
	var damage := maxi(1, roundi(base_damage * (0.20 if can_block else 1.0)))
	hp = maxi(0, hp - damage)
	if can_block:
		state = "blockstun"
		state_frames = move.blockstun
		velocity.x = -attack_direction * move.knockback * 0.25
	else:
		current_move = null
		queued_action = ""
		_set_hitbox(false)
		state = "knockdown" if move.knockdown else "hit"
		state_frames = maxi(42, move.hitstun + 12) if move.knockdown else move.hitstun
		velocity.x = -attack_direction * move.knockback
		if move.knockdown and is_on_floor():
			velocity.y = -280.0
	attacker.hitstop_frames = maxi(attacker.hitstop_frames, 6 if move.key == "ultimate" else 3)
	hitstop_frames = maxi(hitstop_frames, 8 if move.key == "ultimate" else 5)
	attacker.add_energy(move.meter_gain)
	add_energy(5 if can_block else 8)
	health_changed.emit(self)
	if not can_block:
		attacker.combo_damage += damage
	attacker.hit_landed.emit(attacker, self, damage, attacker.combo_count, can_block)
	if _visual != null:
		_visual.flash_hit()
	if hp == 0:
		state = "defeat"
		current_move = null
		_set_hitbox(false)
		battle.on_fighter_ko(self)
	return damage

func register_combo_hit(target: Fighter) -> float:
	var frame := Engine.get_physics_frames()
	if combo_target_id == target.get_instance_id() and frame - combo_last_frame <= 90:
		combo_count += 1
	else:
		combo_count = 1
		combo_damage = 0
	combo_target_id = target.get_instance_id()
	combo_last_frame = frame
	return maxf(0.55, 1.0 - float(combo_count - 1) * 0.10)

func add_energy(amount: int) -> void:
	var next_energy := clampi(energy + amount, 0, MAX_ENERGY)
	if energy != next_energy:
		energy = next_energy
		energy_changed.emit(self)

func _tick_stun() -> void:
	state_frames -= 1
	velocity.x = move_toward(velocity.x, 0.0, 18.0)
	if state_frames <= 0:
		if state == "knockdown":
			state = "getup"
			state_frames = 16
		elif state == "getup":
			state = "neutral"
			invulnerable_frames = 14
		else:
			state = "neutral"

func _update_visual(intent: Dictionary) -> void:
	if _visual == null:
		return
	var pose := state
	var progress := _animation_clock
	if state == "attack" and current_move != null:
		pose = current_move.key
		progress = float(move_frame) / float(maxi(1, current_move.duration()))
	elif state == "neutral":
		if not is_on_floor():
			pose = "jump" if velocity.y < 0 else "fall"
		elif _blocking:
			pose = "block"
		elif _crouching:
			pose = "crouch"
		elif absf(_last_horizontal) > 0.1:
			pose = "walk_forward" if signf(_last_horizontal) == facing else "walk_backward"
		else:
			pose = "idle"
	elif state == "hit":
		pose = "hit_reaction"
	elif state == "blockstun":
		pose = "block"
	elif state == "getup":
		pose = "get_up"
	if _animation_player != null and _animation_player.has_animation(pose) and _animation_player.current_animation != pose:
		_animation_player.play(pose)
	_visual.set_pose(pose, progress, facing)
