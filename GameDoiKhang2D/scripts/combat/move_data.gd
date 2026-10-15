class_name MoveData
extends Resource

@export var key: String = ""
@export var display_name: String = ""
@export var damage: int = 0
@export var startup: int = 1
@export var active: int = 1
@export var recovery: int = 1
@export var range_px: float = 120.0
@export var height_px: float = 100.0
@export var hitstun: int = 18
@export var blockstun: int = 10
@export var knockback: float = 260.0
@export var knockdown: bool = false
@export var energy_cost: int = 0
@export var cooldown_frames: int = 0
@export var meter_gain: int = 8
@export var kind: String = "melee"

func duration() -> int:
	return startup + active + recovery
