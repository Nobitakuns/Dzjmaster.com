class_name AIController
extends RefCounted

## Supplies the same per-frame intent dictionary as a human player's InputMap.
## The fighter remains responsible for move legality, hitboxes, meter and damage.

var _level: String = "normal"
var _rng := RandomNumberGenerator.new()
var _reaction_frames: int = 0
var _cached_horizontal: float = 0.0
var _cached_block: bool = false
var _cached_crouch: bool = false
var _observed_move: String = ""
var _observed_move_frames: int = 0
var _combo_planned: bool = false
var _combo_sent: bool = false


func _init(level: String = "normal") -> void:
	_level = level.to_lower()
	if _level not in ["easy", "normal", "hard"]:
		_level = "normal"
	_rng.randomize()


func get_intent(self_fighter: CharacterBody2D, opponent: CharacterBody2D) -> Dictionary:
	var intent := _empty_intent()
	if not is_instance_valid(self_fighter) or not is_instance_valid(opponent):
		return intent
	if float(self_fighter.get("hp")) <= 0.0 or float(opponent.get("hp")) <= 0.0:
		return intent

	var state := str(self_fighter.get("state"))
	if state in ["hit", "blockstun", "knockdown", "getup", "victory", "defeat"]:
		_reset_idle_plan()
		return intent

	if state == "attack":
		_observe_attack(self_fighter)
		_try_combo(intent)
		return intent

	_observed_move = ""
	_observed_move_frames = 0
	_combo_sent = false
	if _reaction_frames > 0:
		_reaction_frames -= 1
		intent["horizontal"] = _cached_horizontal
		intent["block"] = _cached_block
		intent["crouch"] = _cached_crouch
		return intent

	_reaction_frames = _reaction_delay()
	_choose_neutral_intent(self_fighter, opponent, intent)
	_cached_horizontal = intent["horizontal"]
	_cached_block = intent["block"]
	_cached_crouch = intent["crouch"]
	return intent


func _choose_neutral_intent(self_fighter: CharacterBody2D, opponent: CharacterBody2D, intent: Dictionary) -> void:
	var delta_x := opponent.global_position.x - self_fighter.global_position.x
	var distance := absf(delta_x)
	var toward := signf(delta_x)
	var opposing_move: Variant = opponent.get("current_move")
	var threatened := false
	var whiffing := false
	if str(opponent.get("state")) == "attack" and opposing_move is Object:
		var reach: float = float(opposing_move.get("range_px"))
		var facing: float = float(opponent.get("facing"))
		var aimed_here := facing * -toward > 0.0
		threatened = aimed_here and distance < reach + 28.0
		whiffing = aimed_here and distance > reach + 34.0

	# A committed guard is held until the next reaction; easy AI often reacts late.
	if threatened and _rng.randf() < _guard_chance():
		intent["block"] = true
		intent["crouch"] = distance < 125.0 and _rng.randf() < 0.32
		return

	var energy: float = float(self_fighter.get("energy"))
	var cooldowns: Variant = self_fighter.get("cooldowns")
	var skill_ready := energy >= 25.0 and _cooldown_ready(cooldowns, "skill")
	var ultimate_ready := energy >= 100.0 and _cooldown_ready(cooldowns, "ultimate")
	var ultimate_chance := 0.36 if _level == "easy" else (0.72 if _level == "normal" else 0.92)
	if ultimate_ready and distance < 640.0 and _rng.randf() < ultimate_chance:
		intent["ultimate"] = true
		return

	var skill_chance := 0.12 if _level == "easy" else (0.35 if _level == "normal" else 0.58)
	if whiffing and _level == "hard" and skill_ready and _skill_in_range(self_fighter, distance):
		intent["skill"] = true
		return
	if skill_ready and _skill_in_range(self_fighter, distance) and _rng.randf() < skill_chance:
		intent["skill"] = true
		return

	if distance > 172.0:
		intent["horizontal"] = toward * _movement_scale()
		if distance > 280.0 and self_fighter.is_on_floor() and _rng.randf() < _jump_chance():
			intent["jump"] = true
		return

	# Hard AI moves into a whiff and attacks during the opponent's recovery.
	var attack_chance := 0.48 if _level == "easy" else (0.80 if _level == "normal" else 0.95)
	if whiffing and _level == "hard":
		attack_chance = 1.0
	if _rng.randf() < attack_chance:
		if distance < 125.0 and (_level == "hard" or _rng.randf() < 0.68):
			intent["punch"] = true
		else:
			intent["kick"] = true
	elif distance < 90.0 and _level != "easy":
		intent["horizontal"] = -toward * _movement_scale()
	else:
		intent["horizontal"] = toward * _movement_scale()


func _observe_attack(fighter: CharacterBody2D) -> void:
	var move: Variant = fighter.get("current_move")
	var key := ""
	if move is Object:
		key = str(move.get("key"))
	if key != _observed_move:
		_observed_move = key
		_observed_move_frames = 0
		_combo_sent = false
		var chance := 0.10 if _level == "easy" else (0.62 if _level == "normal" else 0.92)
		_combo_planned = _rng.randf() < chance
	var frame: Variant = fighter.get("move_frame")
	_observed_move_frames = int(frame) if frame is int else _observed_move_frames + 1


func _try_combo(intent: Dictionary) -> void:
	if not _combo_planned or _combo_sent:
		return
	# Follow-up buttons are accepted by Fighter only during its cancel window.
	if _observed_move == "attack1" and _observed_move_frames >= 8 and _observed_move_frames <= 18:
		intent["kick"] = true
		_combo_sent = true
	elif _observed_move == "attack2" and _observed_move_frames >= 13 and _observed_move_frames <= 25:
		intent["punch"] = true
		_combo_sent = true


func _skill_in_range(fighter: CharacterBody2D, distance: float) -> bool:
	var data: Variant = fighter.get("data")
	var style := ""
	if data is Object:
		style = str(data.get("style"))
	match style:
		"fire", "prism":
			return distance >= 130.0 and distance <= 460.0
		"butterfly", "sakura", "solar":
			return distance <= 245.0
		"thunder":
			return distance <= 510.0
		_:
			return distance >= 110.0 and distance <= 600.0


func _cooldown_ready(cooldowns: Variant, key: String) -> bool:
	return not (cooldowns is Dictionary) or float(cooldowns.get(key, 0)) <= 0.0


func _reaction_delay() -> int:
	match _level:
		"easy":
			return _rng.randi_range(22, 36)
		"hard":
			return _rng.randi_range(5, 9)
		_:
			return _rng.randi_range(10, 17)


func _guard_chance() -> float:
	match _level:
		"easy": return 0.12
		"hard": return 0.79
		_: return 0.48


func _jump_chance() -> float:
	match _level:
		"easy": return 0.04
		"hard": return 0.16
		_: return 0.11


func _movement_scale() -> float:
	match _level:
		"easy": return 0.62
		"hard": return 1.0
		_: return 0.84


func _reset_idle_plan() -> void:
	_reaction_frames = 0
	_cached_horizontal = 0.0
	_cached_block = false
	_cached_crouch = false
	_observed_move = ""
	_observed_move_frames = 0
	_combo_sent = false


func _empty_intent() -> Dictionary:
	return {
		"horizontal": 0.0,
		"jump": false,
		"crouch": false,
		"block": false,
		"punch": false,
		"kick": false,
		"skill": false,
		"ultimate": false,
	}
