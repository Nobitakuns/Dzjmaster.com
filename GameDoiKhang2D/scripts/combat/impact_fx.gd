class_name ImpactFX
extends Node2D

var accent: Color = Color.WHITE
var style: String = ""
var age: float = 0.0
var duration: float = 0.33

func _process(delta: float) -> void:
	age += delta
	if age >= duration:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var p := age / duration
	var c := accent
	c.a = (1.0 - p) * 0.94
	var hot := Color("#ff3556")
	hot.a = (1.0 - p) * 0.78
	var radius := 22.0 + p * 76.0
	draw_circle(Vector2.ZERO, 34.0 * (1.0 - p), Color(1.0, 0.94, 0.86, 0.58 * (1.0 - p)))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, c, 8.0 * (1.0 - p), true)
	draw_arc(Vector2.ZERO, radius * 0.67, 0, TAU, 32, hot, 4.0 * (1.0 - p), true)
	var rays := 14 if style in ["solar", "thunder"] else 12
	for i in rays:
		var angle := float(i) * TAU / float(rays) + p * 0.17
		var v := Vector2(cos(angle), sin(angle))
		var length := radius * (1.5 if i % 3 == 0 else 1.12)
		draw_line(v * radius * 0.22, v * length, c if i % 2 == 0 else hot, (6.0 if i % 3 == 0 else 3.5) * (1.0 - p), true)
		draw_circle(v * length, 3.0 * (1.0 - p), c)
	draw_circle(Vector2.ZERO, 12.0 * (1.0 - p), Color(1.0, 0.98, 0.93, 0.92 * (1.0 - p)))
	if style in ["sakura", "butterfly", "shadow"]:
		for i in 4:
			var a := float(i) * TAU / 4.0 + p * 2.0
			draw_circle(Vector2(cos(a), sin(a)) * radius, 7.0 * (1.0 - p), c)
