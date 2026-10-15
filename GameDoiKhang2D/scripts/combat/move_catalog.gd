class_name MoveCatalog
extends RefCounted

const NORMAL_NAMES := [
	["Shadow Jab", "Dark Crescent", "Phantom Claw"],
	["Flame Punch", "Burning Kick", "Crimson Combo"],
	["Butterfly Slash", "Crimson Wing", "Scarlet Dance"],
	["Sakura Palm", "Blossom Kick", "Petal Dance"],
	["Prism Strike", "Rainbow Kick", "Mirage Combo"],
	["Electric Jab", "Thunder Kick", "Lightning Rush"],
	["Holy Palm", "Angel Kick", "Divine Combo"],
	["Solar Punch", "Sun Kick", "Golden Rush"],
]

static func create(data: FighterData) -> Dictionary:
	var names: Array = NORMAL_NAMES[data.fighter_id]
	var moves := {}
	moves["attack1"] = _make("attack1", names[0], 83, 6, 4, 12, 136, 100, 18, 9, 250, false, 0, 0, 10)
	moves["attack2"] = _make("attack2", names[1], 125, 10, 5, 17, 165, 130, 23, 13, 320, false, 0, 0, 13)
	moves["attack3"] = _make("attack3", names[2], 157, 9, 6, 21, 185, 145, 30, 15, 455, true, 0, 0, 17)
	var skill_kind := "projectile"
	match data.style:
		"fire": skill_kind = "dash"
		"butterfly", "sakura", "solar": skill_kind = "area"
		"prism": skill_kind = "teleport"
		"thunder": skill_kind = "strike"
	var skill := _make("skill", data.skill_name, 190, 15, 9, 24, 260, 165, 31, 17, 455, true, 25, 210, 12)
	skill.kind = skill_kind
	moves["skill"] = skill
	var ultimate := _make("ultimate", data.ultimate_name, 370, 26, 28, 43, 780, 230, 47, 22, 620, true, 100, 540, 0)
	ultimate.kind = "ultimate"
	moves["ultimate"] = ultimate
	return moves

static func _make(key: String, title: String, damage: int, startup: int, active: int, recovery: int, range_px: float, height_px: float, hitstun: int, blockstun: int, knockback: float, knockdown: bool, cost: int, cooldown: int, meter_gain: int) -> MoveData:
	var move := MoveData.new()
	move.key = key
	move.display_name = title
	move.damage = damage
	move.startup = startup
	move.active = active
	move.recovery = recovery
	move.range_px = range_px
	move.height_px = height_px
	move.hitstun = hitstun
	move.blockstun = blockstun
	move.knockback = knockback
	move.knockdown = knockdown
	move.energy_cost = cost
	move.cooldown_frames = cooldown
	move.meter_gain = meter_gain
	return move
