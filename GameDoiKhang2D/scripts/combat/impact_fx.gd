class_name ImpactFX
extends Node2D

var accent: Color = Color.WHITE
var style: String = ""
var age: float = 0.0
var duration: float = 0.26

func _process(delta: float) -> void:
	age += delta
	if age >= duration:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var p := age / duration
	var c := accent
	c.a = (1.0 - p) * 0.9
	var radius := 14.0 + p * 65.0
	draw_arc(Vector2.ZERO, radius, 0, TAU, 24, c, 8.0 * (1.0 - p), true)
	var rays := 8 if style in ["solar", "thunder"] else 6
	for i in rays:
		var angle := float(i) * TAU / float(rays) + p * 0.6
		var v := Vector2(cos(angle), sin(angle))
		draw_line(v * radius * 0.25, v * radius * 1.45, c, 6.0 * (1.0 - p), true)
	if style in ["sakura", "butterfly", "shadow"]:
		for i in 4:
			var a := float(i) * TAU / 4.0 + p * 2.0
			draw_circle(Vector2(cos(a), sin(a)) * radius, 7.0 * (1.0 - p), c)
