class_name FighterVisual
extends Node2D
## Art pose atlas changes with combat state; feet stay at the local origin.
## Hitboxes remain on Fighter so art can be replaced without changing combat.

const SHEET_PATHS := {
	"Ngọc Vy": "res://assets/characters/ngoc_vy_sheet.png",
	"Mai Anh": "res://assets/characters/mai_anh_sheet.png",
	"Huyền Chi": "res://assets/characters/huyen_chi_sheet.png",
	"Hồng Nhi": "res://assets/characters/hong_nhi_sheet.png",
	"Bảo Châu": "res://assets/characters/bao_chau_sheet.png",
	"Tử Anh": "res://assets/characters/tu_anh_sheet.png",
	"Thanh Vân": "res://assets/characters/thanh_van_sheet.png",
	"Ánh Dương": "res://assets/characters/anh_duong_sheet.png",
}

var display_name: String = "FIGHTER"
var theme_color: Color = Color("#8428d8")
var _state: String = "idle"
var _progress: float = 0.0
var _attack_phase: int = -1
var _facing: int = 1
var _clock: float = 0.0
var _hit_flash: float = 0.0
var _sprite: Sprite2D
var _atlas: AtlasTexture
var _shown_frame: int = -1


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "PoseSprite"
	_sprite.centered = true
	_sprite.scale = Vector2.ONE * 0.72
	add_child(_sprite)
	_load_sheet()


func configure(new_name: String, new_color: Color) -> void:
	display_name = new_name
	theme_color = new_color
	_load_sheet()
	queue_redraw()


func set_pose(state: String, progress: float, facing: int, attack_phase: int = -1) -> void:
	_state = state.to_lower().replace(" ", "_")
	_progress = progress
	_attack_phase = attack_phase
	_facing = 1 if facing >= 0 else -1
	_update_sprite()
	queue_redraw()


func flash_hit() -> void:
	_hit_flash = 0.16
	queue_redraw()


func _process(delta: float) -> void:
	_clock += delta
	if _hit_flash > 0.0:
		_hit_flash = maxf(0.0, _hit_flash - delta)
	_update_sprite()
	queue_redraw()


func _draw() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_clock * 3.0)
	_draw_ellipse(Vector2(0.0, -2.0), Vector2(64.0, 12.0), Color(0.00, 0.01, 0.04, 0.56))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(_facing), 1.0))
	_draw_aura(pulse)
	if _atlas == null:
		_draw_body()
	_draw_action_fx(pulse)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _load_sheet() -> void:
	if _sprite == null or not SHEET_PATHS.has(display_name):
		return
	var sheet := load(SHEET_PATHS[display_name]) as Texture2D
	if sheet == null:
		return
	_atlas = AtlasTexture.new()
	_atlas.atlas = sheet
	_atlas.region = Rect2(0.0, 0.0, 512.0, 512.0)
	_sprite.texture = _atlas
	_shown_frame = -1
	_update_sprite()


func _update_sprite() -> void:
	if _sprite == null or _atlas == null:
		return
	var frame := 0
	match _state:
		"walk", "walk_forward", "walk_backward", "run", "jump", "fall":
			frame = 1
		"attack1", "attack3", "attack_1", "attack_3", "jump_attack":
			frame = 2
		"attack2", "attack_2":
			frame = 3
		"block", "block_low", "blockstun", "hit", "hit_reaction", "crouch", "knockdown", "get_up", "defeat":
			frame = 4
		"skill", "ultimate", "victory":
			frame = 5
	if _state in ["walk", "walk_forward", "walk_backward", "run"]:
		# Alternating grounded and step poses prevents the run drawing from hovering.
		frame = 1 if fmod(_clock * 7.0, 1.0) < 0.50 else 0
	elif _attack_phase >= 0:
		# Fighter supplies the same startup/active/recovery phase used by its hitbox.
		if _attack_phase == 0:
			frame = 0
		elif _attack_phase == 2:
			frame = 4
	if frame != _shown_frame:
		_atlas.region = Rect2(float(frame % 3) * 512.0, float(floori(float(frame) / 3.0)) * 512.0, 512.0, 512.0)
		_shown_frame = frame
	_sprite.flip_h = _facing < 0
	var bob := 0.0
	if _state == "idle":
		bob = sin(_clock * 3.0) * 1.8
	elif _state in ["walk", "walk_forward", "walk_backward", "run"]:
		bob = absf(sin(_clock * 9.0)) * 5.0
	_sprite.position = Vector2(0.0, -165.0 - bob)
	_sprite.rotation = 0.0
	_sprite.scale = Vector2.ONE * 0.72
	if _state == "crouch":
		_sprite.position.y = -131.0
		_sprite.scale.y = 0.59
	elif _state in ["knockdown", "defeat"]:
		_sprite.position.y = -66.0
		_sprite.rotation = -0.80 * float(_facing)
	elif _state == "hit_reaction":
		_sprite.rotation = -0.13 * float(_facing)
	_sprite.modulate = Color("#ff9fb7") if _hit_flash > 0.0 else Color.WHITE


func _draw_body() -> void:
	var action: String = _state
	var step: float = sin(_progress * TAU)
	var is_walking: bool = action in ["walk", "walk_forward", "walk_backward", "run"]
	var is_low: bool = action in ["crouch", "block_low", "knockdown", "defeat", "get_up"]
	var is_air: bool = action in ["jump", "fall", "jump_attack"]
	var drop: float = 56.0 if is_low else 0.0
	var breathe: float = sin(_clock * 3.4) * (1.7 if action == "idle" else 0.7)
	var lean: float = 0.0
	if action in ["attack_1", "attack1", "attack_2", "attack2", "attack_3", "attack3", "skill", "ultimate"]:
		lean = 12.0
	elif action in ["hit", "hit_reaction", "knockdown", "defeat"]:
		lean = -15.0
	elif is_walking:
		lean = 4.0 * step

	var hip := Vector2(lean * 0.45, -91.0 + drop)
	var chest := Vector2(lean - 4.0, -169.0 + drop + breathe)
	var neck := chest + Vector2(0.0, -24.0)
	var head := chest + Vector2(-5.0, -69.0)
	var skin := Color("#f5d5cc")
	var outline := Color("#100d24")
	var armor := theme_color.darkened(0.41)
	var light := theme_color.lightened(0.41)
	if _hit_flash > 0.0:
		armor = Color.WHITE
		light = Color.WHITE
		skin = Color.WHITE

	var back_foot := Vector2(-36.0, -3.0)
	var front_foot := Vector2(39.0, -3.0)
	var back_knee := Vector2(-33.0, -48.0 + drop * 0.55)
	var front_knee := Vector2(40.0, -48.0 + drop * 0.55)
	if is_walking:
		back_foot.x += step * 28.0
		front_foot.x -= step * 28.0
		back_foot.y -= maxf(0.0, -step) * 12.0
		front_foot.y -= maxf(0.0, step) * 12.0
		back_knee.x += step * 16.0
		front_knee.x -= step * 16.0
	if is_air:
		back_foot = Vector2(-37.0, -43.0)
		front_foot = Vector2(48.0, -36.0)
		back_knee = Vector2(-31.0, -67.0)
		front_knee = Vector2(31.0, -59.0)
	if action in ["attack_2", "attack2", "jump_attack"]:
		front_knee = Vector2(65.0, -115.0 + drop)
		front_foot = Vector2(130.0, -132.0 + drop)
	if is_low:
		back_foot.x = -52.0
		front_foot.x = 53.0
		back_knee.y = -20.0
		front_knee.y = -23.0

	# Back hair and rear arm sit behind the torso.
	var hair := _hair_color()
	var hair_shape := PackedVector2Array([
		head + Vector2(-33.0, -12.0), head + Vector2(-42.0, 36.0),
		head + Vector2(-51.0, 88.0), head + Vector2(-24.0, 70.0),
		head + Vector2(15.0, 45.0), head + Vector2(27.0, -18.0)
	])
	draw_colored_polygon(hair_shape, outline)
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-30.0, -14.0), head + Vector2(-37.0, 35.0),
		head + Vector2(-44.0, 78.0), head + Vector2(-17.0, 62.0),
		head + Vector2(12.0, 40.0), head + Vector2(24.0, -17.0)
	]), hair)
	_draw_limb(hip + Vector2(-15.0, 0.0), back_knee, back_foot, armor.darkened(0.25), outline, 22.0)
	_draw_limb(hip + Vector2(15.0, 0.0), front_knee, front_foot, armor, outline, 23.0)
	_draw_boot(back_foot, outline, light)
	_draw_boot(front_foot, outline, light)

	var rear_shoulder := chest + Vector2(-25.0, 0.0)
	var rear_elbow := chest + Vector2(-42.0, 38.0)
	var rear_hand := chest + Vector2(-24.0, 68.0)
	if action == "block":
		rear_elbow = chest + Vector2(-26.0, -7.0)
		rear_hand = chest + Vector2(0.0, -35.0)
	_draw_limb(rear_shoulder, rear_elbow, rear_hand, armor.darkened(0.19), outline, 16.0)

	# Long coat panels provide a readable, character colored silhouette.
	draw_colored_polygon(PackedVector2Array([
		hip + Vector2(-24.0, 0.0), hip + Vector2(-47.0, 62.0),
		hip + Vector2(-11.0, 48.0), hip + Vector2(4.0, 4.0)
	]), outline)
	draw_colored_polygon(PackedVector2Array([
		hip + Vector2(-21.0, 1.0), hip + Vector2(-41.0, 54.0),
		hip + Vector2(-12.0, 44.0), hip + Vector2(2.0, 3.0)
	]), theme_color.darkened(0.22))
	var torso_outline := PackedVector2Array([
		chest + Vector2(-25.0, -7.0), chest + Vector2(26.0, -8.0),
		chest + Vector2(30.0, 31.0), hip + Vector2(19.0, 8.0),
		hip + Vector2(-20.0, 8.0), chest + Vector2(-30.0, 30.0)
	])
	draw_colored_polygon(torso_outline, outline)
	draw_colored_polygon(PackedVector2Array([
		chest + Vector2(-21.0, -4.0), chest + Vector2(21.0, -4.0),
		chest + Vector2(25.0, 27.0), hip + Vector2(16.0, 3.0),
		hip + Vector2(-16.0, 3.0), chest + Vector2(-24.0, 27.0)
	]), armor)
	draw_colored_polygon(PackedVector2Array([
		chest + Vector2(-12.0, 4.0), chest + Vector2(15.0, 4.0),
		chest + Vector2(19.0, 25.0), hip + Vector2(9.0, -2.0),
		hip + Vector2(-8.0, -2.0), chest + Vector2(-17.0, 24.0)
	]), light)
	draw_line(chest + Vector2(2.0, 6.0), hip + Vector2(2.0, -5.0), theme_color, 5.0, true)
	draw_circle(chest + Vector2(0.0, 18.0), 5.0, Color.WHITE)

	var front_shoulder := chest + Vector2(24.0, 0.0)
	var elbow := chest + Vector2(39.0, 32.0)
	var hand := chest + Vector2(35.0, 55.0)
	match action:
		"attack_1", "attack1", "attack_3", "attack3", "skill", "ultimate":
			elbow = chest + Vector2(63.0, 4.0)
			hand = chest + Vector2(113.0, -4.0)
		"block":
			elbow = chest + Vector2(38.0, -12.0)
			hand = chest + Vector2(20.0, -48.0)
		"victory":
			elbow = chest + Vector2(40.0, -36.0)
			hand = chest + Vector2(54.0, -88.0)
		"hit", "hit_reaction":
			elbow = chest + Vector2(12.0, 40.0)
			hand = chest + Vector2(-16.0, 16.0)
	_draw_limb(front_shoulder, elbow, hand, armor, outline, 17.0)
	draw_circle(hand, 10.0, outline)
	draw_circle(hand, 6.0, skin)

	# Face and hair are kept readable even when the character is mirrored.
	draw_circle(neck, 13.0, outline)
	draw_circle(neck, 10.0, skin)
	draw_circle(head, 37.0, outline)
	draw_circle(head, 33.0, skin)
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-32.0, -15.0), head + Vector2(-25.0, -34.0),
		head + Vector2(14.0, -39.0), head + Vector2(34.0, -23.0),
		head + Vector2(24.0, -6.0), head + Vector2(10.0, -20.0),
		head + Vector2(-6.0, 0.0), head + Vector2(-17.0, -15.0)
	]), hair)
	draw_line(head + Vector2(4.0, 4.0), head + Vector2(14.0, 3.0), outline, 3.0, true)
	draw_circle(head + Vector2(12.0, 5.0), 3.0, theme_color.lightened(0.55))
	draw_line(head + Vector2(14.0, 22.0), head + Vector2(22.0, 20.0), Color("#a86172"), 2.0, true)
	_draw_emblem(head, chest, light)
	if _hit_flash > 0.0:
		_draw_ellipse(chest + Vector2(0.0, -20.0), Vector2(50.0, 111.0), Color(1.0, 1.0, 1.0, _hit_flash * 1.8))


func _draw_limb(a: Vector2, joint: Vector2, end: Vector2, fill: Color, edge: Color, width: float) -> void:
	draw_line(a, joint, edge, width + 7.0, true)
	draw_line(joint, end, edge, width + 5.0, true)
	draw_circle(joint, width * 0.5 + 3.0, edge)
	draw_line(a, joint, fill, width, true)
	draw_line(joint, end, fill.lightened(0.09), width - 2.0, true)
	draw_circle(joint, width * 0.42, fill.lightened(0.12))


func _draw_boot(point: Vector2, edge: Color, light: Color) -> void:
	draw_line(point + Vector2(-10.0, -1.0), point + Vector2(15.0, -1.0), edge, 15.0, true)
	draw_line(point + Vector2(-7.0, -5.0), point + Vector2(13.0, -5.0), light, 5.0, true)


func _draw_emblem(head: Vector2, chest: Vector2, light: Color) -> void:
	if display_name == "Thanh Vân":
		for side in [-1.0, 1.0]:
			var origin: Vector2 = chest + Vector2(side * 23.0, 0.0)
			var tips := PackedVector2Array([
				origin, origin + Vector2(side * 42.0, -55.0),
				origin + Vector2(side * 74.0, -86.0),
				origin + Vector2(side * 58.0, -18.0),
				origin + Vector2(side * 36.0, 18.0)
			])
			draw_polyline(tips, Color(0.65, 0.92, 1.0, 0.75), 3.0, true)
		draw_arc(head + Vector2(0.0, -32.0), 42.0, PI + 0.25, TAU - 0.25, 24, light, 3.0, true)
	elif display_name == "Ngọc Vy":
		_draw_crescent(head + Vector2(-8.0, -46.0), 16.0, light)
		draw_line(chest + Vector2(-29.0, 13.0), chest + Vector2(-65.0, 49.0), theme_color, 4.0, true)
	elif display_name == "Mai Anh":
		_draw_flame(head + Vector2(-23.0, -28.0), light)
	elif display_name == "Huyền Chi":
		_draw_butterfly(head + Vector2(-25.0, -34.0), light)
	elif display_name == "Hồng Nhi":
		for i in 3:
			draw_circle(head + Vector2(-25.0 + 15.0 * i, -41.0 - float(i % 2) * 9.0), 5.0, light)
	elif display_name == "Bảo Châu":
		draw_colored_polygon(PackedVector2Array([
			head + Vector2(-4.0, -52.0), head + Vector2(6.0, -69.0),
			head + Vector2(16.0, -51.0), head + Vector2(5.0, -42.0)
		]), Color("#ffe683"))
	elif display_name == "Tử Anh":
		draw_polyline(PackedVector2Array([
			head + Vector2(-12.0, -43.0), head + Vector2(-2.0, -64.0),
			head + Vector2(3.0, -49.0), head + Vector2(17.0, -69.0)
		]), light, 4.0, true)
	elif display_name == "Ánh Dương":
		draw_arc(head + Vector2(0.0, -34.0), 42.0, PI + 0.2, TAU - 0.2, 24, light, 5.0, true)


func _draw_aura(pulse: float) -> void:
	var alpha: float = 0.15 + 0.07 * pulse
	if _state == "ultimate":
		alpha += 0.27
	elif _state == "skill":
		alpha += 0.17
	_draw_ellipse(Vector2(0.0, -132.0), Vector2(76.0, 145.0), Color(theme_color.r, theme_color.g, theme_color.b, alpha))
	if _state == "ultimate":
		for i in 12:
			var a: float = TAU * float(i) / 12.0 + _clock * 0.18
			var start := Vector2(cos(a) * 86.0, -132.0 + sin(a) * 146.0)
			var finish := Vector2(cos(a) * 112.0, -132.0 + sin(a) * 184.0)
			draw_line(start, finish, theme_color.lightened(0.6), 4.0, true)


func _draw_action_fx(pulse: float) -> void:
	var fx := theme_color.lightened(0.34)
	if _state in ["attack_1", "attack1"]:
		draw_arc(Vector2(100.0, -165.0), 28.0, -PI * 0.7, PI * 0.6, 14, fx, 7.0, true)
	elif _state in ["attack_2", "attack2", "jump_attack"]:
		draw_arc(Vector2(85.0, -135.0), 69.0, -PI * 0.9, PI * 0.55, 25, fx, 9.0, true)
	elif _state in ["attack_3", "attack3"]:
		for i in 3:
			draw_arc(Vector2(110.0 + 12.0 * i, -158.0 + 31.0 * i), 36.0, -PI * 0.7, PI * 0.5, 16, fx, 4.0, true)
	elif _state == "skill":
		draw_arc(Vector2(105.0, -168.0), 32.0 + 14.0 * pulse, 0.0, TAU, 25, fx, 5.0, true)
		draw_line(Vector2(119.0, -168.0), Vector2(204.0, -168.0), fx, 7.0, true)
	elif _state == "ultimate":
		draw_arc(Vector2(64.0, -151.0), 75.0 + 11.0 * pulse, 0.0, TAU, 40, fx, 7.0, true)
		draw_arc(Vector2(64.0, -151.0), 101.0, 0.0, TAU, 40, Color(fx.r, fx.g, fx.b, 0.55), 3.0, true)


func _hair_color() -> Color:
	match display_name:
		"Mai Anh": return Color("#e9474f")
		"Huyền Chi": return Color("#170e22")
		"Hồng Nhi": return Color("#ffb1d6")
		"Bảo Châu": return Color("#84dedf")
		"Tử Anh": return Color("#8960cb")
		"Ánh Dương": return Color("#d7ae64")
		_: return Color("#574258")


func _draw_crescent(center: Vector2, radius: float, color: Color) -> void:
	draw_arc(center, radius, -PI * 0.60, PI * 0.70, 16, color, 5.0, true)


func _draw_flame(center: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-9.0, 8.0), center + Vector2(-6.0, -5.0),
		center + Vector2(0.0, -20.0), center + Vector2(4.0, -4.0),
		center + Vector2(12.0, -12.0), center + Vector2(10.0, 9.0)
	]), color)


func _draw_butterfly(center: Vector2, color: Color) -> void:
	draw_circle(center + Vector2(-7.0, -5.0), 8.0, color)
	draw_circle(center + Vector2(7.0, -5.0), 8.0, color)
	draw_circle(center + Vector2(-5.0, 6.0), 5.0, color)
	draw_circle(center + Vector2(5.0, 6.0), 5.0, color)
	draw_line(center + Vector2(0.0, -10.0), center + Vector2(0.0, 10.0), Color("#241128"), 3.0, true)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 25:
		var angle: float = TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
