extends Node2D

const ROCKET_SPRITE := preload("res://environment/rocket-flight.png")
const MISSILE_SPRITE := preload("res://environment/missile-flight.png")

@export var speed := 270.0
@export var acceleration := 350.0
@export var damage := 800
@export var radius := 90.0
var sector: Node2D
var direction := Vector2.UP
var drift := Vector2.ZERO
var guided := false
var hostile := false
var pdc_hits := 0
var npc: Dictionary = {}
var rock: Dictionary = {}
var age := 0.0
var blast := -1.0

func _physics_process(dt: float) -> void:
	if sector.map_open or sector.market == 3 or sector.console_open or sector.ftl_depart_age >= 0 or sector.ftl_arrival_age < 1: return
	queue_redraw()
	if blast >= 0:
		blast += dt
		if blast >= .32: queue_free()
		return
	age += dt
	var flight_speed := speed + acceleration * age
	if guided and age >= .24:
		var aim := Vector2.ZERO
		if not npc.is_empty() and npc.hp > 0 and sector.npcs.has(npc):
			aim = npc.p-position
		elif not rock.is_empty() and rock.hp > 0:
			aim = rock.p-position
		if aim.length_squared() > .001:
			var limit := maxf(5.0,2.0*flight_speed/aim.length())*dt
			direction = direction.rotated(clampf(direction.angle_to(aim),-limit,limit))
	rotation = direction.angle()+PI/2
	# Once the turn begins, guidance controls the velocity vector.
	var endpoint := position + (direction * flight_speed + (Vector2.ZERO if guided and age >= .24 else drift)) * dt
	var hit: Vector2 = sector.ray_rock(position, endpoint)
	if hostile:
		var player_hit := Geometry2D.segment_intersects_circle(position,endpoint,sector.pos,float(sector.stat(3))*.32)
		if player_hit >= 0 and player_hit <= hit.y:
			position = position.lerp(endpoint,player_hit)
			sector.player_pdc_attacker = npc
			sector.player_pdc_until = sector.traffic_time+8
			sector.player_damage(30)
			if sector.hp == 0: sector.destroyed()
			blast = 0
			return
		if hit.x >= 0:
			position = position.lerp(endpoint,hit.y)
			blast = 0
			return
		if age >= 2.8: queue_free()
		else: position = endpoint
		return
	var contact: Vector2 = sector.ray_npc(position,endpoint,hit.y)
	if hit.x >= 0 or contact.x >= 0:
		position = position.lerp(endpoint,contact.y)
		var direct_rock := -1 if contact.x >= 0 else int(hit.x)
		sector.missile_impact(position,direct_rock,damage,radius,int(contact.x))
		blast = 0
	elif not guided and age >= 2.8:
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
	var sprite := MISSILE_SPRITE if guided else ROCKET_SPRITE
	var size := Vector2(20.0*sprite.get_width()/sprite.get_height(),20.0)
	var nozzle := size.y*.5
	var flame := 10.0+sin(age*70)*3.0
	draw_colored_polygon(PackedVector2Array([Vector2(-3,nozzle-1),Vector2(3,nozzle-1),Vector2(0,nozzle+flame)]),
		Color.DODGER_BLUE if guided else Color.ORANGE_RED)
	draw_colored_polygon(PackedVector2Array([Vector2(-1.5,nozzle),Vector2(1.5,nozzle),Vector2(0,nozzle+flame*.6)]),
		Color.ALICE_BLUE if guided else Color.GOLD)
	draw_texture_rect(sprite,Rect2(-size*.5,size),false)
