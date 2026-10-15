class_name CombatEffect
extends Area2D

var owner_fighter: Fighter
var move: MoveData
var style: String = "shadow"
var effect_kind: String = "projectile"
var travel_speed: float = 0.0
var direction: int = 1
var lifetime_frames: int = 45
var delay_frames: int = 0
var max_hits_per_target: int = 1
var hit_interval_frames: int = 12
var size_px: Vector2 = Vector2(180, 150)
var damage_factor: float = 1.0
var frame: int = 0
var _hits: Dictionary = {}
var _last_hit: Dictionary = {}
var _shape: CollisionShape2D

func configure(fighter: Fighter, attack: MoveData, spec: Dictionary) -> void:
	owner_fighter = fighter
	move = attack
	style = fighter.data.style
	effect_kind = str(spec.get("kind", "projectile"))
	travel_speed = float(spec.get("speed", 0.0))
	direction = fighter.facing
	lifetime_frames = int(spec.get("lifetime", 45))
	delay_frames = int(spec.get("delay", 0))
	max_hits_per_target = int(spec.get("hits", 1))
	hit_interval_frames = int(spec.get("interval", 12))
	size_px = spec.get("size", Vector2(180, 150))
	damage_factor = float(spec.get("damage_factor", 1.0))

func _ready() -> void:
	add_to_group("combat_effect")
	collision_layer = 4
	collision_mask = 2
	monitorable = false
	monitoring = true
	_shape = CollisionShape2D.new()
	_shape.name = "Hitbox"
	var rectangle := RectangleShape2D.new()
	rectangle.size = size_px
	_shape.shape = rectangle
	add_child(_shape)
	queue_redraw()

func _physics_process(delta: float) -> void:
	frame += 1
	if frame >= lifetime_frames or owner_fighter == null or not is_instance_valid(owner_fighter) or not owner_fighter.battle.round_active:
		queue_free()
		return
	position.x += direction * travel_speed * delta
	if global_position.x < -300 or global_position.x > 2220:
		queue_free()
		return
	if frame >= delay_frames:
		for area in get_overlapping_areas():
			var target := area.get_parent() as Fighter
			if target == null or target == owner_fighter or target.hp <= 0:
				continue
			var id := target.get_instance_id()
			if int(_hits.get(id, 0)) >= max_hits_per_target:
				continue
			if frame - int(_last_hit.get(id, -1000)) < hit_interval_frames:
				continue
			var dealt := target.receive_hit(move, owner_fighter, damage_factor)
			if dealt >= 0:
				_hits[id] = int(_hits.get(id, 0)) + 1
				_last_hit[id] = frame
				owner_fighter.battle.spawn_impact(target.global_position + Vector2(0, -120), owner_fighter.data.accent, style)
	queue_redraw()

func _draw() -> void:
	if owner_fighter == null:
		return
	var color := owner_fighter.data.accent
	var fade := 1.0 - float(frame) / float(maxi(1, lifetime_frames))
	var pulse := 0.75 + 0.25 * sin(float(frame) * 0.28)
	var tint := color
	tint.a = 0.24 * fade
	var edge := color
	edge.a = 0.8 * fade
	var w := size_px.x * 0.5
	var h := size_px.y * 0.5
	if frame < delay_frames:
		edge.a *= 0.4
		draw_rect(Rect2(-w, -h, size_px.x, size_px.y), edge, false, 4)
		return
	match effect_kind:
		"projectile", "wave":
			draw_circle(Vector2.ZERO, minf(w, h) * pulse, tint)
			draw_arc(Vector2.ZERO, minf(w, h) * pulse, 0, TAU, 28, edge, 9, true)
			for i in 3:
				var angle := float(i) * TAU / 3.0 + float(frame) * 0.13
				draw_line(Vector2.ZERO, Vector2(cos(angle), sin(angle)) * minf(w, h) * 1.1, edge, 5)
		"field", "tornado", "portal", "sun":
			draw_ellipse_placeholder(Vector2(w * 0.72, h * 0.7), tint, edge)
			for i in 5:
				var angle := float(i) * TAU / 5.0 + float(frame) * (0.14 if style == "sakura" else -0.1)
				var orbit := Vector2(cos(angle) * w * 0.66, sin(angle) * h * 0.64)
				draw_circle(orbit, 8.0 + 4.0 * pulse, edge)
		"lightning":
			var start := Vector2(-w * 0.25, -h)
			for i in 7:
				var end := Vector2((1 if i % 2 else -1) * w * 0.18, -h + (i + 1) * size_px.y / 7.0)
				draw_line(start, end, edge, 14, true)
				start = end
			draw_circle(Vector2.ZERO, w * 0.5, tint)
		"beam":
			draw_rect(Rect2(-w, -h * 0.42, size_px.x, h * 0.84), tint)
			draw_line(Vector2(-w, -h * 0.43), Vector2(w, -h * 0.43), edge, 8)
			draw_line(Vector2(-w, h * 0.43), Vector2(w, h * 0.43), edge, 8)
		_:
			draw_circle(Vector2.ZERO, minf(w, h), tint)
			draw_arc(Vector2.ZERO, minf(w, h), 0, TAU, 32, edge, 8, true)

func draw_ellipse_placeholder(radius: Vector2, fill: Color, outline: Color) -> void:
	var points := PackedVector2Array()
	for i in 33:
		var angle := float(i) * TAU / 32.0
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, fill)
	draw_polyline(points, outline, 7.0, true)
