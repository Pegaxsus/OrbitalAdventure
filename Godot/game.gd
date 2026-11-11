extends Node2D

const MISSILE := preload("res://missile.tscn")
const HALF := 5000.0
const ROCK_HP := 2400
const STAR_FIELD := preload("res://environment/stars.png")
const MODES := ["Ametralladora", "Cohete", "Minería", "Sin armamento", "Salvaging", "Misil"]
const RES := ["Hielo de agua", "Metano", "Hierro", "Aluminio", "Titanio", "Cobre", "Silicio", "Carbono", "Níquel", "Tierras raras"]
const PAINT := [Color.WHITE, Color(1.5,.65,.55), Color(.65,1.4,.65), Color(1.25,.72,1.4)]
const LEGACY_SAVE := "user://sector.json"

func save_path() -> String:
	var base := OS.get_executable_path().get_base_dir()
	if OS.has_feature("editor"):
		base = ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	return base.path_join("savegames/godot/latest.json")
var ships: Array[Texture2D] = []
var asteroid_sprites: Array[Texture2D] = []
var specs: Array[PackedStringArray] = []
var rocks: Array = []
var bullets: Array = []
var fragments: Array = []
var cargo: Array = []
var inventory: Array = []
var selected := 0
var paint := 0
var mode := 0
var motor := false
var coupled := true
var hangar := true
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var angle := 0.0
var zoom := 1.0
var hp := 90
var status := ""
var ping := 1000.0
var ping_origin := Vector2.ZERO
var cooldown := 0.0
var missile_cooldown := 0.0
var missile_layer := Node2D.new()
var power := 35
var mining_time := 0.0
var target := -1
var selected_target := -1
var help_open := false
var inventory_open := false
var station_discovered := false
var nacar_discovered := false

var npcs: Array[Dictionary] = []
var traffic_time := 0.0
var next_trader := 8.0
var trader: Dictionary = {}
var neutral_attack := -100.0
var attack_position := Vector2.ZERO
var npc_target: Dictionary = {}

var wreck_fields: Array = [[],[],[],[],[]]
var explosions: Array[Dictionary] = []
var wreck_sprites: Array[Texture2D] = []
var salvage_target := -1
var salvage_rays: Array = []
var mining_rays: Array = []
var mining_hits := 0
const SALVAGE_MATERIALS := [5,2,4,3]

func wreck_radius(item: Dictionary) -> float:
	return 8.0+(int(item.sprite)%3)*4

func ray_wreck(start: Vector2, end: Vector2, limit: float) -> Vector2:
	var result := Vector2(-1,limit)
	var items: Array = wreck_fields[sector]
	for i in range(items.size()):
		var item: Dictionary = items[i]
		var radius := wreck_radius(item)
		var hit := Geometry2D.segment_intersects_circle(start,end,item.p,radius)
		if start.distance_squared_to(item.p) <= radius*radius: hit = 0
		if hit >= 0 and hit <= result.y: result = Vector2(i,hit)
	return result

func damage_wreck(index: int) -> void:
	var item: Dictionary = wreck_fields[sector][index]
	item.hits = int(item.get("hits",0))+1
	if item.hits >= 3+int(item.sprite)%2: destroy_wreck(index)

func destroy_wreck(index: int) -> void:
	wreck_fields[sector].remove_at(index)
	salvage_target = -1

func wreck_ship(at: Vector2, ship: int, player: bool = false, rotation_angle: float = 0.0) -> void:
	var count := clampi(2+int(specs[ship][3])/30,2,7)
	explosions.append({"p":at,"age":0.0,"ship":ship,"angle":rotation_angle,"player":player})
	for i in range(count):
		var offset := Vector2.RIGHT.rotated(i*TAU/count)*randf_range(15,36+count*3)
		wreck_fields[sector].append({"p":at+offset,"sprite":randi()%maxi(1,wreck_sprites.size()),"angle":randf_range(0,TAU),"progress":0.0})

func update_wrecks(dt: float) -> void:
	for i in range(explosions.size()-1,-1,-1):
		explosions[i].age += dt
		if explosions[i].age >= 1.08:
			var player: bool = explosions[i].player
			explosions.remove_at(i)
			if player:
				player_destroying = false
				rescue_dock()
				status = "Nave destruida. Repuesta en el hangar."
	salvage_target = -1
	salvage_rays.clear()
	if hangar or player_destroying or mode != 4 or not has_module_for_mode() or not Input.is_key_pressed(KEY_SPACE): return
	var f := forward()
	var nose := pos+f*stat(3)/2.0
	var end := nose+f*stat(3)*.55
	var count := module_count(3)
	var hits := 0
	for i in range(count):
		var start := pos+ship_mount(selected,"salvaging",i,count).rotated(angle)
		var rock := ray_rock(start,end)
		var hit := ray_wreck(start,end,rock.y)
		salvage_rays.append([start,start.lerp(end,hit.y)])
		if hit.x >= 0:
			if salvage_target < 0: salvage_target = int(hit.x)
			if int(hit.x) == salvage_target: hits += 1
	if salvage_target < 0: return
	var item: Dictionary = wreck_fields[sector][salvage_target]
	var grade := int(item.sprite)%3
	var amount := 3+2*grade
	if used()+amount > stat(4):
		status = "Se necesitan %d U libres en la bodega" % amount
		return
	item.progress += dt*hits/(1.0+grade*.75)
	if item.progress >= 1:
		var resource: int = SALVAGE_MATERIALS[int(item.sprite)%SALVAGE_MATERIALS.size()]
		cargo[resource] += amount
		destroy_wreck(salvage_target)
		status = "Recuperadas %d U de %s" % [amount,RES[resource]]


const SHIP_BLAST := preload("res://environment/ship-explosion.png")
const BLAST_COLUMNS := [20,245,505,786,1100,1430,1730,2048]
var player_destroying := false

func draw_blast(at: Vector2, elapsed: float, duration: float, scale: float) -> void:
	if elapsed < 0 or elapsed >= duration: return
	var frame := mini(6,int(elapsed/duration*7))
	var sheet_size := SHIP_BLAST.get_size()
	var left: float = BLAST_COLUMNS[frame]
	var right: float = BLAST_COLUMNS[frame+1]
	var source := Rect2(left/2048*sheet_size.x,155.0/685*sheet_size.y,
		(right-left)/2048*sheet_size.x,330.0/685*sheet_size.y)
	var size := Vector2(right-left,330)*scale/330
	var alpha := clampf((duration-elapsed)/(duration*.19),0,1)
	draw_texture_rect_region(SHIP_BLAST,Rect2(at-size/2,size),source,Color(1,1,1,alpha))

func draw_explosions(center: Vector2) -> void:
	for blast in explosions:
		var at: Vector2 = blast.p
		var ship: int = blast.ship
		var length := float(specs[ship][3])
		var angle_at_death: float = blast.angle
		var elapsed: float = blast.age
		var axis := Vector2.UP.rotated(angle_at_death)
		if elapsed < .70:
			draw_set_transform(center+(at-pos)*zoom,angle_at_death,Vector2.ONE*zoom)
			sprite(ship,Vector2.ZERO,length,PAINT[paint] if blast.player else Color.WHITE)
			draw_set_transform(center-pos*zoom,0,Vector2.ONE*zoom)
		draw_blast(at+axis*length*.22,elapsed,.42,length*.57)
		draw_blast(at-axis*length*.24,elapsed-.20,.42,length*.62)
		draw_blast(at,elapsed-.58,.50,length*1.75)

var next_pdc_id := 0

func make_npc(role: String, ship: int, at: Vector2) -> Dictionary:
	var npc := {"role":role,"ship":ship,"p":at,"v":Vector2.ZERO,"angle":0.0,
		"module":2 if role == "Minero" else (-1 if role in ["Trader","Mercante"] else 0),"hp":int(specs[ship][2]),"cooldown":0.0,"trace":0.0,"end":at,"cargo":0,"work":0.0,"rock":-1}
	npc.pdc_id = next_pdc_id
	next_pdc_id += 1
	npc.ftl = role in ["Trader","Mercante"]
	npc.entry_age = 1.0
	npc.shield = randf() < .20
	npc.shield_state = {"value":float(specs[ship][2])*.5 if npc.shield else 0.0,"delay":0.0,"flash":0.0,"break_flash":0.0,"lock":0.0}
	npc.pdc = false
	npc.missile_loot = role == "Pirata" and randf() < .35
	npcs.append(npc)
	return npc

func reset_traffic() -> void:
	auto_station = -1
	auto_ready = 0.0
	ftl_exits.clear()
	pdc_states.clear()
	npcs.clear()
	freight_ship = {}
	trader = {}
	npc_target = {}
	traffic_time = 0
	station_raid_until = 0
	next_trader = 8
	neutral_attack = -100
	make_npc("Minero",2,Vector2(230,-140))
	make_npc("Patrulla",4,Vector2(-290,220))
	next_raid = randf_range(45,120)
	extra_target = {}

var next_raid := 90.0

func raid_opportunity() -> void:
	next_raid = traffic_time+randf_range(60,150)
	for npc in npcs:
		if npc.role == "Pirata" and npc.hp > 0: return
	if randf() >= .55: return
	spawn_raid()

func spawn_raid() -> void:
	var mission: String = ["Sector","Minero","Trader","Jugador"].pick_random()
	var entrance := Vector2.from_angle(randf()*TAU)*4600
	for i in range(randi_range(1,2)):
		var pirate := make_npc("Pirata",3,entrance+Vector2(i*90,0))
		pirate.raid = mission
		pirate.expires = traffic_time+180

func npc_hit(npc: Dictionary, amount: int, by_player: bool, attacker: Dictionary = {}) -> void:
	if npc.hp <= 0 or amount <= 0: return
	npc.hp = maxi(0,npc.hp-shield_damage(npc.shield_state,float(specs[npc.ship][2])*.5 if npc.shield else 0.0,amount))
	npc.pdc_attacker = attacker
	npc.pdc_player = by_player
	npc.pdc_until = traffic_time+8
	if npc.role == "Pirata":
		npc.attacker = attacker
		npc.attacked_by_player = by_player
		if npc.hp < int(specs[npc.ship][2])*.40 and not npc.has("flees"):
			npc.flees = randf() < .5
	if npc.role == "Mercante" and not freight.is_empty():
		freight.hp = npc.hp
		if npc.hp == 0:
			freight.clear()
			freight_ship = {}
	if npc.hp == 0:
		wreck_ship(npc.p,npc.ship,false,npc.angle)
		if npc.ftl and randf() < .10: module_drops[sector].append([npc.p.x,npc.p.y,10])
		if npc.shield and randf() < .20: module_drops[sector].append([npc.p.x,npc.p.y,9])
		for kind in [6,7,8]:
			if (kind != 8 or npc.get("pdc",false)) and randf() < .20: module_drops[sector].append([npc.p.x,npc.p.y,kind])
		if npc.get("missile_loot",false) and randf() < .5:
			module_drops[sector].append([npc.p.x,npc.p.y,5])
		if npc.module >= 0 and randf() < .5:
			module_drops[sector].append([npc.p.x,npc.p.y,npc.module])
	if by_player:
		attack_position = npc.p
		if npc.role in ["Trader","Mercante","Minero","Escolta"]:
			var patrol := npcs[1]
			if patrol.hp > 0 and patrol.p.distance_to(npc.p) < 720 and ray_rock(patrol.p,npc.p).x < 0:
				neutral_attack = traffic_time

func fire_npc(npc: Dictionary, at: Vector2, victim: Dictionary) -> void:
	if npc.module != 0: return
	if npc.cooldown > 0 or npc.p.distance_to(at) > 310: return
	var origin := npc_mount(npc,"ametralladora")
	var block := ray_rock(origin,at)
	if block.x >= 0: return
	npc.cooldown = .48
	npc.trace = .10
	npc.end = at
	var debris := ray_wreck(origin,at,1)
	if debris.x >= 0:
		npc.end = origin.lerp(at,debris.y)
		damage_wreck(int(debris.x))
		return
	if victim.is_empty() and npc.role == "Pirata" and npc.get("missile_loot",false) and randf() < .35:
		var rocket := MISSILE.instantiate()
		rocket.sector = self
		rocket.hostile = true
		rocket.npc = npc
		rocket.position = origin
		rocket.direction = (at-origin).normalized()
		rocket.rotation = rocket.direction.angle()+PI/2
		missile_layer.add_child(rocket)
		npc.trace = 0.0
		npc.cooldown = 1.2
		return
	if victim.is_empty():
		player_pdc_attacker = npc
		player_pdc_until = traffic_time+8
		player_damage(9)
		if hp <= 0: destroyed()
	else:
		npc_hit(victim,12,false,npc)

func steer_npc(npc: Dictionary, goal: Vector2, speed: float, dt: float, mining_rock: int) -> void:
	var offset: Vector2 = goal-npc.p
	var desired := offset.limit_length(speed)
	var ahead: Vector2 = npc.p + desired.normalized()*100
	var obstacle := ray_rock(npc.p,ahead)
	if obstacle.x >= 0 and int(obstacle.x) != mining_rock:
		var rock: Dictionary = rocks[int(obstacle.x)]
		var side: Vector2 = (npc.p-rock.p).normalized()
		desired = (desired.normalized().orthogonal()+side*.7).normalized()*speed
	var old_velocity: Vector2 = npc.v
	npc.v = npc.v.move_toward(desired,80*dt)
	npc.active_thrust = (npc.v-old_velocity).length()/maxf(dt,.00001)
	npc.p += npc.v*dt
	var facing: Vector2 = npc.end-npc.p if npc.trace > 0 else offset
	if facing.length_squared() > 4:
		npc.angle = rotate_toward(npc.angle,facing.angle()+PI/2,1.7*dt)

func update_traffic(dt: float) -> void:
	traffic_time += dt
	if traffic_time >= next_raid: raid_opportunity()
	if traffic_time >= next_trader:
		if not trader.is_empty():
			for i in range(npcs.size()-1,-1,-1):
				if npcs[i].role in ["Trader","Escolta"]:
					if npcs[i].hp > 0: ftl_exits.append({"p":npcs[i].p,"angle":npcs[i].angle,"ship":npcs[i].ship,"age":0.0})
					npcs.remove_at(i)
			trader = {}
			next_trader = traffic_time + randf_range(20,42)
		else:
			var ship: int = [2,5,9].pick_random()
			trader_stock.fill(5)
			trader = make_npc("Trader",ship,(pos+Vector2(-420,180)).clamp(Vector2(-4500,-4500),Vector2(4500,4500)))
			ftl_npc_arrival(trader)
			if ship == 9:
				ftl_npc_arrival(make_npc("Escolta",2,trader.p+Vector2(-95,-85)))
				ftl_npc_arrival(make_npc("Escolta",2,trader.p+Vector2(-95,85)))
			next_trader = traffic_time + randf_range(320,400)
	var miner: Dictionary = npcs[0]
	for npc in npcs:
		if hangar or player_destroying or npc.hp <= 0: continue
		npc.cooldown -= dt
		npc.trace -= dt
		var goal: Vector2 = npc.p
		var speed := 105.0
		var rock_index := -1
		var pirate := nearest_pirate(npc.p)
		var station_index := nearest_station(sector,npc.p)
		var station: Dictionary = stations[station_index] if station_index >= 0 else {}
		match npc.role:
			"Mercante":
				continue
			"Trader":
				goal = Vector2.from_angle(traffic_time*.03)*700
				speed = 80
			"Escolta":
				goal = trader.p + Vector2(-95,-85 if npc.p.y < trader.p.y else 85)
				if not pirate.is_empty() and pirate.p.distance_to(trader.p) < 350:
					fire_npc(npc,pirate.p,pirate)
			"Minero":
				if npc.module != 2: continue
				speed = 48.0
				if not station.is_empty() and npc.cargo > 0:
					goal = port_center(station,CAPITAL_PORT if station.layout == "shipyard" else 0)
					for port in range(1,station.ports):
						var candidate := port_center(station,port)
						if npc.p.distance_squared_to(candidate) < npc.p.distance_squared_to(goal): goal = candidate
					if npc.p.distance_to(goal) < 20 and npc.v.length() < 32:
						if station_index == 0: station_reserve += int(npc.cargo)
						elif station_index == 1: nacar_reserve += int(npc.cargo)
						else: station.reserve += int(npc.cargo)
						station_minerals(station_index)[int(npc.get("ore_resource",2))] += int(npc.cargo)
						npc.cargo = 0
						npc.rock = -1
						npc.think = 8.0
				elif npc.cargo >= 20:
					goal = Vector2(0,-1250)
					if npc.p.distance_to(goal) < 65: npc.hp = 0
				elif npc.has("ore"):
					goal = npc.ore
					if npc.p.distance_to(goal) < 24:
						npc.cargo += int(npc.ore_amount)
						npc.erase("ore")
				else:
					rock_index = npc.rock
					if rock_index < 0 or rocks[rock_index].hp <= 0 or rock_index == target:
						npc.work = 0
						rock_index = -1
						npc.think = float(npc.get("think",8.0))-dt
						if npc.think > 0:
							steer_npc(npc,npc.p,0,dt,-1)
							continue
						npc.think = 8.0
						var nearest := INF
						for i in range(rocks.size()):
							if i == target or rocks[i].hp <= 0: continue
							var distance: float = npc.p.distance_squared_to(rocks[i].p)
							if distance < nearest:
								nearest = distance
								rock_index = i
						npc.rock = rock_index
					if rock_index >= 0:
						var rock: Dictionary = rocks[rock_index]
						var offset: Vector2 = rock.p-npc.p
						var gap: float = rock.r+35
						goal = rock.p-offset.normalized()*gap
						if absf(offset.length()-gap) < 12 and npc.v.length() < 26:
							npc.work += dt
							npc.trace = .10
							npc.end = rock.p-offset.normalized()*rock.r
							if npc.work >= 18:
								npc.ore = rock.p
								npc.ore_resource = rock.first
								npc.ore_amount = mini(20-npc.cargo,4+asteroid_size(rock.r)*4)
								rock.mined = true
								rock.hp = 0
								npc.work = 0
			"Pirata":
				var mission: String = npc.get("raid","Sector")
				var victim: Dictionary = miner if mission == "Minero" and miner.hp > 0 else (trader if mission == "Trader" and not trader.is_empty() and trader.hp > 0 else {})
				var at: Vector2 = pos if victim.is_empty() else victim.p
				if traffic_time >= npc.get("expires",INF): npc.flees = true
				if npc.get("flees",false):
					goal = Vector2(4400,-4300) if npc.p.x >= 0 else Vector2(-4400,-4300)
					speed = 145
					if npc.p.distance_to(goal) < 65: npc.hp = 0
				elif npc.get("attacked_by_player",false):
					goal = pos+(npc.p-pos).normalized()*175
					fire_npc(npc,pos,{})
				elif not npc.get("attacker",{}).is_empty() and npc.attacker.hp > 0:
					var aggressor: Vector2 = npc.attacker.p
					goal = aggressor+(npc.p-aggressor).normalized()*175
					fire_npc(npc,aggressor,npc.attacker)
				else:
					goal = Vector2(3000,2500)
					if mission == "Jugador" or not victim.is_empty():
						goal = at+(npc.p-at).normalized()*175
						fire_npc(npc,at,victim)
					elif mission == "Sector" and not station.is_empty():
						var base: Vector2 = station.p
						goal = base+(npc.p-base).normalized()*235
						attack_station(npc,station)
			"Patrulla":
				goal = Vector2(-280,200)+Vector2.from_angle(traffic_time*.13)*340
				if not station.is_empty():
					goal = station.p+Vector2.from_angle(traffic_time*.13)*280
				if not station.is_empty() and not pirate.is_empty() and (traffic_time < station_raid_until or pirate.p.distance_to(station.p) < 465):
					goal = pirate.p+(npc.p-pirate.p).normalized()*155
					fire_npc(npc,pirate.p,pirate)
				elif traffic_time-neutral_attack < 22 and npc.p.distance_to(attack_position) < 720:
					goal = pos+(npc.p-pos).normalized()*165
					fire_npc(npc,pos,{})
				elif not pirate.is_empty() and npc.p.distance_to(pirate.p) < 620 and ray_rock(npc.p,pirate.p).x < 0:
					goal = pirate.p+(npc.p-pirate.p).normalized()*155
					fire_npc(npc,pirate.p,pirate)
				elif bullets.size() > 0 and npc.p.distance_to(pos) < 650:
					goal = pos+(npc.p-pos).normalized()*200
		steer_npc(npc,goal,speed,dt,rock_index)

var freight: Dictionary = {}
var freight_ship: Dictionary = {}
var freight_clock := 0.0

func route_edge(from_sector: int, destination: int) -> int:
	var queue: Array[Vector2i] = [Vector2i(from_sector,-1)]
	var seen := 1 << from_sector
	while not queue.is_empty():
		var entry: Vector2i = queue.pop_front()
		for i in range(links.size()):
			var link: Vector2i = links[i]
			if entry.x != link.x and entry.x != link.y: continue
			var next := link.y if entry.x == link.x else link.x
			if (seen & (1 << next)) != 0: continue
			var first := i if entry.y < 0 else entry.y
			if next == destination: return first
			seen |= 1 << next
			queue.append(Vector2i(next,first))
	return -1

func update_freight(dt: float) -> void:
	if freight.is_empty():
		freight_clock += dt
		if freight_clock < 30: return
		freight_clock = 0
		var origin := randi_range(0,1)
		var destination := 1-origin
		var kind := -1
		var best := 0
		var stock := station_minerals(origin)
		for i in range(RES.size()):
			var margin := station_price(destination,i)/2-station_price(origin,i)
			if stock[i] > 0 and margin > best:
				kind = i
				best = margin
		if kind < 0: return
		var amount := mini(stock[kind],8)
		stock[kind] -= amount
		var start := port_center(stations[origin],0)
		freight = {"sector":origin,"destination":destination,"kind":kind,"amount":amount,"x":start.x,"y":start.y,"hp":int(specs[5][2]),"ftl_wait":300.0}
	var local := int(freight.sector)
	var destination := int(freight.destination)
	var edge := route_edge(local,destination) if local != destination else -1
	var goal := gate_position(edge,local) if edge >= 0 else port_center(stations[destination],0)
	var at := Vector2(freight.x,freight.y)
	if local == sector and freight_ship.is_empty():
		freight_ship = make_npc("Mercante",5,at)
		freight_ship.hp = int(freight.hp)
		ftl_npc_arrival(freight_ship)
	if not freight_ship.is_empty():
		freight.hp = freight_ship.hp
		var direction := goal-at
		if direction.length_squared() > 1: freight_ship.angle = direction.angle()+PI/2
	var previous_position := at
	at = at.move_toward(goal,95*dt)
	freight.x = at.x
	freight.y = at.y
	if not freight_ship.is_empty():
		var previous_velocity: Vector2 = freight_ship.v
		freight_ship.v = (at-previous_position)/maxf(dt,.00001)
		freight_ship.active_thrust = (freight_ship.v-previous_velocity).length()/maxf(dt,.00001)
		freight_ship.p = at
	if at != goal: return
	if float(freight.get("ftl_wait",0)) > 0: return
	if not freight_ship.is_empty():
		ftl_exits.append({"p":freight_ship.p,"angle":freight_ship.angle,"ship":freight_ship.ship,"age":0.0})
		npcs.erase(freight_ship)
		freight_ship = {}
	if edge < 0:
		station_minerals(destination)[int(freight.kind)] += int(freight.amount)
		freight.clear()
	else:
		var link: Vector2i = links[edge]
		local = link.y if link.x == local else link.x
		var entry := gate_position(edge,local)
		freight.sector = local
		freight.ftl_wait = 300.0
		freight.x = entry.x
		freight.y = entry.y

func nearest_pirate(at: Vector2) -> Dictionary:
	var result: Dictionary = {}
	var nearest := INF
	for npc in npcs:
		if npc.role != "Pirata" or npc.hp <= 0: continue
		var distance := at.distance_squared_to(npc.p)
		if distance < nearest:
			nearest = distance
			result = npc
	return result

func attack_station(npc: Dictionary, station: Dictionary) -> void:
	if npc.module != 0: return
	var base: Vector2 = station.p
	if npc.cooldown > 0 or npc.p.distance_to(base) > 310 or ray_rock(npc_mount(npc,"ametralladora"),base).x >= 0: return
	npc.cooldown = .48
	npc.trace = .10
	npc.end = base
	station.pdc_attacker = npc
	station.pdc_until = traffic_time+8
	station.hp = maxi(1,station.hp-90)
	station.repair_delay = 5.0
	station.repair_fraction = 0.0
	station_raid_until = traffic_time+10

func ray_npc(start: Vector2, endpoint: Vector2, limit: float) -> Vector2:
	var result := Vector2(-1,limit)
	for i in range(npcs.size()):
		var npc: Dictionary = npcs[i]
		if npc.hp <= 0: continue
		var radius := int(specs[npc.ship][3])*.32
		var hit := Geometry2D.segment_intersects_circle(start,endpoint,npc.p,radius)
		if start.distance_squared_to(npc.p) < radius*radius: hit = 0
		if hit >= 0 and hit <= result.y: result = Vector2(i,hit)
	return result


var stations: Array[Dictionary] = []
var dock_station := 0
var dock_port := 0
var station_reserve := 0
var station_raid_until := 0.0
var reset_traffic_on_launch := false
var soft_sky: Texture2D
const PORT_LENGTH := 164.0
const PORT_WIDTH := 58.0
const CAPITAL_PORT := 8
const CAPITAL_LENGTH := 258.0
const CAPITAL_WIDTH := 196.0

func uses_capital_port() -> bool:
	return int(specs[selected][11]) >= 4

func port_dimensions(port: int, station: Dictionary = {}) -> Vector2:
	if station.get("dock_mounts",{}).has(port): return station.dock_mounts[port].size
	return Vector2(CAPITAL_LENGTH,CAPITAL_WIDTH) if port >= CAPITAL_PORT else Vector2(PORT_LENGTH,PORT_WIDTH)

func docking_ports(station: Dictionary) -> Array:
	if station.layout == "shipyard": return [CAPITAL_PORT]
	return range(CAPITAL_PORT,CAPITAL_PORT+station.capital_ports) if uses_capital_port() else range(int(station.ports))

func load_stations() -> void:
	var sky := STAR_FIELD.get_image()
	sky.resize(150,100,Image.INTERPOLATE_LANCZOS)
	sky.resize(900,600,Image.INTERPOLATE_BILINEAR)
	soft_sky = ImageTexture.create_from_image(sky)
	for line in FileAccess.get_file_as_string("res://station-attributes.txt").strip_edges().split("\n"):
		var data := line.strip_edges().split(",")
		var art: Texture2D = load("res://environment/"+data[0])
		var soft := art.get_image()
		soft.resize(36,36,Image.INTERPOLATE_LANCZOS)
		soft.resize(256,256,Image.INTERPOLATE_BILINEAR)
		var station := {"name":data[1],"sector":int(data[2]),"p":Vector2(float(data[3]),float(data[4])),
			"size":float(data[5]),"mass":int(data[6]),"hp":int(data[7]),"max_hp":int(data[7]),"repair_delay":0.0,"repair_fraction":0.0,"ports":int(data[8]),"art":art,"soft":ImageTexture.create_from_image(soft),"layout":data[9] if data.size()>9 else "cross","pivot":Vector2(float(data[10]),float(data[11])) if data.size()>11 else Vector2(.5,.5),"mask":art.get_image(),"capital_ports":3 if data.size()>9 and data[9]=="tri" else (2 if data.size()>9 and data[9]=="bi" else 1),"discovered":false,"reserve":0,"stock":[20,20,20,20,20,20,20,20,20,20],"modules":new_station_modules(),"dock_mounts":{},"defense_mounts":{}}
		if station.layout == "custom":
			load_station_mounts(station,"res://"+data[0].get_basename()+".hardpoints.txt")
		stations.append(station)

func new_station_modules() -> Array:
	var stock := []
	stock.resize(MODULE_NAMES.size())
	stock.fill(2)
	return stock

func load_station_mounts(station: Dictionary, path: String) -> void:
	var lines := FileAccess.get_file_as_string(path).strip_edges().split("\n")
	station.ports = 0
	station.capital_ports = 0
	for i in range(1,lines.size()):
		var row := lines[i].strip_edges().split(",")
		if row.size() != 9: continue
		var index := int(row[3])
		var mount := {"offset":Vector2(float(row[4]),float(row[5])),
			"angle":deg_to_rad(float(row[6])),"size":Vector2(float(row[7]),float(row[8]))}
		match row[2]:
			"pdc": station.defense_mounts[index] = mount
			"atraque_normal":
				station.dock_mounts[index] = mount
				station.ports += 1
			"atraque_dread":
				station.dock_mounts[CAPITAL_PORT+index] = mount
				station.capital_ports += 1

func nearest_station(local_sector: int, position: Vector2) -> int:
	var index := -1
	var best := INF
	for i in range(stations.size()):
		var station: Dictionary = stations[i]
		if station.sector != local_sector: continue
		var distance := position.distance_squared_to(station.p)
		if distance < best:
			best = distance
			index = i
	return index

func is_station_discovered(index: int) -> bool:
	if index == 0: return station_discovered
	if index == 1: return nacar_discovered
	return stations[index].discovered

func station_axis(station: Dictionary, wing: int) -> Vector2:
	if station.layout == "tri": return Vector2.UP.rotated(wing*TAU/3)
	if station.layout == "bi": return Vector2.UP.rotated(wing*PI)
	if station.layout == "shipyard": return Vector2.RIGHT
	return [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT][wing%4]

func port_axis(port: int, station: Dictionary = {}) -> Vector2:
	if station.get("dock_mounts",{}).has(port): return Vector2.from_angle(station.dock_mounts[port].angle)
	if not station.is_empty() and station.layout != "cross":
		var wing := port-CAPITAL_PORT if port >= CAPITAL_PORT else (port/2 if station.layout == "tri" else port)
		return station_axis(station,wing)
	if port >= CAPITAL_PORT: return Vector2.UP
	return [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT][port/2]

func port_center(station: Dictionary, port: int) -> Vector2:
	if station.get("dock_mounts",{}).has(port): return station.p+station.dock_mounts[port].offset
	if station.layout != "cross":
		var wing := port-CAPITAL_PORT if port >= CAPITAL_PORT else (port/2 if station.layout == "tri" else port)
		var axis := station_axis(station,wing)
		var tip: float = station.size*(.52 if station.layout == "tri" else (.33 if station.layout == "bi" else .16))
		var distance := tip+PORT_LENGTH*.5+25
		if port >= CAPITAL_PORT: return station.p+axis*(distance+PORT_LENGTH*.5+CAPITAL_LENGTH*.5+35)
		var side := 55.0 if port%2 == 0 else -55.0
		if station.layout == "bi": side = 55.0
		return station.p+axis*distance+axis.orthogonal()*side
	var point: Variant = hardpoints.get("estacion/%d/atraque/%d" % [4107+station.sector,port],
		hardpoints.get("estacion/*/atraque/%d" % port))
	if point is Vector2: return station.p+point
	if port == CAPITAL_PORT: return station.p + Vector2(0,-385)
	var axis := port_axis(port)
	return station.p + axis * (station.size / 2 + 82.5) + axis.orthogonal() * (48 if port%2 == 0 else -48)

func dock_at(index: int, port: int) -> void:
	dock_station = index
	var available := docking_ports(stations[index])
	dock_port = port if available.has(port) else int(available[0])
	port = dock_port
	pos = port_center(stations[index],port)
	angle = port_axis(port,stations[index]).angle()+PI/2
	dock()

func rescue_dock() -> void:
	var local_station := nearest_station(sector,pos)
	if local_station >= 0:
		dock_at(local_station,0)
		return
	if sector != 0:
		sector = 0
		rocks = fields[0]
		fragments = sector_loot[0]
		reset_traffic_on_launch = true
	dock_at(0,0)

func dock_coverage(offset: Vector2, axis: Vector2, dimensions: Vector2) -> float:
	var forward_axis := forward()
	var side := forward_axis.orthogonal()*ship_half_width()
	var nose := forward_axis*stat(3)*.5
	var hull := PackedVector2Array()
	for corner in [offset+nose+side,offset+nose-side,offset-nose-side,offset-nose+side]:
		hull.append(Vector2(corner.dot(axis),corner.dot(axis.orthogonal())))
	var h := dimensions*.5
	var bounds := PackedVector2Array([Vector2(-h.x,-h.y),Vector2(h.x,-h.y),h,Vector2(-h.x,h.y)])
	var covered := 0.0
	for polygon in Geometry2D.intersect_polygons(hull,bounds):
		var area := 0.0
		for i in range(polygon.size()):
			area += polygon[i].cross(polygon[(i+1)%polygon.size()])
		covered += absf(area)*.5
	return covered/(stat(3)*2.0*ship_half_width())

func repair_stations(dt: float) -> void:
	for station in stations:
		var wait: float = station.repair_delay
		station.repair_delay = maxf(0,wait-dt)
		if station.hp >= station.max_hp: continue
		station.repair_fraction += maxf(0,dt-wait)*station.max_hp/300.0
		var recovered := int(station.repair_fraction)
		station.hp = mini(station.max_hp,station.hp+recovered)
		station.repair_fraction -= recovered
		if station.hp == station.max_hp: station.repair_fraction = 0.0

func try_dock() -> void:
	if hangar or map_open: return
	if vel.length() > 3:
		status = "Reduce la velocidad a 3 o menos para atracar"
		return
	for i in range(stations.size()):
		var station := stations[i]
		if station.sector != sector or pos.distance_to(station.p) > station.size+CAPITAL_LENGTH+stat(3): continue
		for port in docking_ports(station):
			var dimensions := port_dimensions(port,station)
			var axis := port_axis(port,station)
			var offset := pos-port_center(station,port)
			var alignment := absf(forward().dot(axis))
			if alignment + .000001 < cos(deg_to_rad(10)) or dock_coverage(offset,axis,dimensions) < .89999: continue
			mark_station(i)
			dock_at(i,port)
			status = "Atraque completado · "+station.name
			return
	status = "Atraque: alinea la nave a 10° y deja el 90 % del casco dentro"

func ship_half_width() -> float:
	return maxf(4,stat(3)*ships[selected].get_width()/float(ships[selected].get_height())*.5)

func station_shapes(station: Dictionary) -> Array[Rect2]:
	var size: float = station.size
	var p: Vector2 = station.p
	return [Rect2(p-Vector2(size*.46,size*.071),Vector2(size*.92,size*.142)),
		Rect2(p-Vector2(size*.071,size*.46),Vector2(size*.142,size*.92)),
		Rect2(p-Vector2.ONE*size*.13,Vector2.ONE*size*.26)]

func station_contact(previous: Vector2) -> bool:
	var width := ship_half_width()
	for station in stations:
		if station.sector != sector or pos.distance_to(station.p) > station.size*1.3+stat(3): continue
		if station.layout != "cross":
			var collision := false
			for longitudinal in [-.45,0,.45]:
				var point: Vector2 = pos+forward()*stat(3)*longitudinal
				for i in range(9):
					var sample := point if i == 8 else point+Vector2.from_angle(i*TAU/8)*width
					if absf((sample-pos).dot(forward())) <= stat(3)*.5 and station_contains(station,sample):
						collision = true
			if collision:
				var speed := vel.length()
				pos = previous
				vel *= -.32
				if speed > 14: player_damage(int(speed*.3))
				if hp <= 0: destroyed()
				return true
			continue
		for shape in station_shapes(station):
			for i in [-1,0,1]:
				var sample: Vector2 = pos+forward()*int(i)*stat(3)*.37
				if not shape.grow(width).has_point(sample): continue
				var speed := vel.length()
				pos = previous
				vel *= -.32
				if speed > 14: player_damage(int(speed*.3))
				if hp <= 0: destroyed()
				return true
	return false

func draw_stations() -> void:
	for station in stations:
		if station.sector != sector: continue
		var size := Vector2.ONE*float(station.size)
		draw_texture_rect(station.art,Rect2(station.p-station.pivot*size,size),false)
		label(station.p+Vector2(-53,21),station.name,12,Color.TURQUOISE)
		if pos.distance_to(station.p) > station.size+CAPITAL_LENGTH+stat(3): continue
		for port in docking_ports(station):
			var p := port_center(station,port)
			var dimensions := port_dimensions(port,station)
			var axis := port_axis(port,station)
			var across := axis.orthogonal()
			var points := PackedVector2Array()
			for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
				points.append(p+axis*corner.x*dimensions.x*.5+across*corner.y*dimensions.y*.5)
			draw_colored_polygon(points,Color(.03,.26,.14,.52))
			points.append(points[0])
			draw_polyline(points,Color.PALE_GREEN,1.5)
			if port >= CAPITAL_PORT: label(p+Vector2(-67,-145),"Atraque universal" if station.layout == "shipyard" else "Atraque Dreadnought",14,Color.PALE_GREEN)
		label(station.p+Vector2(-74,40),"Mantén B · Autoatraque · Casco %d" % station.hp,13,Color.PALE_GREEN)

func station_contains(station: Dictionary, point: Vector2) -> bool:
	var uv: Vector2 = (point-station.p)/float(station.size)+station.pivot
	if uv.x < 0 or uv.y < 0 or uv.x >= 1 or uv.y >= 1: return false
	var mask: Image = station.mask
	return mask.get_pixel(int(uv.x*mask.get_width()),int(uv.y*mask.get_height())).a > .12

func mark_station(index: int) -> void:
	stations[index].discovered = true
	if index == 0: station_discovered = true
	elif index == 1: nacar_discovered = true

var auto_station := -1
var auto_port := -1
var auto_ready := 0.0
var auto_angle := 0.0

func update_auto_dock(dt: float, held: bool) -> bool:
	if not held or hangar or map_open:
		if auto_station >= 0 and not held: status = "Autoatraque cancelado"
		auto_station = -1
		auto_ready = 0.0
		return false
	if auto_station < 0:
		var best := 0.0
		for index in range(stations.size()):
			var station := stations[index]
			if station.sector != sector: continue
			for port in docking_ports(station):
				var axis := port_axis(port,station)
				var coverage := dock_coverage(pos-port_center(station,port),axis,port_dimensions(port,station))
				if coverage <= best: continue
				best = coverage
				auto_station = index
				auto_port = port
		if auto_station < 0:
			status = "Entra parcialmente en una zona verde y mantén B"
			return false
		var axis := port_axis(auto_port,stations[auto_station])
		auto_angle = axis.angle()+PI/2
		if absf(angle_difference(angle,auto_angle+PI)) < absf(angle_difference(angle,auto_angle)): auto_angle += PI
	var station := stations[auto_station]
	if station.sector != sector or not docking_ports(station).has(auto_port):
		auto_station = -1
		return false
	angle = rotate_toward(angle,auto_angle,deg_to_rad(maxf(23,159-stat(3)))*(1+.1*module_count(7))*dt)
	var offset: Vector2 = port_center(station,auto_port)-pos
	var desired := offset.limit_length(35)
	if offset.length() < 3: desired = Vector2.ZERO
	var previous_velocity := vel
	vel = vel.move_toward(desired,maxf(40,float(stat(1))/stat(0))*(1+.1*module_count(6))*dt)
	player_thrust = (vel-previous_velocity).length()/maxf(dt,.00001)
	var axis := port_axis(auto_port,station)
	var ready := vel.length() <= 3 and absf(forward().dot(axis))+.000001 >= cos(deg_to_rad(10)) and dock_coverage(-offset,axis,port_dimensions(auto_port,station)) >= .89999
	auto_ready = auto_ready+dt if ready else 0.0
	status = "Autoatraque · suelta B para cancelar · %.1f s" % maxf(0,1-auto_ready) if ready else "Autoatraque · alineando y frenando · suelta B para cancelar"
	if auto_ready >= 1:
		mark_station(auto_station)
		dock_at(auto_station,auto_port)
		status = "Atraque completado · "+station.name
		auto_station = -1
		auto_ready = 0
	return true

func clear_station_approaches() -> void:
	for station in stations:
		if station.layout == "cross": continue
		for rock in fields[station.sector]:
			if rock.p.distance_to(station.p) <= station.size+CAPITAL_LENGTH+rock.r:
				rock.hp = 0
				rock.mined = false

func draw_docked_background(screen: Vector2) -> void:
	if stations.is_empty(): return
	var station := stations[dock_station]
	var size := Vector2.ONE*float(station.size)*2.6
	var center := screen/2+(Vector2(station.p)-pos)*2.6
	draw_texture_rect(station.soft,Rect2(center-station.pivot*size,size),false,Color(.54,.64,.74,.86))
	draw_rect(Rect2(Vector2.ZERO,screen),Color(.035,.07,.13,.58))



const SHIP_COUNT := 27
var trait_values: Dictionary = {}

var hardpoints: Dictionary = {}

func load_hardpoints() -> bool:
	if not read_hardpoint_file("res://hardpoints.txt",-1): return false
	for id in range(SHIP_COUNT):
		var path := "res://hardpoints/ship%d.txt" % id
		if FileAccess.file_exists(path) and not read_hardpoint_file(path,id): return false
	return true

func read_hardpoint_file(path: String, expected_ship: int) -> bool:
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir "+path)
		return false
	file.get_line()
	while file.get_position() < file.get_length():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"): continue
		var row := line.split(",")
		if row.size() != 6 or not row[3].is_valid_int() or not row[4].is_valid_float() or not row[5].is_valid_float():
			push_error("Hardpoint inválido en "+path+": "+line)
			return false
		if expected_ship >= 0 and (row[0] != "nave" or row[1] != str(expected_ship)):
			push_error("ID de nave distinto al del archivo "+path)
			return false
		hardpoints["%s/%s/%s/%s" % [row[0],row[1],row[2],row[3]]] = Vector2(float(row[4]),float(row[5]))
	return true

func ship_mount(ship: int, kind: String, index: int, count: int) -> Vector2:
	var length := float(specs[ship][3])
	var width := length*ships[ship].get_width()/float(ships[ship].get_height())
	var point: Variant = hardpoints.get("nave/%d/%s/%d" % [ship,kind,index])
	if point is Vector2: return Vector2(point.x*width,point.y*length)
	var side := (float(index)/(count-1)-.5)*width*.72 if count > 1 else 0.0
	if kind == "motor": return Vector2(side,length*.48)
	return Vector2(side,-length*.5-(9 if kind == "cohete" else 0))

func engine_count(ship: int) -> int:
	var count := 0
	while hardpoints.has("nave/%d/motor/%d" % [ship,count]): count += 1
	return maxi(1,count)

func npc_mount(npc: Dictionary, kind: String) -> Vector2:
	return npc.p+ship_mount(npc.ship,kind,0,1).rotated(npc.angle)

func load_ship_traits() -> bool:
	var file := FileAccess.open("res://ship-traits.txt",FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir ship-traits.txt")
		return false
	file.get_line()
	while file.get_position() < file.get_length():
		var line := file.get_line().strip_edges()
		if line.is_empty(): continue
		var row := line.split(",")
		if row.size() != 3 or not row[2].is_valid_float():
			push_error("Rasgo de nave inválido: "+line)
			return false
		trait_values[row[0]+"/"+row[1]] = float(row[2])
	return true

func ship_trait(trait_name: String, parameter: String, fallback: float) -> float:
	if trait_name not in specs[selected][12].split("|"): return fallback
	return float(trait_values.get(trait_name+"/"+parameter,fallback))

func mining_aim(nose: Vector2, forward_axis: Vector2, reach: float) -> Vector2:
	var cone := ship_trait("gimbal_miners","cono_grados",0)
	if cone <= 0: return forward_axis
	var minimum_dot := cos(deg_to_rad(minf(180,cone)*.5))
	var nearest := INF
	var aim := forward_axis
	for rock in rocks:
		if rock.hp <= 0: continue
		var offset: Vector2 = rock.p-nose
		var length := offset.length()
		var surface := maxf(0,length-float(rock.r))
		if length <= 0 or surface > reach or surface >= nearest: continue
		var direction := offset/length
		if direction.dot(forward_axis) < minimum_dot: continue
		nearest = surface
		aim = direction
	return aim

func load_ship_catalog() -> bool:
	ships.resize(SHIP_COUNT)
	specs.resize(SHIP_COUNT)
	var file := FileAccess.open("res://ships-godot.txt",FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir ships-godot.txt")
		return false
	file.get_line()
	while file.get_position() < file.get_length():
		var line := file.get_line().strip_edges()
		if line.is_empty(): continue
		var row := line.split(",")
		if row.size() != 16 or not row[0].is_valid_int() or row[2] not in ["0","180"]:
			push_error("Fila de nave inválida en ships-godot.txt: "+line)
			return false
		var id := int(row[0])
		if id < 0 or id >= SHIP_COUNT or ships[id] != null:
			push_error("ID de nave inválido o repetido: "+row[0])
			return false
		var texture := load("res://ships/"+row[1].strip_edges()) as Texture2D
		if texture == null:
			push_error("PNG de nave inválido: "+row[1])
			return false
		if row[2] == "180":
			var art := texture.get_image()
			art.flip_x()
			art.flip_y()
			texture = ImageTexture.create_from_image(art)
		ships[id] = texture
		specs[id] = row.slice(3)
	if ships.has(null):
		push_error("Faltan IDs de nave en ships-godot.txt")
		return false
	return true

func _ready() -> void:
	target_title_font.font_names = PackedStringArray(["Segoe UI"])
	target_title_font.font_weight = 700
	target_body_font.font_names = PackedStringArray(["Consolas"])
	add_child(missile_layer)
	for i in range(1,33):
		var path := "res://environment/debris-%02d.png" % i
		if ResourceLoader.exists(path): wreck_sprites.append(load(path))
	for size in range(1, 6):
		for variant in range(1, 3):
			asteroid_sprites.append(load("res://environment/asteroid-%d-%d.png" % [size, variant]))
	if not load_hardpoints() or not load_ship_traits() or not load_ship_catalog():
		get_tree().quit(1)
		return
	cargo.resize(RES.size())
	cargo.fill(0)
	inventory.resize(RES.size())
	inventory.fill(0)
	for i in range(5):
		fields.append(generate_field(i))
		sector_loot.append([])
	rocks = fields[0]
	fragments = sector_loot[0]

	load_stations()
	for i in range(6): ftl_frame(i)
	dock_at(0,0)
	reset_traffic()
	load_game()
	clear_station_approaches()

var links := generate_links()

func generate_links() -> Array[Vector2i]:
	var state := 4107
	var result: Array[Vector2i] = []
	for i in range(1,5):
		state = (state*73+41)%65521
		result.append(Vector2i(state%i,i))
	while result.size() < 6:
		state = (state*73+41)%65521
		var a := state%5
		state = (state*73+41)%65521
		var b := state%5
		var pair := Vector2i(mini(a,b),maxi(a,b))
		if a != b and not result.has(pair): result.append(pair)
	return result
const MAP_POINTS := [Vector2(-175,0),Vector2(130,-95),Vector2(-20,-105),Vector2(160,95),Vector2(-30,105)]
var fields: Array = []
var sector_loot: Array = []
var sector := 0
var crossed := 0
var map_open := false

func generate_field(index: int) -> Array:
	var field: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 4107 + index * 7729
	for line in FileAccess.get_file_as_string("res://sector.txt").strip_edges().split("\n"):
		var row := line.strip_edges().split(",")
		if index > 0:
			var point := Vector2(rng.randi_range(-4940,4940),rng.randi_range(-4940,4940))
			if point.length() < 175: point.x += 245
			row = PackedStringArray([str(int(point.x)),str(int(point.y)),str(rng.randi_range(12,45)),row[3],row[4],row[5]])
		field.append({"p":Vector2(int(row[0]),int(row[1])),"r":int(row[2]),"hp":ROCK_HP,
			"first":int(row[3]),"second":int(row[4]),"seen":false,
			"ideal":.25+.05*int(row[5]),"progress":0.0})

	return field

func gate_position(edge: int, local: int) -> Vector2:
	var slot_index := 0
	for i in range(edge):
		if local == links[i].x or local == links[i].y: slot_index += 1
	return [Vector2(0,-1250),Vector2(1250,0),Vector2(0,1250),Vector2(-1250,0)][slot_index]

const FTL_ATLAS := preload("res://environment/ftl-arrival-v2.png")
var ftl_cooldown := 0.0
var ftl_destination := -1
var ftl_depart_age := -1.0
var ftl_arrival_age := 1.0
var ftl_exits: Array[Dictionary] = []

func known_sectors() -> int:
	var known := 1 | (1 << sector)
	for i in range(links.size()):
		if crossed & (1 << i): known |= (1 << links[i].x) | (1 << links[i].y)
	return known

func jump_distance(destination: int) -> int:
	var distances := {sector:0}
	var queue := [sector]
	while not queue.is_empty():
		var current: int = queue.pop_front()
		if current == destination: return int(distances[current])
		for link in links:
			var next := link.y if link.x == current else (link.x if link.y == current else -1)
			if next >= 0 and not distances.has(next):
				distances[next] = int(distances[current])+1
				queue.append(next)
	return 999

func can_ftl(destination: int) -> bool:
	return not hangar and module_count(10) > 0 and ftl_cooldown <= 0 and destination >= 0 and destination < 5 and destination != sector and (known_sectors() & (1 << destination)) != 0 and jump_distance(destination) <= 3 and ftl_depart_age < 0 and ftl_arrival_age >= 1

func request_ftl(destination: int) -> void:
	if not can_ftl(destination):
		status = "FTL requiere módulo, destino conocido a 1–3 enlaces y recarga completada"
		return
	ftl_destination = destination

func confirm_ftl() -> void:
	if not can_ftl(ftl_destination):
		ftl_destination = -1
		return
	ftl_depart_age = 0.0
	for state in pdc_states.values(): state.trace = 0.0
	map_open = false
	ftl_cooldown = 300.0
	var state := player_shield()
	if state.value > 0: state.break_flash = .28
	state.value = 0.0
	state.lock = 60.0
	state.delay = 10.0

func commit_ftl() -> void:
	sector = ftl_destination
	rocks = fields[sector]
	fragments = sector_loot[sector]
	var candidate := Vector2(850,700)
	for attempt in range(200):
		candidate = Vector2(randf_range(-1600,1600),randf_range(-1600,1600))
		var clear := true
		for rock in rocks:
			if rock.hp > 0 and candidate.distance_to(rock.p) < rock.r+stat(3)*.65+20: clear = false
		for station in stations:
			if station.sector == sector and candidate.distance_to(station.p) < station.size*.8+stat(3): clear = false
		if clear: break
	pos = candidate
	vel = Vector2.ZERO
	selected_target = -1
	npc_target = {}
	extra_target = {}
	target = -1
	salvage_target = -1
	mining_rays.clear()
	salvage_rays.clear()
	bullets.clear()
	cooldown = 0.0
	clear_missiles()
	explosions.clear()
	reset_traffic()
	ftl_exits.clear()
	ftl_depart_age = -1.0
	ftl_arrival_age = 0.0
	ftl_destination = -1
	status = "FTL · Sector %d · Escudos bloqueados 60 s" % (4107+sector)

func ftl_npc_arrival(npc: Dictionary) -> void:
	npc.entry_age = 0.0
	if npc.ftl:
		npc.shield_state.value = 0.0
		npc.shield_state.lock = 60.0
		npc.shield_state.delay = 10.0

func update_ftl(dt: float) -> void:
	ftl_cooldown = maxf(0,ftl_cooldown-dt)
	if not freight.is_empty(): freight.ftl_wait = maxf(0,float(freight.get("ftl_wait",0))-dt)
	ftl_arrival_age = minf(1,ftl_arrival_age+dt)
	for npc in npcs: npc.entry_age = minf(1,npc.entry_age+dt)
	for i in range(ftl_exits.size()-1,-1,-1):
		ftl_exits[i].age += dt
		if ftl_exits[i].age > .65: ftl_exits.remove_at(i)
	if ftl_depart_age >= 0:
		ftl_depart_age += dt
		if ftl_depart_age >= .65: commit_ftl()

func ftl_offset(age: float, facing: float, departure: bool = false) -> Vector2:
	return Vector2.UP.rotated(facing)*(650*pow(clampf(age/.65,0,1),3) if departure else -650*pow(1-clampf((age-.15)/.85,0,1),3))

var ftl_frames: Array[Texture2D] = []

func ftl_frame(index: int) -> Texture2D:
	if ftl_frames.is_empty(): ftl_frames.resize(6)
	if ftl_frames[index] == null:
		var image := FTL_ATLAS.get_image().get_region(Rect2i(index*362,0,362,362))
		for y in range(362):
			for x in range(362):
				var radius := (Vector2(x+.5,y+.5)-Vector2(181,181)).length()/181.0
				var color := image.get_pixel(x,y)
				color.a *= 1.0-smoothstep(.72,.98,radius)
				image.set_pixel(x,y,color)
		ftl_frames[index] = ImageTexture.create_from_image(image)
	return ftl_frames[index]

func draw_ftl_burst(point: Vector2, age: float, size: float) -> void:
	if age < 0 or age >= .7: return
	var frame := mini(5,int(age/.7*6))
	var opacity := clampf((.7-age)/.25,0,1)
	draw_texture_rect(ftl_frame(frame),Rect2(point-Vector2.ONE*size*.5,Vector2.ONE*size),false,Color(1,1,1,opacity))

func map_ftl_click(point: Vector2) -> void:
	var center := get_viewport_rect().size*.5
	if ftl_destination >= 0:
		if Rect2(center+Vector2(-180,45),Vector2(160,35)).has_point(point): confirm_ftl()
		elif Rect2(center+Vector2(20,45),Vector2(160,35)).has_point(point): ftl_destination = -1
		return
	for i in range(5):
		if (known_sectors() & (1 << i)) != 0 and point.distance_to(center+MAP_POINTS[i]) <= 20:
			request_ftl(i)
			return

func draw_ftl_map(center: Vector2) -> void:
	label(center+Vector2(-225,125),"FTL · %.0f s de recarga · alcance 3" % ftl_cooldown,14,Color.TURQUOISE)
	if ftl_destination < 0: return
	draw_rect(Rect2(center-Vector2(220,70),Vector2(440,165)),Color("#081322"))
	label(center+Vector2(-200,-40),"¿Saltar al sector %d?" % (4107+ftl_destination),19,Color.TURQUOISE)
	label(center+Vector2(-200,-10),"Recarga 5 min · Escudos inactivos 1 min",15)
	menu_button(Rect2(center+Vector2(-180,45),Vector2(160,35)),"Confirmar",true)
	menu_button(Rect2(center+Vector2(20,45),Vector2(160,35)),"Cancelar")

func cross_gate() -> void:
	if hangar or map_open: return
	for i in range(links.size()):
		var link: Vector2i = links[i]
		if sector != link.x and sector != link.y: continue
		if pos.distance_to(gate_position(i,sector)) > 110: continue
		sector = link.y if link.x == sector else link.x
		crossed |= 1 << i
		rocks = fields[sector]
		fragments = sector_loot[sector]
		var arrival := gate_position(i,sector)
		pos = arrival-arrival.normalized()*130
		vel = Vector2.ZERO
		selected_target = -1
		target = -1
		mining_rays.clear()
		salvage_rays.clear()
		salvage_target = -1
		ping = 1000
		bullets.clear()
		cooldown = 0.0
		clear_missiles()
		explosions.clear()
		reset_traffic()
		status = "Salto al sector %d" % (4107+sector)
		return
	status = "Acércate a una puerta estelar para saltar"

func ship_name() -> String:
	return specs[selected][9] if specs[selected].size() > 9 else "Nave %02d" % (selected+1)

func draw_maps(screen: Vector2) -> void:
	if not hangar:
		var bounds := Rect2(screen.x-136,18,116,116)
		draw_rect(bounds,Color("#151d38"))
		draw_rect(bounds,Color.TURQUOISE,false)
		for i in range(links.size()):
			if (crossed & (1 << i)) == 0 or (sector != links[i].x and sector != links[i].y): continue
			draw_circle(bounds.position+(gate_position(i,sector)/10000.0+Vector2(.5,.5))*bounds.size,3,Color.MEDIUM_PURPLE)
		for index in range(stations.size()):
			var station: Dictionary = stations[index]
			if station.sector == sector and is_station_discovered(index):
				var marker := bounds.position+(Vector2(station.p)/10000.0+Vector2(.5,.5))*bounds.size
				draw_rect(Rect2(marker-Vector2(3,3),Vector2(6,6)),Color.PALE_GREEN)
		draw_circle(bounds.position+(pos/10000.0+Vector2(.5,.5))*bounds.size,4,Color.WHITE)
	if not map_open: return
	var center := screen/2
	var panel := Rect2(center-Vector2(245,175),Vector2(490,350))
	draw_rect(panel,Color("#151d38"))
	draw_rect(panel,Color.TURQUOISE,false)
	label(panel.position+Vector2(20,30),"MAPA ESTELAR  |  M Cerrar",18,Color.TURQUOISE)
	var visited := 1
	for i in range(links.size()):
		if (crossed & (1 << i)) == 0: continue
		var link: Vector2i = links[i]
		visited |= (1 << link.x) | (1 << link.y)
		draw_line(center+MAP_POINTS[link.x],center+MAP_POINTS[link.y],Color.TURQUOISE,2)
	for i in range(5):
		if (visited & (1 << i)) == 0: continue
		var point: Vector2 = center+MAP_POINTS[i]
		draw_circle(point,8,Color.GOLD if i == sector else Color.WHITE)
		label(point+Vector2(11,5),str(4107+i),14)
	var station_labels := [0,0,0,0,0]
	for index in range(stations.size()):
		if not is_station_discovered(index): continue
		var station: Dictionary = stations[index]
		var local := int(station.sector)
		var caption := String(station.name).trim_prefix("Estación ")
		label(center+MAP_POINTS[local]+Vector2(-32,29+station_labels[local]*16),caption,13,Color.PALE_GREEN)
		station_labels[local] += 1
	label(panel.position+Vector2(20,330),"G salta desde una puerta cercana",14)

func stat(i: int) -> int:
	return int(specs[selected][i])

func used() -> int:
	var total := 0
	for amount in cargo:
		total += int(amount)
	return total

func unload_cargo() -> void:
	if not hangar: return
	var amount := used()
	if amount == 0:
		status = "La bodega está vacía"
		return
	for i in range(RES.size()):
		inventory[i] = int(inventory[i]) + int(cargo[i])
	cargo.fill(0)
	status = "%d U transferidas al inventario" % amount

func forward() -> Vector2:
	return Vector2.UP.rotated(angle)

func dock() -> void:
	extra_target = {}
	hangar = true
	selected_target = -1
	npc_target = {}
	hp = stat(2)
	vel = Vector2.ZERO
	bullets.clear()
	cooldown = 0.0
	clear_missiles()
	ping = 1000
	target = -1
	mining_rays.clear()

func choose(i: int) -> void:
	if int(specs[i][4]) < used():
		status = "La carga supera la capacidad de esa nave"
		return
	selected = i
	hp = stat(2)
	status = ""

var extra_target: Dictionary = {}
var console_open := false
var console_text := ""
var console_result := "show_vectors 0 | show_vectors 1"
var show_vectors := false
var player_thrust := 0.0

func entities() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for i in range(rocks.size()):
		if rocks[i].hp > 0: entries.append({"kind":"Asteroide","p":rocks[i].p,"r":float(rocks[i].r),"index":i})
	for npc in npcs:
		if npc.hp > 0: entries.append({"kind":"Nave","p":npc.p,"r":float(specs[npc.ship][3])*.4,"data":npc})
	for station in stations:
		if station.sector == sector: entries.append({"kind":"Estación","p":station.p,"r":station.size*.48,"data":station})
	for wreck in wreck_fields[sector]:
		entries.append({"kind":"Restos","p":wreck.p,"r":wreck_radius(wreck),"data":wreck})
	for item in fragments: entries.append({"kind":"Recursos","p":item.p,"r":10.0,"data":item})
	for item in module_drops[sector]: entries.append({"kind":"Módulo","p":Vector2(item[0],item[1]),"r":12.0,"module":int(item[2])})
	for i in range(links.size()):
		if sector in [links[i].x,links[i].y]: entries.append({"kind":"Puerta","p":gate_position(i,sector),"r":65.0})
	return entries

func select_entity(entry: Dictionary) -> void:
	selected_target = -1
	npc_target = {}
	extra_target = {}
	if entry.is_empty(): return
	if entry.kind == "Asteroide": selected_target = int(entry.index)
	elif entry.kind == "Nave": npc_target = entry.data
	else: extra_target = entry

func cycle_target() -> void:
	if hangar: return
	var nearby := entities()
	nearby.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return pos.distance_squared_to(a.p) < pos.distance_squared_to(b.p))
	select_entity(nearby[0] if not nearby.is_empty() else {})

func click_target(pointer: Vector2, deselect_empty: bool = false) -> void:
	var point := pos+(pointer-get_viewport_rect().size*.5)/zoom
	var nearby := entities()
	nearby.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return point.distance_squared_to(a.p) < point.distance_squared_to(b.p))
	for entity in nearby:
		if point.distance_to(entity.p) <= maxf(entity.r,8.0/zoom):
			select_entity(entity)
			return

	if deselect_empty: select_entity({})

const CONSOLE_COMMANDS := ["show_vectors"]
var completion_seed := ""
var completion_last := ""
var completion_index := -1

func complete_console() -> void:
	if completion_index < 0 or console_text != completion_last:
		completion_seed = console_text
		completion_index = -1
	var split_at := completion_seed.rfind(" ")+1
	var head := completion_seed.left(split_at)
	var prefix := completion_seed.substr(split_at).to_lower()
	var options: Array[String] = []
	var source: Array = CONSOLE_COMMANDS if head.strip_edges().is_empty() else (["0","1"] if head.strip_edges().to_lower() == "show_vectors" else [])
	for option in source:
		if option.begins_with(prefix): options.append(option)
	if options.is_empty(): return
	completion_index = (completion_index+1)%options.size()
	console_text = head+options[completion_index]
	completion_last = console_text

func console_command() -> void:
	var parts := console_text.strip_edges().split(" ",false)
	if parts.size() == 2 and parts[0] == "show_vectors" and parts[1] in ["0","1"]:
		show_vectors = parts[1] == "1"
		console_result = "show_vectors "+parts[1]
	else: console_result = "Uso: show_vectors 0 | show_vectors 1"
	console_text = ""
	completion_index = -1

func draw_console(screen: Vector2) -> void:
	if not console_open: return
	draw_rect(Rect2(15,15,screen.x-30,115),Color("#08111f"))
	draw_rect(Rect2(15,15,screen.x-30,115),Color.TURQUOISE,false)
	label(Vector2(30,40),"CONSOLA · Tab completar · º / Esc cerrar",18,Color.TURQUOISE)
	label(Vector2(30,72),console_result,16)
	label(Vector2(30,106),"> "+console_text+"_",18)

func vector_arrow(point: Vector2, velocity: Vector2, active: float, facing: Vector2) -> void:
	if not show_vectors: return
	var f := velocity.normalized() if velocity.length_squared() > .0001 else facing
	var tip := point+f*clampf(active*.65,12,160)
	draw_line(point,tip,Color.AQUAMARINE,2)
	draw_line(tip,tip-f.rotated(.5)*9,Color.AQUAMARINE,2)
	draw_line(tip,tip-f.rotated(-.5)*9,Color.AQUAMARINE,2)

func draw_target_info(screen: Vector2) -> void:
	if hangar: return
	var rows: Array[String] = []
	if selected_target >= 0 and rocks[selected_target].hp > 0:
		var rock: Dictionary = rocks[selected_target]
		rows.append("Asteroide")
		rows.append("Casco estimado ~%d" % (maxi(1,roundi(rock.hp/100.0)*100)))
		if rock.seen:
			var count := 2+asteroid_size(rock.r)*2
			rows.append("%s · %d U" % [RES[rock.first],count*10 if rock.second < 0 else count*5])
			if rock.second >= 0: rows.append("%s · %d U" % [RES[rock.second],count*5])
		else: rows.append("Contenido sin escanear · TAB")
	elif not npc_target.is_empty() and npc_target.hp > 0:
		rows.append(str(specs[npc_target.ship][9])+" · "+str(npc_target.role))
		rows.append(str(specs[npc_target.ship][10]))
		if npc_target.get("scanned",false):
			rows.append("Casco %d / %d" % [npc_target.hp,int(specs[npc_target.ship][2])])
			var amount := int(npc_target.cargo)
			if is_same(npc_target,trader): amount = trader_stock.reduce(func(total: int,value: int) -> int: return total+value,0)
			elif is_same(npc_target,freight_ship) and not freight.is_empty(): amount = int(freight.amount)
			rows.append("Bodega %d / %d U" % [amount,int(specs[npc_target.ship][4])])
			rows.append("Módulos")
			rows.append(MODULE_NAMES[npc_target.module] if npc_target.module >= 0 else "Ninguno")
			if npc_target.get("missile_loot",false): rows.append("Cohete")
			if npc_target.ftl: rows.append("FTL")
			if npc_target.shield:
				rows.append("Escudo %d / %d" % [ceili(npc_target.shield_state.value),int(specs[npc_target.ship][2])*.5])
		else: rows.append("Detalles sin escanear · TAB")
	elif not extra_target.is_empty():
		rows.append(extra_target.kind)
		if extra_target.has("module"): rows.append(MODULE_NAMES[extra_target.module])
		elif extra_target.kind == "Estación": rows.append(str(extra_target.data.name))
		elif extra_target.kind == "Recursos": rows.append("%s · %d U" % [RES[extra_target.data.resource],extra_target.data.amount])
	if rows.is_empty(): return
	var at := Vector2(screen.x-275,145)
	draw_rect(Rect2(at,Vector2(255,26+rows.size()*22)),Color("#101c30"))
	draw_rect(Rect2(at,Vector2(255,26+rows.size()*22)),Color.TURQUOISE,false)
	for i in range(rows.size()):
		var title := i == 0 or rows[i] == "Módulos"
		draw_string(target_title_font if title else target_body_font,at+Vector2(10,24+i*22),rows[i],HORIZONTAL_ALIGNMENT_LEFT,235,16 if title else 13,Color.TURQUOISE if title else Color("#e2e9f2"))



func normalize_weapon() -> void:
	var available := equipped_modes()
	if mode not in available: mode = available[0] if not available.is_empty() else 3

func launch() -> void:
	normalize_weapon()
	if hangar and not docking_ports(stations[dock_station]).has(dock_port):
		dock_at(dock_station,0)
	if reset_traffic_on_launch:
		reset_traffic()
		reset_traffic_on_launch = false
	hangar = false

func _input(event: InputEvent) -> void:
	if player_destroying or ftl_depart_age >= 0 or ftl_arrival_age < 1: return
	if event is InputEventKey and event.keycode == KEY_B and not event.pressed:
		if auto_station >= 0: status = "Autoatraque cancelado"
		auto_station = -1
		auto_ready = 0.0
	if event is InputEventKey and event.pressed:
		if not event.echo and (event.physical_keycode == KEY_QUOTELEFT or event.unicode == 186):
			console_open = not console_open
			return
		if console_open:
			if event.keycode == KEY_ESCAPE: console_open = false
			elif event.keycode == KEY_TAB: complete_console()
			elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER: console_command()
			elif event.keycode == KEY_BACKSPACE: console_text = console_text.left(maxi(0,console_text.length()-1))
			elif event.unicode >= 32 and console_text.length() < 100: console_text += char(event.unicode)
			return
	if console_open: return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if ftl_destination >= 0:
			ftl_destination = -1
		elif market > 0:
			market = 0
			quantity_row = -1
		elif inventory_open:
			inventory_open = false
			dragged_module = -1
		elif help_open:
			help_open = false
		elif map_open:
			map_open = false
		return
	if map_open and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		map_ftl_click(event.position)
		return
	if market > 0:
		if event is InputEventKey: quantity_key(event)
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: market_click(event.position)
		return
	if hangar and not inventory_open and not map_open and not help_open and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in range(5):
			if market_button(i).has_point(event.position):
				if i == 2:
					inventory_open = true
					return
				if i == 3:
					unload_cargo()
					return
				if i == 4:
					launch()
					return
				market = i+1
				quantity_row = -1
				market_status = ""
				return
	if inventory_open:
		if event is InputEventMouseButton: equipment_input(event)
		return
	if event is InputEventKey and not event.echo:
		if not event.pressed:
			return
		if not hangar:
			var key := int(event.keycode)
			var slot_number := key-KEY_1 if key >= KEY_1 and key <= KEY_9 else key-KEY_KP_1
			var available := equipped_modes()
			if slot_number >= 0 and slot_number < available.size():
				mode = available[slot_number]
		match event.keycode:
			KEY_J:
				if not hangar and not trader.is_empty() and trader.hp > 0 and pos.distance_to(trader.p) <= 220:
					market = 3
					market_status = ""
					quantity_row = -1
			KEY_ENTER:
				launch()
			KEY_H:
				help_open = not help_open
			KEY_B:
				try_dock()
			KEY_T:
				cycle_target()
			KEY_Y:
				extra_target = {}
				selected_target = -1
				npc_target = {}
			KEY_O, KEY_L:
				if not hangar and mode == 2:
					power = clampi(power + (5 if event.keycode == KEY_O else -5),0,100)
			KEY_U:
				unload_cargo()
			KEY_P:
				if hangar: paint = (paint + 1) % PAINT.size()
			KEY_M:
				map_open = not map_open
				ftl_destination = -1
			KEY_G:
				cross_gate()
			KEY_N:
				if hangar: motor = not motor
			KEY_LEFT, KEY_RIGHT:
				if hangar: choose(posmod(selected + (1 if event.keycode == KEY_RIGHT else -1),ships.size()))
			KEY_TAB:
				if not hangar:
					ping = 0
					ping_origin = pos
			KEY_C:
				coupled = not coupled
			KEY_F5:
				save_game()
			KEY_F9:
				load_game()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and not hangar and not map_open and not help_open:
			click_target(event.position,event.double_click)
		if event.button_index == MOUSE_BUTTON_LEFT and hangar:
			for i in range(ships.size()):
				if slot(i).has_point(event.position): choose(i)
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var direction := 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1
			if not hangar:
				if mode == 2 and event.shift_pressed: power = clampi(power + direction * 5,0,100)
				else: zoom = clampf(zoom * pow(1.12,direction),.22,4.2)

func axis(negative: Key, positive: Key) -> int:
	return int(Input.is_key_pressed(positive)) - int(Input.is_key_pressed(negative))

func _physics_process(dt: float) -> void:
	queue_redraw()
	if map_open or market == 3 or console_open: return
	update_ftl(dt)
	repair_stations(dt)
	update_shields(dt)
	update_wrecks(dt)
	if player_destroying or ftl_depart_age >= 0 or ftl_arrival_age < 1: return
	if hangar:
		decay_mining(dt, -1)
		return
	update_asteroid_respawn(dt)
	angle += axis(KEY_Q,KEY_E) * deg_to_rad(maxf(23,159-stat(3))*(1.0+.1*module_count(7))) * dt
	var f := forward()
	var boost := 1.0+.1*module_count(6)
	var thrust := float(stat(1)) / stat(0) * (1.35 if motor else 1.0)*boost
	var main := 1.0 if Input.is_key_pressed(KEY_W) else (-.5 if Input.is_key_pressed(KEY_S) else 0.0)
	var applied := (f * main + f.rotated(PI/2) * axis(KEY_A,KEY_D) * .25) * thrust
	vel += applied*dt
	vel = vel.limit_length(maxf(95,345-stat(3)*1.62)*boost)
	var manual_brake := Input.is_key_pressed(KEY_X)
	var translating := Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_D)
	if manual_brake or (coupled and not translating):
		var braking := thrust*(1.35 if manual_brake else .65)
		if vel.length() > 0: applied -= vel.normalized()*braking
		vel = vel.move_toward(Vector2.ZERO,braking*dt)
	player_thrust = applied.length()
	if update_auto_dock(dt,Input.is_key_pressed(KEY_B)):
		if hangar: return
		f = forward()
	var previous := pos
	pos += vel * dt
	station_contact(previous)
	if hangar or player_destroying: return
	var limit := HALF - stat(3)*.32
	if absf(pos.x) > limit:
		pos.x = clampf(pos.x,-limit,limit)
		vel.x *= -.35
	if absf(pos.y) > limit:
		pos.y = clampf(pos.y,-limit,limit)
		vel.y *= -.35
	for rock in rocks:
		if rock.hp <= 0: continue
		var offset: Vector2 = pos - rock.p
		var radius: float = rock.r + stat(3)*.32
		if offset.length_squared() >= radius*radius: continue
		var normal := offset.normalized() if offset != Vector2.ZERO else Vector2.RIGHT
		pos = rock.p + normal*(radius+.1)
		var impact := -vel.dot(normal)
		if impact <= 0: continue
		vel += normal*impact*1.35
		if impact >= 14:
			player_damage(int(impact*.38))
			rock.hp = maxi(0,rock.hp-int(impact*stat(0)/200))
		if hp <= 0:
			destroyed()
			return
	if ping < 650:
		ping = minf(650,ping+830*dt)
		for rock in rocks:
			if rock.hp > 0 and rock.p.distance_to(ping_origin) <= ping+rock.r: rock.seen = true
		for npc in npcs:
			if npc.hp > 0 and npc.p.distance_to(ping_origin) <= ping+float(specs[npc.ship][3])*.32: npc.scanned = true
	cooldown = maxf(0, cooldown - dt)
	missile_cooldown = maxf(0, missile_cooldown - dt)
	if mode in [1,5] and has_module_for_mode() and Input.is_key_pressed(KEY_SPACE) and missile_cooldown <= 0:
		launch_ordnance(f)
	if mode == 0 and has_module_for_mode() and Input.is_key_pressed(KEY_SPACE) and cooldown <= 0:
		var count := module_count(0)
		for i in range(count):
			bullets.append({"p":pos+ship_mount(selected,"ametralladora",i,count).rotated(angle),"v":vel+f*920,"f":f,"life":.85})
		cooldown = .075
	for i in range(bullets.size()-1,-1,-1):
		var shot: Dictionary = bullets[i]
		var next: Vector2 = shot.p + shot.v*dt
		var hit := ray_rock(shot.p, next)
		var contact := ray_npc(shot.p,next,hit.y)
		var debris := ray_wreck(shot.p,next,contact.y)
		if debris.x >= 0:
			damage_wreck(int(debris.x))
		elif contact.x >= 0:
			npc_hit(npcs[int(contact.x)],24,true)
		elif hit.x >= 0:
			rocks[int(hit.x)].hp = maxi(0,rocks[int(hit.x)].hp-24)
		shot.p = next
		shot.life -= dt
		if shot.life <= 0 or hit.x >= 0 or contact.x >= 0 or debris.x >= 0: bullets.remove_at(i)
	update_mining(dt,f)
	decay_mining(dt, target)
	if selected_target >= 0 and rocks[selected_target].hp <= 0:
		selected_target = -1
	if not hangar and not player_destroying:
		update_freight(dt)
		update_traffic(dt)
		update_pdc(dt)
	if hangar or player_destroying: return
	var tractor := module_count(4) > 0
	if not extra_target.is_empty() and extra_target.kind in ["Restos","Recursos"]:
		var collection: Array = wreck_fields[sector] if extra_target.kind == "Restos" else fragments
		if collection.has(extra_target.data): extra_target.p = extra_target.data.p
		else: extra_target = {}
	elif not extra_target.is_empty() and extra_target.kind == "Módulo":
		var present := false
		for item in module_drops[sector]:
			if Vector2(item[0],item[1]) == extra_target.p and int(item[2]) == extra_target.module: present = true
		if not present: extra_target = {}
	var drops: Array = module_drops[sector]
	for i in range(drops.size()-1,-1,-1):
		var drop_item: Array = drops[i]
		if tractor:
			var pulled := pull_item(Vector2(drop_item[0],drop_item[1]),dt)
			drop_item[0] = pulled.x
			drop_item[1] = pulled.y
		if pos.distance_to(Vector2(drop_item[0],drop_item[1])) <= stat(3)*.32+20 and store_module(int(drop_item[2])):
			status = "Módulo recogido: "+MODULE_NAMES[int(drop_item[2])]
			drops.remove_at(i)
	if not npc_target.is_empty() and (npc_target.hp <= 0 or not npcs.has(npc_target)): npc_target = {}
	for i in range(fragments.size()-1,-1,-1):
		var item: Dictionary = fragments[i]
		if tractor: item.p = pull_item(item.p,dt)
		if pos.distance_to(item.p) <= stat(3)*.32+16 and used()+item.amount <= stat(4):
			cargo[item.resource] += item.amount
			status = "%s: %d U en bodega" % [RES[item.resource],cargo[item.resource]]
			fragments.remove_at(i)

func _process(_dt: float) -> void:
	missile_layer.position = get_viewport_rect().size / 2 - pos * zoom
	missile_layer.scale = Vector2.ONE * zoom

func launch_ordnance(forward_axis: Vector2) -> void:
	var guided := mode == 5
	if guided and selected_target < 0 and npc_target.is_empty():
		status = "Selecciona un objetivo con T para lanzar un misil"
		return
	var count := module_count(5 if guided else 1)*maxi(1,int(ship_trait("double_ordnance","multiplicador_salva",1)))
	for i in range(count):
		var missile := MISSILE.instantiate()
		var mount := ship_mount(selected,"misil" if guided else "cohete",i,count)
		var side := signf(mount.x) if absf(mount.x) > .001 else (1.0 if i % 2 == 0 else -1.0)
		missile.sector = self
		missile.position = pos+mount.rotated(angle)
		missile.direction = forward_axis.rotated(side*PI/2) if guided else forward_axis
		missile.rotation = missile.direction.angle()+PI/2
		missile.drift = vel
		missile.guided = guided
		if guided:
			missile.npc = npc_target
			if selected_target >= 0: missile.rock = rocks[selected_target]
		missile_layer.add_child(missile)
	missile_cooldown = 1.4 if guided else .85

func clear_missiles() -> void:
	for missile in missile_layer.get_children():
		missile_layer.remove_child(missile)
		missile.queue_free()
	missile_cooldown = 0

func missile_impact(at: Vector2, direct: int, damage: int, radius: float, direct_npc: int = -1) -> void:
	for i in range(npcs.size()):
		var npc := npcs[i]
		var distance := maxf(0,at.distance_to(npc.p)-int(specs[npc.ship][3])*.32)
		var amount := damage if i == direct_npc else roundi(damage*.5*maxf(0,1-distance/radius))
		npc_hit(npc,amount,true)
	for i in range(rocks.size()):
		var rock: Dictionary = rocks[i]
		if rock.hp <= 0: continue
		var distance := maxf(0, at.distance_to(rock.p) - rock.r)
		if distance >= radius and i != direct: continue
		var amount := damage if i == direct else roundi(damage * .5 * (1 - distance / radius))
		rock.hp = maxi(0, rock.hp - amount)

func destroyed() -> void:
	if player_destroying: return
	player_destroying = true
	vel = Vector2.ZERO
	bullets.clear()
	cooldown = 0.0
	clear_missiles()
	wreck_ship(pos,selected,true,angle)
	status = "Nave destruida"

func ray_rock(start: Vector2, end: Vector2) -> Vector2:
	var result := Vector2(-1,1)
	for i in range(rocks.size()):
		var rock: Dictionary = rocks[i]
		if rock.hp <= 0: continue
		var hit: Variant = Geometry2D.segment_intersects_circle(start,end,rock.p,rock.r)
		if start.distance_squared_to(rock.p) <= rock.r*rock.r: hit = 0.0
		if hit >= 0 and hit <= result.y: result = Vector2(i,hit)
	return result

func window_center(rock: Dictionary) -> float:
	return clampf(rock.ideal+.15*sin(mining_time*1.8),.15,.86)

func decay_mining(dt: float, active: int) -> void:
	for i in range(rocks.size()):
		if i != active and rocks[i].progress > 0:
			rocks[i].progress = maxf(0,rocks[i].progress-dt*.10)

func mining_margin(hits: int) -> float:
	return .10+.035*maxi(0,hits-1)

func update_mining(dt: float, f: Vector2) -> void:
	target = -1
	mining_rays.clear()
	if mode != 2 or not has_module_for_mode() or not Input.is_key_pressed(KEY_SPACE): return
	mining_time += dt
	var nose := pos+f*stat(3)/2.0
	var reach := stat(3)*maxf(0,ship_trait("long_miner","multiplicador_alcance",1))
	var end := nose+mining_aim(nose,f,reach)*reach
	var count := module_count(2)
	var hits := 0
	for i in range(count):
		var start := pos+ship_mount(selected,"mineria",i,count).rotated(angle)
		var hit := ray_rock(start,end)
		mining_rays.append([start,start.lerp(end,hit.y)])
		if hit.x >= 0:
			if target < 0: target = int(hit.x)
			if int(hit.x) == target: hits += 1
	mining_hits = hits
	if target < 0: return
	var rock: Dictionary = rocks[target]
	if power == 100:
		drop(rock,1)
		player_damage(ceili(stat(2)*.25))
		status = "Sobrecarga: 10% recuperable"
		if hp <= 0: destroyed()
	elif absf(power/100.0-window_center(rock)) <= mining_margin(hits):
		rock.progress += dt/3
		if rock.progress >= 1:
			drop(rock,10)
			status = "Extracción completa"
	else:
		rock.progress = maxf(0,rock.progress-dt*.25)

func asteroid_size(radius: int) -> int:
	return clampi(floori((radius - 12) / 7.0), 0, 4)

func drop(rock: Dictionary, amount: int) -> void:
	rock.mined = true
	rock.hp = 0
	target = -1
	var count := 2 + asteroid_size(rock.r) * 2
	for i in range(count):
		fragments.append({"p":rock.p+Vector2.RIGHT.rotated(i*TAU/count)*rock.r*.65,
			"resource":rock.second if rock.second >= 0 and i%2 == 1 else rock.first,"amount":amount})

var respawn_clock := 0.0

func respawn_position(field: Array, field_index: int, rock: Dictionary) -> Vector2:
	for attempt in range(32):
		var candidate := Vector2(randf_range(-4850,4850),randf_range(-4850,4850))
		if candidate.length() < 300 or (sector == field_index and candidate.distance_to(pos) < 180): continue
		var blocked := false
		for edge in range(links.size()):
			if field_index in [links[edge].x,links[edge].y] and candidate.distance_to(gate_position(edge,field_index)) < 140:
				blocked = true
				break
		if blocked: continue
		for other in field:
			if (other.hp > 0 or float(other.get("fade",-1)) >= 0) and candidate.distance_to(other.p) < rock.r+other.r+12:
				blocked = true
				break
		if not blocked: return candidate
	return Vector2.INF

func update_asteroid_respawn(dt: float) -> void:
	for field in fields:
		for rock in field:
			if not rock.has("fade"): continue
			rock.fade += dt
			if rock.fade >= 10:
				rock.erase("fade")
				rock.hp = ROCK_HP
	respawn_clock += dt
	if respawn_clock < 300: return
	respawn_clock = fmod(respawn_clock,300)
	for index in range(fields.size()):
		var field: Array = fields[index]
		var eligible: Array = []
		for rock in field:
			if rock.hp == 0 and rock.get("mined",false) and not rock.has("fade"): eligible.append(rock)
		eligible.shuffle()
		for i in range(ceili(eligible.size()*.25)):
			var rock: Dictionary = eligible[i]
			var candidate := respawn_position(field,index,rock)
			if candidate == Vector2.INF: continue
			rock.p = candidate
			rock.seen = false
			rock.progress = 0.0
			rock.mined = false
			rock.fade = 0.0

func load_quantities(values: Variant, target_values: Array[int]) -> void:
	target_values.fill(1)
	if not values is Array: return
	for i in range(mini(values.size(),target_values.size())):
		target_values[i] = clampi(int(values[i]),0,9999)

func save_game() -> void:
	var path := save_path()
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK:
		status = "Error al crear la carpeta savegames"
		return
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		status = "Error al guardar"
		return
	var all_fields: Array = []
	var all_loot: Array = []
	var saved_wrecks: Array = []
	for i in range(fields.size()):
		var field: Array = []
		for rock in fields[i]: field.append([rock.hp,rock.seen,rock.progress,rock.p.x,rock.p.y,rock.get("mined",false),rock.get("fade",-1)])
		all_fields.append(field)
		var loot: Array = []
		for item in sector_loot[i]: loot.append([item.p.x,item.p.y,item.resource,item.amount])
		all_loot.append(loot)
		var wrecks: Array = []
		for item in wreck_fields[i]: wrecks.append([item.p.x,item.p.y,item.sprite,item.angle,item.progress,item.get("hits",0)])
		saved_wrecks.append(wrecks)
	file.store_string(JSON.stringify({"extra_stations":stations.slice(2).map(func(station: Dictionary) -> Dictionary: return {"hp":station.hp,"discovered":station.discovered,"reserve":station.reserve,"stock":station.stock,"modules":station.modules}),"ftl_cooldown":ftl_cooldown,"shields":shield_states,"ship":selected,"paint":paint,"mode":mode,"motor":motor,"coupled":coupled,"hangar":hangar,"dock_station":dock_station,"dock_port":dock_port,"station_discovered":station_discovered,"nacar_discovered":nacar_discovered,"nacar_hp":stations[1].hp,"nacar_reserve":nacar_reserve,"nacar_stock":nacar_stock,"nacar_modules":nacar_modules,"freight":freight,"station_hp":stations[0].hp,"station_reserve":station_reserve,"module_locations":module_locations,"module_types":module_types,"credits":credits,"mineral_quantities":mineral_quantities,"object_quantities":object_quantities,"respawn_clock":respawn_clock,"mineral_stock":mineral_stock,"module_stock":module_stock,"module_drops":module_drops,
		"x":pos.x,"y":pos.y,"vx":vel.x,"vy":vel.y,"angle":angle,"hp":hp,"cargo":cargo,"inventory":inventory,"field":all_fields[sector],"loot":all_loot[sector],"sector":sector,"crossed":crossed,"fields":all_fields,"sector_loot":all_loot,"wrecks":saved_wrecks}))
	status = "Partida guardada"

func load_game() -> void:
	var path := save_path()
	if not FileAccess.file_exists(path):
		path = LEGACY_SAVE
	if not FileAccess.file_exists(path):
		status = "Todavía no hay partida guardada"
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not data.has("field") or data.field.size() != rocks.size():
		status = "Partida inválida"
		return
	selected = int(data.ship)
	paint = int(data.paint)
	mode = int(data.mode)
	motor = data.motor
	coupled = bool(data.get("coupled",true))
	hangar = data.hangar
	pos = Vector2(data.x,data.y)
	vel = Vector2(data.vx,data.vy)
	angle = data.angle
	hp = int(data.hp)
	cargo = data.cargo
	load_modules(data.get("module_locations",[]),data.get("module_types",[0,1,2,3]))
	load_shields(data.get("shields",[]))
	ftl_cooldown = clampf(float(data.get("ftl_cooldown",0)),0,300)
	ftl_destination = -1
	ftl_depart_age = -1.0
	ftl_arrival_age = 1.0
	ftl_exits.clear()
	load_quantities(data.get("mineral_quantities",[]),mineral_quantities)
	load_quantities(data.get("object_quantities",[]),object_quantities)
	respawn_clock = clampf(float(data.get("respawn_clock",0)),0,300)
	credits = maxi(0,int(data.get("credits",500)))
	mineral_stock.assign(data.get("mineral_stock",[20,20,20,20,20,20,20,20,20,20]))
	if not data.has("mineral_stock"): mineral_stock[2] += maxi(0,int(data.get("station_reserve",0)))
	module_stock.assign(data.get("module_stock",[2,2,2,2,2]))
	while module_stock.size() < MODULE_NAMES.size(): module_stock.append(2)
	module_drops = data.get("module_drops",[[],[],[],[],[]])
	var stored: Variant = data.get("inventory", [])
	for i in range(RES.size()):
		inventory[i] = maxi(0, int(stored[i])) if stored is Array and stored.size() == RES.size() else 0
	sector = clampi(int(data.get("sector",0)),0,4)
	crossed = clampi(int(data.get("crossed",0)),0,(1<<links.size())-1)
	for index in range(5):
		fields[index] = generate_field(index)
		sector_loot[index] = []
		wreck_fields[index] = []
		if data.has("wrecks"):
			for item in data.wrecks[index]:
				wreck_fields[index].append({"p":Vector2(item[0],item[1]),"sprite":int(item[2]),"angle":item[3],"progress":item[4],"hits":int(item[5]) if item.size() > 5 else 0})
		var saved_field: Array = data.fields[index] if data.has("fields") else (data.field if index == sector else [])
		var loot: Array = data.sector_loot[index] if data.has("sector_loot") else (data.loot if index == sector else [])
		if saved_field.size() == fields[index].size():
			for i in range(saved_field.size()):
				fields[index][i].hp = int(saved_field[i][0])
				fields[index][i].seen = saved_field[i][1]
				fields[index][i].progress = saved_field[i][2]
				if saved_field[i].size() >= 7:
					fields[index][i].p = Vector2(saved_field[i][3],saved_field[i][4])
					fields[index][i].mined = saved_field[i][5]
					if float(saved_field[i][6]) >= 0: fields[index][i].fade = float(saved_field[i][6])
		for item in loot:
			sector_loot[index].append({"p":Vector2(item[0],item[1]),"resource":int(item[2]),"amount":int(item[3])})
	rocks = fields[sector]
	fragments = sector_loot[sector]
	bullets.clear()
	cooldown = 0.0
	clear_missiles()
	ping = 1000
	target = -1
	mining_rays.clear()
	selected_target = -1
	for station in stations:
		station.repair_delay = 0.0
		station.repair_fraction = 0.0
	stations[0].hp = clampi(int(data.get("station_hp",26000)),1,26000)
	nacar_discovered = bool(data.get("nacar_discovered",false))
	stations[1].hp = clampi(int(data.get("nacar_hp",25000)),1,25000)
	nacar_reserve = maxi(0,int(data.get("nacar_reserve",0)))
	nacar_stock.assign(data.get("nacar_stock",[20,20,20,20,20,20,20,20,20,20]))
	nacar_modules.assign(data.get("nacar_modules",[2,2,2,2,2,2,2,2,2,2,2]))
	while nacar_modules.size() < MODULE_NAMES.size(): nacar_modules.append(2)
	freight = data.get("freight",{})
	station_discovered = bool(data.get("station_discovered",false))
	station_reserve = maxi(0,int(data.get("station_reserve",0)))
	if hangar:
		var saved_dock := int(data.get("dock_station",-1))
		if saved_dock >= 0 and saved_dock < stations.size() and stations[saved_dock].sector == sector:
			dock_at(saved_dock,int(data.get("dock_port",0)))
		else:
			rescue_dock()
	reset_traffic()
	explosions.clear()
	player_destroying = false
	salvage_target = -1
	salvage_rays.clear()
	for index in range(2,stations.size()):
		stations[index].hp = stations[index].max_hp
		stations[index].discovered = false
		stations[index].reserve = 0
		stations[index].stock = [20,20,20,20,20,20,20,20,20,20]
		stations[index].modules = new_station_modules()
		var extra: Array = data.get("extra_stations",[])
		if index-2 >= extra.size(): continue
		var saved: Dictionary = extra[index-2]
		stations[index].hp = clampi(int(saved.get("hp",stations[index].max_hp)),1,stations[index].max_hp)
		stations[index].discovered = bool(saved.get("discovered",false))
		stations[index].reserve = maxi(0,int(saved.get("reserve",0)))
		var stock: Array = saved.get("stock",[])
		if stock.size() == RES.size(): stations[index].stock = stock
		var modules: Array = saved.get("modules",[])
		for slot_index in range(mini(modules.size(),MODULE_NAMES.size())):
			stations[index].modules[slot_index] = maxi(0,int(modules[slot_index]))
	clear_station_approaches()
	status = "Partida cargada"
	normalize_weapon()


func label(at: Vector2, value: String, size: int = 17, color: Color = Color.WHITE) -> void:
	draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func slot(i: int) -> Rect2:
	var columns := ceili(ships.size()/2.0)
	var width := (get_viewport_rect().size.x-40)/columns
	return Rect2(20+(i%columns)*width,get_viewport_rect().size.y-124+(i/columns)*44,width-4,40)

var shield_states: Array[Dictionary] = []
var shield_art: Array[Texture2D] = []
var shield_break_art: Array[Texture2D] = []
var target_title_font := SystemFont.new()
var target_body_font := SystemFont.new()

func player_shield() -> Dictionary:
	while shield_states.size() < SHIP_COUNT: shield_states.append({"value":-1.0,"delay":0.0,"flash":0.0,"break_flash":0.0,"lock":0.0})
	var state := shield_states[selected]
	var maximum := float(stat(2))*.5*module_count(9)
	if state.lock > 0: state.value = 0.0
	if maximum > 0 and state.value < 0: state.value = maximum
	if maximum > 0: state.value = minf(state.value,maximum)
	return state

func shield_damage(state: Dictionary, maximum: float, amount: int) -> int:
	if amount <= 0: return 0
	state.delay = 10.0
	var absorbed := minf(maxf(0,state.value),float(amount)) if maximum > 0 else 0.0
	if absorbed > 0:
		state.value -= absorbed
		state.flash = .6
		if state.value <= 0: state.break_flash = .28
	return ceili(amount-absorbed)

func player_damage(amount: int) -> void:
	hp = maxi(0,hp-shield_damage(player_shield(),float(stat(2))*.5*module_count(9),amount))

func recharge_shield(state: Dictionary, maximum: float, dt: float) -> void:
	var lock_time: float = state.lock
	state.lock = maxf(0,lock_time-dt)
	state.flash = maxf(0,state.flash-dt)
	state.break_flash = maxf(0,state.break_flash-dt)
	var wait: float = state.delay
	state.delay = maxf(0,wait-dt)
	if maximum > 0:
		if lock_time > 0: state.value = 0.0
		state.value = minf(maximum,maxf(0,state.value)+maxf(0,dt-maxf(wait,lock_time))*maximum/120.0)

func update_shields(dt: float) -> void:
	recharge_shield(player_shield(),float(stat(2))*.5*module_count(9),dt)
	for npc in npcs:
		if npc.hp > 0: recharge_shield(npc.shield_state,float(specs[npc.ship][2])*.5 if npc.shield else 0.0,dt)

func shield_sprite(ship: int, at: Vector2, height: float, flash: float, break_flash: float = 0.0) -> void:
	if flash <= 0 and break_flash <= 0: return
	while shield_art.size() < SHIP_COUNT:
		shield_art.append(null)
		shield_break_art.append(null)
	if shield_art[ship] == null:
		var mask := ships[ship].get_image()
		var h := int(specs[ship][3])
		var w := maxi(1,roundi(h*float(mask.get_width())/mask.get_height()))
		mask.resize(w,h,Image.INTERPOLATE_LANCZOS)
		var image := Image.create(w,h,false,Image.FORMAT_RGBA8)
		for y in range(h):
			for x in range(w):
				if mask.get_pixel(x,y).a < .1: continue
				var edge := false
				for offset in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]:
					var point: Vector2i = Vector2i(x,y)+offset
					if point.x < 0 or point.y < 0 or point.x >= w or point.y >= h or mask.get_pixel(point.x,point.y).a < .1: edge = true
				image.set_pixel(x,y,Color(43.0/255,251.0/255,245.0/255,1.0 if edge else .6))
		shield_art[ship] = ImageTexture.create_from_image(image)
		for y in range(h):
			for x in range(w):
				var color := image.get_pixel(x,y)
				image.set_pixel(x,y,Color(1,1,1,color.a))
		shield_break_art[ship] = ImageTexture.create_from_image(image)
	var texture := shield_art[ship]
	var size := Vector2(height*texture.get_width()/texture.get_height(),height)
	draw_texture_rect(texture,Rect2(at-size*.5,size),false,Color(1,1,1,minf(1,flash/.12)))
	if break_flash > 0:
		var intensity := minf(1,break_flash/.07)*(.5+.5*absf(sin(break_flash*35)))
		draw_texture_rect(shield_break_art[ship],Rect2(at-size*.5,size),false,Color(1,1,1,intensity))

func load_shields(values: Variant) -> void:
	shield_states.clear()
	for i in range(SHIP_COUNT):
		var state := {"value":-1.0,"delay":0.0,"flash":0.0,"break_flash":0.0,"lock":0.0}
		if values is Array and i < values.size() and values[i] is Dictionary:
			state.value = clampf(float(values[i].get("value",-1)),-1,float(specs[i][2])*2)
			state.delay = clampf(float(values[i].get("delay",0)),0,10)
			state.lock = clampf(float(values[i].get("lock",0)),0,60)
		shield_states.append(state)

func sprite(i: int, at: Vector2, height: float, tint: Color) -> void:
	var size := Vector2(height*ships[i].get_width()/ships[i].get_height(),height)
	draw_texture_rect(ships[i],Rect2(at-size/2,size),false,tint)

const SLOT_NAMES := ["Armamento","Defensa","Utilidad","Motores"]
const SLOT_COLORS := [Color.SALMON,Color.SKY_BLUE,Color.TURQUOISE,Color.KHAKI]
const HELP_GROUPS := [
	["VUELO", "Enter  Despegar", "B  Atracar", "W/S  Empuje longitudinal", "A/D  Empuje lateral", "Q/E  Girar", "X  Frenar", "C  Coupled / Decoupled", "Rueda  Zoom"],
	["INTERACCIÓN", "Tab  Escanear", "T / clic  Seleccionar objetivo", "Y  Quitar objetivo", "1–5  Módulos equipados", "Espacio  Usar módulo", "Minería: Mayús + rueda u O/L"],
	["HANGAR Y MAPA", "Inventario: botón del hangar", "Clic/flechas  Elegir nave", "P  Pintura   N  Motor", "U  Descargar bodega", "M  Mapa   G  Saltar","J  Comerciar con trader", "F5  Guardar   F9  Cargar", "H / Esc  Cerrar ayuda"]
]

func draw_menu_panel(center: Vector2, dimensions: Vector2, title: String, hint: String) -> Vector2:
	var panel := Rect2(center-dimensions/2,dimensions)
	draw_rect(panel,Color("#111b32"))
	draw_rect(panel,Color.TURQUOISE,false)
	draw_string(ThemeDB.fallback_font,panel.position+Vector2(0,34),title,HORIZONTAL_ALIGNMENT_CENTER,dimensions.x,23,Color.TURQUOISE)
	label(panel.position+Vector2(18,dimensions.y-13),hint,13,Color.LIGHT_SLATE_GRAY)
	return panel.position

const MODULE_NAMES := ["Ametralladora","Cohete","Equipo de minería","Equipo de salvaging","Tractor beam Tier0","Misil guiado","Thrusters","Gyro","PDC","Escudo","FTL"]
const MODULE_ICONS := ["AM","CO","MN","SV","TB","MI","TH","GY","PD","ES","FTL"]
const MODULE_DETAILS := [
	["Dispara ráfagas de trazadoras.","Modo: Armamento"],
	["Dispara un cohete explosivo.","Modo: Cohetes"],
	["Extrae mineral de asteroides.","Modo: Minería"],
	["Recupera metal de restos.","Modo: Salvaging"],
	["Atrae mineral y módulos.","Radio: 1,25 × longitud"],
	["Sigue al objetivo fijado con T.","Sale de lado y acelera en vuelo."],
	["+10 % de empuje, velocidad y frenada."],
	["+10 % de velocidad de giro."],
	["Defensa en ráfagas de tres tiros."],
	["+50 % del casco como escudo por módulo.","Regenera tras 10 s sin recibir daño."],
	["Salto de hasta 3 enlaces desde el mapa.","Recarga 300 s · escudo bloqueado 60 s."]
]
const MODULE_MODES := [0,1,2,4,-1,5]
const EQUIPMENT_SIZE := Vector2(900,406)
const EQUIPMENT_CELL := 38.4
const EQUIPMENT_GRID := Vector2(338,70)
const EQUIPMENT_SPAN := EQUIPMENT_CELL*8
const EQUIPPED_START := 64
const WEAPON_SLOT_STRIDE := 5
const UTILITY_START := 256
const UTILITY_STRIDE := 3
var module_locations: Array[int] = [0,1,2,3]
var dragged_module := -1

func weapon_location(slot_index: int, ship_index: int) -> int:
	return EQUIPPED_START+ship_index*WEAPON_SLOT_STRIDE+slot_index

func utility_location(slot_index: int, ship_index: int) -> int:
	return UTILITY_START+ship_index*UTILITY_STRIDE+slot_index

const CATEGORY_START := [64,352,256,448]
const CATEGORY_STRIDE := [5,4,3,4]
const MODULE_CATEGORY := [0,0,0,0,2,0,3,3,1,1,2]
const MODULE_TEXTURES := [
	preload("res://environment/modules/ametralladora.png"),preload("res://environment/modules/cohete.png"),
	preload("res://environment/modules/mineria.png"),preload("res://environment/modules/salvaging.png"),
	preload("res://environment/modules/tractor.png"),preload("res://environment/modules/misil.png"),
	preload("res://environment/modules/thrusters.png"),preload("res://environment/modules/gyro.png"),preload("res://environment/modules/pdc.png"),preload("res://environment/modules/shield.svg"),preload("res://environment/modules/ftl.svg")]
const MODULE_WORLD := [
	preload("res://environment/modules/thrusters-world.png"),preload("res://environment/modules/gyro-world.png"),
	preload("res://environment/modules/pdc-world.png")]

# Defense IDs for the original 24 ships remain valid in existing saves.
const EXTRA_DEFENSE_START := 576
const ORIGINAL_DEFENSE_SHIPS := 24

func slot_location(category: int, ship: int, index: int) -> int:
	if category == 1 and ship >= ORIGINAL_DEFENSE_SHIPS:
		return EXTRA_DEFENSE_START+(ship-ORIGINAL_DEFENSE_SHIPS)*CATEGORY_STRIDE[1]+index
	return CATEGORY_START[category]+ship*CATEGORY_STRIDE[category]+index

func location_category(location: int) -> int:
	if location >= EXTRA_DEFENSE_START: return 1
	if location >= 448: return 3
	if location >= 352: return 1
	if location >= 256: return 2
	return 0

func equipped_slot(location: int, category: int) -> int:
	var index := location-slot_location(category,selected,0)
	return index if index >= 0 and index < stat(5+category) else -1

func module_count(kind: int) -> int:
	var count := 0
	for i in range(module_locations.size()):
		if module_types[i] == kind and equipped_slot(module_locations[i],MODULE_CATEGORY[kind]) >= 0: count += 1
	return count

func auto_equip(item: int) -> void:
	if item < 0 or module_locations[item] >= EQUIPPED_START: return
	var category: int = MODULE_CATEGORY[module_types[item]]
	for slot in range(stat(5+category)):
		var location := slot_location(category,selected,slot)
		if not module_locations.has(location):
			module_locations[item] = location
			return
	status = "No hay una ranura compatible libre"

func equipped_modes() -> Array[int]:
	var available: Array[int] = []
	for kind in [0,1,5,2,3]:
		if module_count(kind) > 0: available.append(MODULE_MODES[kind])
	return available

func weapon_keys() -> String:
	var available := equipped_modes()
	var labels := PackedStringArray()
	for i in range(available.size()):
		labels.append("%d %s" % [i+1,MODES[available[i]]])
	return " · ".join(labels)

func has_module_for_mode() -> bool:
	var kind := MODULE_MODES.find(mode)
	return kind >= 0 and module_count(kind) > 0

func module_fits(kind: int, location: int) -> bool:
	return location < EQUIPPED_START or MODULE_CATEGORY[kind] == location_category(location)

func pull_item(at: Vector2, dt: float) -> Vector2:
	if at.distance_to(pos) <= stat(3)*1.25:
		return at.move_toward(pos,180*dt)
	return at

func equipment_slot(at: Vector2, category: int, index: int) -> Rect2:
	var count := stat(5+category)
	return Rect2(at+Vector2(205-(count-1)*13+index*26-10,105+category*49),Vector2(21,21))

func equipment_location(pointer: Vector2) -> int:
	var at := (get_viewport_rect().size-EQUIPMENT_SIZE)/2
	var grid := Rect2(at+EQUIPMENT_GRID,Vector2.ONE*EQUIPMENT_SPAN)
	if grid.has_point(pointer):
		var cell := Vector2i((pointer-grid.position)/EQUIPMENT_CELL)
		return cell.y*8+cell.x
	for category in range(SLOT_NAMES.size()):
		for i in range(stat(5+category)):
			if equipment_slot(at,category,i).has_point(pointer): return slot_location(category,selected,i)
	return -1

func equipment_input(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT: return
	var destination := equipment_location(event.position)
	if event.pressed:
		var at := (get_viewport_rect().size-EQUIPMENT_SIZE)/2
		if Rect2(at+Vector2(765,10),Vector2(110,34)).has_point(event.position):
			inventory_open = false
			dragged_module = -1
			return
		if Rect2(at+Vector2(677,248),Vector2(197,38)).has_point(event.position):
			unequip_all()
			return
		dragged_module = module_locations.find(destination) if destination >= 0 else -1
		if event.double_click:
			auto_equip(dragged_module)
			dragged_module = -1
	elif dragged_module >= 0:
		if destination >= 0 and module_fits(module_types[dragged_module],destination):
			var other := module_locations.find(destination)
			var origin := module_locations[dragged_module]
			if other < 0 or module_fits(module_types[other],origin):
				if other >= 0: module_locations[other] = origin
				module_locations[dragged_module] = destination
		dragged_module = -1

func load_modules(saved: Variant, kinds: Variant = [0,1,2,3]) -> void:
	module_locations.assign([0,1,2,3])
	module_types.assign([0,1,2,3])
	if not saved is Array or not kinds is Array or saved.size() != kinds.size(): return
	var validated: Array[int] = []
	var validated_types: Array[int] = []
	for i in range(saved.size()):
		var value: Variant = saved[i]
		var kind := int(kinds[i])
		if kind < 0 or kind >= MODULE_NAMES.size(): return
		validated_types.append(kind)
		if not (value is int or value is float): return
		var location := int(value)
		if location < 0 or validated.has(location): return
		if location >= EQUIPPED_START:
			if not module_fits(kind,location): return
			var category := location_category(location)
			var local: int = location-CATEGORY_START[category]
			var stride: int = CATEGORY_STRIDE[category]
			var ship := local/stride
			if location >= EXTRA_DEFENSE_START:
				local = location-EXTRA_DEFENSE_START
				ship = ORIGINAL_DEFENSE_SHIPS+local/stride
			if ship >= specs.size() or local%stride >= int(specs[ship][5+category]): return
		validated.append(location)
	module_locations.assign(validated)
	module_types.assign(validated_types)

const PDC_BASE := preload("res://environment/modules/pdc-base.png")
const PDC_BARRELS := preload("res://environment/modules/pdc-barrels.png")
const PDC_PIVOT := Vector2(15.0/34.0,13.0/31.0)*16.0
var pdc_states := {}
var player_pdc_attacker: Dictionary = {}
var player_pdc_until := 0.0
var pdc_sector := -1

func update_pdc(dt: float) -> void:
	if pdc_sector != sector:
		pdc_states.clear()
		player_pdc_attacker = {}
		pdc_sector = sector
	var active := {}
	var player_attacker := player_pdc_attacker if traffic_time < player_pdc_until else {}
	for i in range(module_count(8)):
		tick_pdc(active,"player%d"%i,pos+ship_mount(selected,"pdc",i,module_count(8)).rotated(angle)*.6,pos,player_attacker,false,true,dt,angle)
	for index in range(stations.size()):
		var station: Dictionary = stations[index]
		if station.sector != sector: continue
		var attacker: Dictionary = station.get("pdc_attacker",{}) if traffic_time < station.get("pdc_until",0.0) else {}
		for i in range(4):
			var mount: Dictionary = station.defense_mounts.get(i,{})
			var offset: Vector2 = mount.get("offset",port_axis(i*2)*station.size*.43)
			tick_pdc(active,"station%d/%d"%[index,i],station.p+offset,station.p,attacker,false,false,dt,float(mount.get("angle",0.0)))
	for npc in npcs:
		if npc.hp <= 0 or not npc.get("pdc",false): continue
		var alerted: bool = traffic_time < npc.get("pdc_until",0.0)
		var attacker: Dictionary = npc.get("pdc_attacker",{}) if alerted else {}
		tick_pdc(active,str(npc.pdc_id),npc.p,npc.p,attacker,alerted and npc.get("pdc_player",false),false,dt,npc.angle,npc)
	pdc_states = active

func tick_pdc(active: Dictionary, key: String, origin: Vector2, owner: Vector2, attacker: Dictionary, attack_player: bool, player_owned: bool, dt: float, mount_angle: float = 0.0, defender: Dictionary = {}) -> void:
	var state: Dictionary = pdc_states.get(key,{"timer":0.0,"left":0,"angle":-PI/4,"trace":0.0,"end":origin})
	state.origin = origin
	state.mount_angle = mount_angle
	state.timer -= dt
	state.trace -= dt
	active[key] = state
	var projectile: Node2D = null
	var nearest := 245.0
	for shot in missile_layer.get_children():
		if shot.blast >= 0 or shot.hostile != player_owned: continue
		var distance: float = origin.distance_to(shot.position)
		if distance >= nearest: continue
		if Geometry2D.segment_intersects_circle(shot.position,shot.position+shot.direction*650,owner,32.0 if origin == owner else origin.distance_to(owner)+16.0) < 0: continue
		if ray_rock(origin,shot.position).x >= 0: continue
		nearest = distance
		projectile = shot
	var aim := origin
	if projectile != null: aim = projectile.position
	elif attack_player: aim = pos
	elif not attacker.is_empty() and attacker.hp > 0 and npcs.has(attacker): aim = attacker.p
	if aim == origin or origin.distance_to(aim) > 245 or (projectile == null and ray_rock(origin,aim).x >= 0):
		state.left = 0
		return
	var local_aim := (aim-origin).angle()-mount_angle
	state.angle = rotate_toward(state.angle,local_aim,12*dt)
	if state.timer > 0 or absf(angle_difference(state.angle,local_aim)) > .2: return
	if state.left == 0: state.left = 3
	state.left -= 1
	state.timer = .085 if state.left > 0 else .75
	state.trace = .055
	state.end = aim
	if projectile != null:
		projectile.pdc_hits += 1
		if projectile.pdc_hits >= 2: projectile.blast = .25
	elif attack_player:
		player_damage(4)
		if hp == 0: destroyed()
	else: npc_hit(attacker,4,player_owned,defender)

func draw_pdc_world(world_origin: Vector2) -> void:
	for key in pdc_states:
		var state: Dictionary = pdc_states[key]
		var origin: Vector2 = state.origin
		if str(key).begins_with("player"):
			origin += ftl_offset(ftl_depart_age,angle,true) if ftl_depart_age >= 0 else ftl_offset(ftl_arrival_age,angle)
		var mount_angle: float = state.mount_angle
		var pivot := PDC_PIVOT-Vector2(8,8)
		var at := world_origin+origin*zoom
		draw_set_transform(at,mount_angle,Vector2.ONE*zoom)
		draw_texture_rect(PDC_BASE,Rect2(-8,-8,16,16),false)
		draw_circle(pivot,2.5,Color("#34383a"))
		draw_set_transform(at+pivot.rotated(mount_angle)*zoom,mount_angle+state.angle+PI/4,Vector2.ONE*zoom)
		draw_texture_rect(PDC_BARRELS,Rect2(-PDC_PIVOT,Vector2(16,16)),false)
		draw_set_transform(world_origin,0,Vector2.ONE*zoom)
		if state.trace > 0:
			var f := Vector2.from_angle(state.angle+mount_angle)
			draw_line(origin+f*7,origin+f*minf(85,origin.distance_to(state.end)),Color.LIGHT_YELLOW,1.5)

func module_icon(at: Vector2, item: int, size: float = 18) -> void:
	if item < MODULE_TEXTURES.size():
		draw_texture_rect(MODULE_TEXTURES[item],Rect2(at-Vector2.ONE*size*.5,Vector2.ONE*size),false)
		return
	draw_rect(Rect2(at-Vector2(10,9),Vector2(20,18)),Color("#203f4d"))
	label(at+Vector2(-8,5),MODULE_ICONS[item],11,Color.PALE_GREEN)

const MINERAL_PRICES := [5,7,8,12,20,10,14,9,15,25]
const MODULE_PRICES := [120,180,150,150,220,320,240,200,360,300,5000]
var credits := 500
const NACAR_PRICES := [3,2,22,6,46,25,8,23,8,54]
var nacar_stock: Array[int] = [20,20,20,20,20,20,20,20,20,20]
var nacar_reserve := 0
var trader_stock: Array[int] = [5,5,5,5,5,5,5,5,5,5]
var mineral_stock: Array[int] = [20,20,20,20,20,20,20,20,20,20]
var nacar_modules: Array[int] = [2,2,2,2,2,2,2,2,2,2,2]
var module_stock: Array[int] = [2,2,2,2,2,2,2,2,2,2,2]
var module_types: Array[int] = [0,1,2,3]
var module_drops: Array = [[],[],[],[],[]]
var market := 0
var market_status := ""
const MARKET_SIZE := Vector2(790,520)

func free_module_cell() -> int:
	for cell in range(64):
		if not module_locations.has(cell): return cell
	return -1

func store_module(kind: int) -> bool:
	var cell := free_module_cell()
	if cell < 0: return false
	module_locations.append(cell)
	module_types.append(kind)
	return true

func unequip_all() -> void:
	var equipped: Array[int] = []
	var stored := 0
	for i in range(module_locations.size()):
		var location := module_locations[i]
		if location < 64: stored += 1
		elif equipped_slot(location,MODULE_CATEGORY[module_types[i]]) >= 0: equipped.append(i)
	if equipped.size() > 64-stored:
		status = "Faltan celdas libres para desequipar"
		return
	for i in equipped: module_locations[i] = free_module_cell()
	dragged_module = -1
	status = "Módulos devueltos al inventario"

func first_stored_module(kind: int) -> int:
	for i in range(module_types.size()):
		if module_types[i] == kind and module_locations[i] < 64: return i
	return -1

var mineral_quantities: Array[int] = [1,1,1,1,1,1,1,1,1,1,1]
var object_quantities: Array[int] = [1,1,1,1,1,1,1,1,1,1,1]
var quantity_row := -1
var replace_quantity := false

func market_quantities() -> Array[int]:
	return object_quantities if market == 2 else mineral_quantities

func quantity_key(event: InputEventKey) -> void:
	if quantity_row < 0 or not event.pressed: return
	var quantities := market_quantities()
	if event.keycode == KEY_BACKSPACE:
		quantities[quantity_row] = 0 if replace_quantity else quantities[quantity_row]/10
		replace_quantity = false
	elif event.unicode >= 48 and event.unicode <= 57:
		var previous := 0 if replace_quantity else quantities[quantity_row]
		quantities[quantity_row] = mini(9999,previous*10+event.unicode-48)
		replace_quantity = false

func station_minerals(index: int) -> Array[int]:
	if index >= 2:
		var result: Array[int] = []
		result.assign(stations[index].stock)
		stations[index].stock = result
		return result
	return nacar_stock if index == 1 else mineral_stock

func station_price(index: int, row: int) -> int:
	if index >= 2: return maxi(1,int(MINERAL_PRICES[row])+(index-2)*2+(row%3))
	return NACAR_PRICES[row] if index == 1 else MINERAL_PRICES[row]

func market_stock() -> Array[int]:
	if market == 3: return trader_stock
	if market == 2:
		if dock_station >= 2:
			var result: Array[int] = []
			result.assign(stations[dock_station].modules)
			stations[dock_station].modules = result
			return result
		return nacar_modules if dock_station == 1 else module_stock
	return station_minerals(dock_station)

func market_price(row: int) -> int:
	if market == 2: return MODULE_PRICES[row]
	if market == 3: return MINERAL_PRICES[row]+3
	return station_price(dock_station,row)

func trade(row: int, buy: bool) -> void:
	var objects := market == 2
	var stock := market_stock()
	var price := market_price(row)
	var quantity := market_quantities()[row]
	if quantity <= 0:
		market_status = "Escribe una cantidad mayor que cero"
		return
	var materials := cargo if market == 3 else inventory
	var owned := 0 if objects else int(materials[row])
	if objects:
		owned = 0
		for i in range(module_types.size()):
			if module_types[i] == row and module_locations[i] < 64: owned += 1
	if buy:
		if stock[row] < quantity or credits < price*quantity:
			market_status = "Stock o Créditos insuficientes para esa cantidad"
			return
		if objects:
			var free := 64
			for location in module_locations:
				if location < 64: free -= 1
			if free < quantity:
				market_status = "El inventario de módulos no tiene espacio suficiente"
				return
			for i in range(quantity): store_module(row)
		else:
			if market == 3 and used()+quantity > stat(4):
				market_status = "No hay espacio suficiente en la bodega"
				return
			materials[row] += quantity
		stock[row] -= quantity
		credits -= price*quantity
		market_status = "Compra realizada: %d" % quantity
	else:
		if owned < quantity:
			market_status = "Cantidad insuficiente en tu inventario"
			return
		if objects:
			for i in range(quantity):
				var item := first_stored_module(row)
				module_types.remove_at(item)
				module_locations.remove_at(item)
		else:
			materials[row] -= quantity
		stock[row] += quantity
		credits += (price/2)*quantity
		market_status = "Venta realizada: %d" % quantity

func market_button(index: int) -> Rect2:
	return Rect2(get_viewport_rect().size.x-238,94+index*39,218,33)

func menu_button(area: Rect2, caption: String, green: bool = false) -> void:
	draw_rect(area,Color("#244938") if green else Color("#203b51"))
	draw_rect(area,Color.PALE_GREEN if green else Color.TURQUOISE,false)
	draw_string(ThemeDB.fallback_font,area.position+Vector2(0,area.size.y*.5+5),caption,HORIZONTAL_ALIGNMENT_CENTER,area.size.x,16,Color.WHITE)

func market_click(pointer: Vector2) -> void:
	var at := (get_viewport_rect().size-MARKET_SIZE)/2
	if Rect2(at+Vector2(650,13),Vector2(120,35)).has_point(pointer):
		market = 0
		return
	quantity_row = -1
	var count := MODULE_NAMES.size() if market == 2 else RES.size()
	for row in range(count):
		var y := 94+row*33
		if Rect2(at+Vector2(315,y),Vector2(118,28)).has_point(pointer): trade(row,true)
		elif Rect2(at+Vector2(443,y),Vector2(118,28)).has_point(pointer): trade(row,false)
		elif Rect2(at+Vector2(571,y),Vector2(72,28)).has_point(pointer):
			quantity_row = row
			replace_quantity = true

func draw_market(center: Vector2) -> void:
	var objects := market == 2
	var at := draw_menu_panel(center,MARKET_SIZE,"Mercado Objetos" if objects else ("Trader" if market == 3 else "Mercado Minería"),market_status)
	label(at+Vector2(23,62),"%d Créditos" % credits,19,Color.PALE_GREEN)
	label(at+Vector2(205,85),"BODEGA" if market == 3 else "INVENTARIO",16,Color.TURQUOISE)
	label(at+Vector2(571,85),"CANTIDAD",14,Color.TURQUOISE)
	label(at+Vector2(680,85),"TRADER" if market == 3 else "ESTACIÓN",16,Color.TURQUOISE)
	menu_button(Rect2(at+Vector2(650,13),Vector2(120,35)),"Cerrar")
	var count := MODULE_NAMES.size() if objects else RES.size()
	var quantities := market_quantities()
	for row in range(count):
		var y := 94+row*33
		var owned := 0
		if objects:
			for i in range(module_types.size()):
				if module_types[i] == row and module_locations[i] < 64: owned += 1
		else: owned = cargo[row] if market == 3 else inventory[row]
		var stock := market_stock()[row]
		var price := market_price(row)
		label(at+Vector2(23,y+21),MODULE_NAMES[row] if objects else RES[row],17)
		label(at+Vector2(244,y+21),str(owned),17)
		label(at+Vector2(710,y+21),str(stock),17)
		menu_button(Rect2(at+Vector2(315,y),Vector2(118,28)),"← Comprar %d" % price)
		menu_button(Rect2(at+Vector2(443,y),Vector2(118,28)),"Vender %d →" % (price/2))
		var field := Rect2(at+Vector2(571,y),Vector2(72,28))
		draw_rect(field,Color("#081322"))
		draw_rect(field,Color.PALE_GREEN if quantity_row == row else Color.SLATE_GRAY,false)
		label(field.position+Vector2(9,20),str(quantities[row]),17)
		if not objects:
			draw_line(at+Vector2(23,y+31),at+Vector2(763,y+31),Color("#365073"))

func draw_inventory(center: Vector2) -> void:
	var at := draw_menu_panel(center,EQUIPMENT_SIZE,"Inventario","Arrastra el módulo a una ranura compatible")
	menu_button(Rect2(at+Vector2(765,10),Vector2(110,34)),"Cerrar")
	label(at+Vector2(20,61),ship_name()+"  /  RANURAS",14,Color.TURQUOISE)
	label(at+Vector2(338,61),"CUADRÍCULA DE EQUIPAMIENTO",14,Color.TURQUOISE)
	draw_line(at+Vector2(314,54),at+Vector2(314,377),Color("#365073"))
	sprite(selected,at+Vector2(205,194),222,PAINT[paint])
	for category in range(SLOT_NAMES.size()):
		var y := 116+category*49
		var count := stat(5+category)
		label(at+Vector2(20,y+4),SLOT_NAMES[category],16,SLOT_COLORS[category])
		for i in range(count):
			var cell := equipment_slot(at,category,i)
			draw_rect(cell,Color(.04,.08,.15,.78))
			draw_rect(cell,SLOT_COLORS[category],false,1.5)
	var grid := at+EQUIPMENT_GRID
	draw_rect(Rect2(grid,Vector2.ONE*EQUIPMENT_SPAN),Color("#0a1427"))
	for i in range(9):
		draw_line(grid+Vector2(i*EQUIPMENT_CELL,0),grid+Vector2(i*EQUIPMENT_CELL,EQUIPMENT_SPAN),Color("#365073"))
		draw_line(grid+Vector2(0,i*EQUIPMENT_CELL),grid+Vector2(EQUIPMENT_SPAN,i*EQUIPMENT_CELL),Color("#365073"))

	draw_line(at+Vector2(660,54),at+Vector2(660,377),Color("#365073"))
	label(at+Vector2(677,61),"DETALLES DEL MÓDULO",14,Color.TURQUOISE)
	var pointer := get_local_mouse_position()
	var hovered := module_locations.find(equipment_location(pointer))
	if dragged_module >= 0: hovered = dragged_module
	menu_button(Rect2(at+Vector2(677,248),Vector2(197,38)),"Desequipar todo")
	if hovered >= 0:
		var kind := module_types[hovered]
		label(at+Vector2(677,106),MODULE_NAMES[kind],17,Color.PALE_GREEN)
		label(at+Vector2(677,132),"Ranura: "+SLOT_NAMES[MODULE_CATEGORY[kind]],13)
		for i in range(MODULE_DETAILS[kind].size()):
			label(at+Vector2(677,161+i*23),MODULE_DETAILS[kind][i],14)
	else:
		label(at+Vector2(677,106),"Pasa el ratón sobre un módulo.",13)
	for item in range(module_locations.size()):
		if item == dragged_module: continue
		var location := module_locations[item]
		if location < EQUIPPED_START:
			module_icon(grid+(Vector2(location%8,location/8)+Vector2(.5,.5))*EQUIPMENT_CELL,module_types[item],28)
		else:
			var category: int = MODULE_CATEGORY[module_types[item]]
			var slot := equipped_slot(location,category)
			if slot >= 0: module_icon(equipment_slot(at,category,slot).get_center(),module_types[item])
	if dragged_module >= 0: module_icon(pointer,module_types[dragged_module])

func draw_help(center: Vector2) -> void:
	var at := draw_menu_panel(center,Vector2(620,308),"Controles","H / Esc  Cerrar")
	for column in range(HELP_GROUPS.size()):
		var group: Array = HELP_GROUPS[column]
		var x := 18+column*201
		if column > 0: draw_line(at+Vector2(x-9,55),at+Vector2(x-9,270),Color("#365073"))
		label(at+Vector2(x,70),group[0],15,Color.TURQUOISE)
		for i in range(1,group.size()):
			label(at+Vector2(x,70+i*24),group[i],15)



func _draw() -> void:
	var screen := get_viewport_rect().size
	var center := screen/2
	draw_texture_rect(soft_sky if hangar and soft_sky != null else STAR_FIELD,Rect2(Vector2.ZERO,screen),not hangar)
	if ships.is_empty() or ships.has(null): return
	if hangar:
		draw_docked_background(screen)
		for i in range(-5,6):
			draw_line(center+Vector2(i*24,-120),center+Vector2(i*24,120),Color("#283449"))
			draw_line(center+Vector2(-120,i*24),center+Vector2(120,i*24),Color("#283449"))
		sprite(selected,center,160,PAINT[paint])
		for i in range(ships.size()):
			var rect := slot(i)
			draw_rect(rect,Color.TURQUOISE if i == selected else Color.DIM_GRAY,false)
			sprite(i,rect.get_center(),30,Color.WHITE)
			label(rect.position+Vector2(4,14),str(i+1),12)
	else:
		draw_set_transform(center-pos*zoom,0,Vector2.ONE*zoom)
		if module_count(4) > 0:
			var alpha := .24+.12*sin(Time.get_ticks_msec()/650.0)
			draw_arc(pos,stat(3)*1.25,0,TAU,64,Color(.7,.73,.77,alpha),2)
		draw_stations()
		for i in range(rocks.size()):
			var rock: Dictionary = rocks[i]
			if (rock.hp <= 0 and not rock.has("fade")) or absf(rock.p.x-pos.x) > center.x/zoom+150 or absf(rock.p.y-pos.y) > center.y/zoom+90: continue
			var texture := asteroid_sprites[asteroid_size(rock.r) * 2 + i % 2]
			var extent: Vector2 = Vector2.ONE * rock.r
			draw_texture_rect(texture, Rect2(rock.p - extent, extent * 2), false, Color(1,1,1,float(rock.fade)/10) if rock.has("fade") else Color.WHITE)
			if rock.has("fade"): continue
			if rock.seen:
				var contents: String = RES[rock.first]
				if rock.second >= 0: contents += " + "+RES[rock.second]
				label(rock.p+Vector2(-rock.r,rock.r+17),contents,12,Color.TURQUOISE)
			if rock.hp < ROCK_HP:
				draw_rect(Rect2(rock.p+Vector2(-rock.r,rock.r+3),Vector2(2.0*rock.r*rock.hp/ROCK_HP,2)),Color.ORANGE)
			if i == selected_target:
				draw_arc(rock.p,rock.r+5,0,TAU,48,Color.GOLD,2)
			if i == target:
				var left: Vector2 = rock.p+Vector2(-rock.r-12,rock.r)
				var right: Vector2 = rock.p+Vector2(rock.r+6,rock.r)
				var h: float = rock.r*2
				draw_rect(Rect2(left-Vector2(0,h),Vector2(6,h)),Color.DARK_SLATE_GRAY)
				draw_rect(Rect2(right-Vector2(0,h),Vector2(6,h)),Color.DARK_SLATE_GRAY)
				draw_rect(Rect2(left-Vector2(0,h*rock.progress),Vector2(6,h*rock.progress)),Color.LIME_GREEN)
				draw_rect(Rect2(right-Vector2(0,h*power/100.0),Vector2(6,h*power/100.0)),Color.ORANGE)
				draw_rect(Rect2(right-Vector2(2,h*(window_center(rock)+mining_margin(mining_hits))),Vector2(10,h*mining_margin(mining_hits)*2)),Color.TURQUOISE,false)
		for i in range(links.size()):
			if sector != links[i].x and sector != links[i].y: continue
			var gate := gate_position(i,sector)
			draw_arc(gate,52,0,TAU,48,Color.MEDIUM_PURPLE,5)
			draw_arc(gate,38,0,TAU,40,Color.TURQUOISE,2)
			label(gate+Vector2(-36,73),"G  Puerta",14,Color.TURQUOISE)
		for npc in npcs:
			if npc.hp <= 0: continue
			if npc.has("ore"): draw_circle(npc.ore,6,Color.GOLD)
			if npc.trace > 0:
				draw_line(npc_mount(npc,"mineria" if npc.role == "Minero" else "ametralladora"),npc.end,Color.GOLD if npc.role == "Minero" else Color.ORANGE_RED,2)
			draw_ftl_burst(npc.p,float(npc.entry_age),maxf(70,float(specs[npc.ship][3])*2))
			if npc.entry_age < .15: continue
			draw_set_transform(center+(npc.p+ftl_offset(npc.entry_age,npc.angle)-pos)*zoom,npc.angle,Vector2.ONE*zoom)
			sprite(npc.ship,Vector2.ZERO,int(specs[npc.ship][3]),Color.WHITE)
			if npc.shield: shield_sprite(npc.ship,Vector2.ZERO,int(specs[npc.ship][3]),npc.shield_state.flash,npc.shield_state.break_flash)
			draw_set_transform(center-pos*zoom,0,Vector2.ONE*zoom)
			if is_same(npc,npc_target): draw_arc(npc.p,40,0,TAU,40,Color.GOLD,2)
			label(npc.p+Vector2(14,34),npc.role,13,Color.ORANGE_RED if npc.role == "Pirata" else Color.TURQUOISE)
		var wrecks: Array = wreck_fields[sector]
		for i in range(wrecks.size()):
			var item: Dictionary = wrecks[i]
			if not wreck_sprites.is_empty():
				var texture := wreck_sprites[int(item.sprite)%wreck_sprites.size()]
				var size := texture.get_size()*(wreck_radius(item)*2/maxf(texture.get_width(),texture.get_height()))
				draw_set_transform(center+(item.p-pos)*zoom,item.angle,Vector2.ONE*zoom)
				draw_texture_rect(texture,Rect2(-size/2,size),false)
				draw_set_transform(center-pos*zoom,0,Vector2.ONE*zoom)
			else:
				draw_circle(item.p,5,Color.SLATE_GRAY)
			if i == salvage_target:
				draw_arc(item.p,16,0,TAU*item.progress,24,Color.TURQUOISE,2)
		if mode == 4 and Input.is_key_pressed(KEY_SPACE):
			for ray in salvage_rays:
				draw_line(ray[0],ray[1],Color.FOREST_GREEN,5)
				draw_line(ray[0],ray[1],Color.PALE_GREEN,2)
		for item in module_drops[sector]:
			var point := Vector2(item[0],item[1])
			draw_circle(point,11,Color.DARK_GREEN)
			if int(item[2]) in [6,7,8]:
				draw_texture_rect(MODULE_WORLD[int(item[2])-6],Rect2(point-Vector2(14,12),Vector2(28,24)),false)
			else: module_icon(point,int(item[2]))
		for item in fragments:
			draw_circle(item.p,5,Color.SLATE_GRAY)
			draw_rect(Rect2(item.p-Vector2(2,2),Vector2(4,4)),Color.TURQUOISE)
		for shot in bullets: draw_line(shot.p,shot.p-shot.f*20,Color.KHAKI,2)
		if ping > 0 and ping < 650:
			draw_arc(ping_origin,ping,0,TAU,96,Color(0.25,0.9,0.8,1-ping/650),2)
		if mode == 2 and Input.is_key_pressed(KEY_SPACE):
			for ray in mining_rays:
				draw_line(ray[0],ray[1],Color.GOLD,5)
				draw_line(ray[0],ray[1],Color.WHITE,2)
		draw_ftl_burst(pos,ftl_arrival_age,maxf(90,stat(3)*2))
		var visual := ftl_offset(ftl_depart_age,angle,true) if ftl_depart_age >= 0 else ftl_offset(ftl_arrival_age,angle)
		draw_set_transform(center+visual*zoom,angle,Vector2.ONE*zoom)
		if not player_destroying and Input.is_key_pressed(KEY_W):
			var count := engine_count(selected)
			var flame := 10.0+fmod(Time.get_ticks_msec()/35.0,8.0)
			for i in range(count):
				var mount := ship_mount(selected,"motor",i,count)
				draw_rect(Rect2(mount-Vector2(3,0),Vector2(6,flame)),Color.ORANGE_RED)
				draw_rect(Rect2(mount-Vector2(1,0),Vector2(2,flame*.75)),Color.GOLD)
		if not player_destroying and ftl_arrival_age >= .15:
			sprite(selected,Vector2.ZERO,stat(3),PAINT[paint])
			if module_count(9) > 0: shield_sprite(selected,Vector2.ZERO,stat(3),player_shield().flash,player_shield().break_flash)
		draw_set_transform(center-pos*zoom,0,Vector2.ONE*zoom)
		vector_arrow(pos,vel,player_thrust,forward())
		for npc in npcs:
			if npc.hp > 0: vector_arrow(npc.p,npc.v,float(npc.get("active_thrust",0)),Vector2.UP.rotated(npc.angle))
		if not extra_target.is_empty(): draw_arc(extra_target.p,float(extra_target.r)+5,0,TAU,32,Color.GOLD,2)
		draw_pdc_world(center-pos*zoom)
		for exit in ftl_exits:
			var exit_visual: Vector2 = exit.p+ftl_offset(exit.age,exit.angle,true)
			draw_set_transform(center+(exit_visual-pos)*zoom,exit.angle,Vector2.ONE*zoom)
			sprite(exit.ship,Vector2.ZERO,float(specs[exit.ship][3]),Color.WHITE)
		draw_set_transform(center-pos*zoom,0,Vector2.ONE*zoom)
		draw_explosions(center)
		draw_set_transform(Vector2.ZERO)
	label(Vector2(20,34),"HANGAR ORBITAL / GODOT 0.0.58" if hangar else "SECTOR %d / 10.000 × 10.000" % (4107+sector),23,Color.TURQUOISE)
	label(Vector2(20,62),"H Controles   M Mapa estelar" if hangar else "H Controles   M Mapa estelar")
	label(Vector2(20,86),"%s   Masa %d   Empuje %d   Casco %d/%d   Bodega %d/%d U" % [ship_name(),stat(0),stat(1),hp,stat(2),used(),stat(4)])
	if hangar:
		label(Vector2(20,137),stations[dock_station].name+"  ·  "+("Atraque universal" if stations[dock_station].layout == "shipyard" else ("Atraque Dreadnought" if dock_port >= CAPITAL_PORT else "Puerto "+str(dock_port+1)))+"  ·  Enter despegar",15,Color.PALE_GREEN)
		label(Vector2(20,158),"Entregas mineras: %d U" % (nacar_reserve if dock_station == 1 else station_reserve),15,Color.PALE_GREEN)
		var ship_class := specs[selected][10]
		label(Vector2(20,110),"%s | Slots: Arm. %d  Def. %d  Util. %d  Motor %d" %
			[ship_class,stat(5),stat(6),stat(7),stat(8)],15,Color.TURQUOISE)
		label(Vector2(20,screen.y-246),"Inventario del jugador",16,Color.TURQUOISE)
		for i in range(RES.size()):
			label(Vector2(20+(i%2)*195,screen.y-226+floori(i/2.0)*19),
				"%s  %d U" % [RES[i],inventory[i]],13)
	else:
		label(Vector2(20,182),"Coupled [C]" if coupled else "Decoupled [C]",15,Color.TURQUOISE)
		label(Vector2(20,110),"%s   Vel %d   %s" % [MODES[mode],int(vel.length()),"Potencia %d%%" % power if mode == 2 else ""])
		var keys := weapon_keys()
		label(Vector2(20,134),keys if not keys.is_empty() else "Sin módulos de armamento",15,Color.TURQUOISE)
	label(Vector2(20,screen.y-18),status,15,Color.TURQUOISE)
	if not hangar and selected_target >= 0:
		label(Vector2(20,158),"Objetivo: asteroide a %d" % pos.distance_to(rocks[selected_target].p),15,Color.GOLD)
	if not hangar and not npc_target.is_empty():
		label(Vector2(20,158),"Objetivo: %s a %d" % [npc_target.role,pos.distance_to(npc_target.p)],15,Color.GOLD)
	if not hangar and not trader.is_empty() and trader.hp > 0:
		var delta: Vector2 = (trader.p-pos)*zoom
		var edge := maxf(absf(delta.x)/(center.x-35),absf(delta.y)/(center.y-35))
		if pos.distance_to(trader.p) <= 220:
			label(Vector2(20,208),"J  Comerciar con trader",16,Color.PALE_GREEN)
		if edge > 1:
			var tip := center+delta/edge
			var direction := delta.normalized()
			var side := direction.orthogonal()
			draw_colored_polygon(PackedVector2Array([tip+direction*11,tip-direction*7+side*8,tip-direction*7-side*8]),Color.TURQUOISE)
	draw_target_info(screen)
	draw_maps(screen)
	if map_open: draw_ftl_map(center)
	if hangar:
		label(Vector2(screen.x-238,80),"%d Créditos" % credits,21,Color.PALE_GREEN)
		menu_button(market_button(0),"Mercado Minería")
		menu_button(market_button(1),"Mercado Objetos")
		menu_button(market_button(2),"Inventario")
		menu_button(market_button(3),"Descargar bodega")
		menu_button(market_button(4),"Desatracar",true)
	if market > 0 and (hangar or market == 3):
		draw_market(center)
	elif inventory_open and hangar:
		draw_inventory(center)
	elif help_open:
		draw_help(center)
	draw_console(screen)
