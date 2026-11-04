extends Node2D

@export var speed := 270.0
@export var acceleration := 350.0
@export var damage := 800
@export var radius := 90.0
var sector: Node2D
var direction := Vector2.UP
var drift := Vector2.ZERO
var age := 0.0
var blast := -1.0

func _physics_process(dt: float) -> void:
	if sector.map_open: return
	queue_redraw()
	if blast >= 0:
		blast += dt
		if blast >= .32: queue_free()
		return
	age += dt
	var endpoint := position + (drift + direction * (speed + acceleration * age)) * dt
	var hit: Vector2 = sector.ray_rock(position, endpoint)
	var contact: Vector2 = sector.ray_npc(position,endpoint,hit.y)
	var debris: Vector2 = sector.ray_wreck(position,endpoint,contact.y)
	if hit.x >= 0 or contact.x >= 0 or debris.x >= 0:
		position = position.lerp(endpoint,debris.y)
		var direct_rock := -1 if contact.x >= 0 or debris.x >= 0 else int(hit.x)
		var direct_npc := -1 if debris.x >= 0 else int(contact.x)
		sector.missile_impact(position,direct_rock,damage,radius,direct_npc,int(debris.x))
		blast = 0
	elif age >= 2.8:
		queue_free()
	else:
		position = endpoint

func _draw() -> void:
	if blast >= 0:
		var progress := clampf(blast / .32, 0, 1)
		var size := maxf(3, radius * progress)
		draw_circle(Vector2.ZERO, size, Color(1,.35,.05,.28*(1-progress)))
		draw_arc(Vector2.ZERO, size, 0, TAU, 32, Color(1,.65,.2,1-progress), 3)
		return
	draw_line(Vector2(0,6),Vector2(0,20+sin(age*70)*4),Color.ORANGE_RED,4)
	draw_line(Vector2(0,6),Vector2(0,15),Color.GOLD,2)
	draw_colored_polygon(PackedVector2Array([Vector2(0,-10),Vector2(3,-3),Vector2(3,8),Vector2(-3,8),Vector2(-3,-3)]),Color.GAINSBORO)
	draw_line(Vector2(-3,0),Vector2(3,0),Color.ORANGE_RED,2)

