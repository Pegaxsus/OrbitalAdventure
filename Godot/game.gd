extends Node2D

const MISSILE := preload("res://missile.tscn")
const HALF := 5000.0
const ROCK_HP := 2400
const STAR_FIELD := preload("res://environment/stars.png")
const MODES := ["Armamento", "Misiles", "Minería", "Drones", "Salvaging"]
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
var beam := 0.0
var shift_time := -1
var shift_scroll := false

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
var salvage_length := 0.0
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

func destroy_wreck(index: int) -> void:
	wreck_fields[sector].remove_at(index)
	salvage_target = -1

func wreck_ship(at: Vector2, ship: int, player: bool = false) -> void:
	var count := clampi(2+int(specs[ship][3])/30,2,7)
	explosions.append({"p":at,"age":0.0,"size":float(specs[ship][3])*.75,"player":player})
	for i in range(count):
		var offset := Vector2.RIGHT.rotated(i*TAU/count)*randf_range(15,36+count*3)
		wreck_fields[sector].append({"p":at+offset,"sprite":randi()%maxi(1,wreck_sprites.size()),"angle":randf_range(0,TAU),"progress":0.0})

func update_wrecks(dt: float) -> void:
	for i in range(explosions.size()-1,-1,-1):
		explosions[i].age += dt
		if explosions[i].age >= .7: explosions.remove_at(i)
	salvage_target = -1
	salvage_length = 0
	if hangar or mode != 4 or not Input.is_key_pressed(KEY_SPACE): return
	var start := pos+forward()*stat(3)/2.0
	var reach := stat(3)*.55
	var end := start+forward()*reach
	var rock := ray_rock(start,end)
	var hit := ray_wreck(start,end,rock.y)
	salvage_length = hit.y*reach
	salvage_target = int(hit.x)
	if salvage_target < 0: return
	var item: Dictionary = wreck_fields[sector][salvage_target]
	var grade := int(item.sprite)%3
	var amount := 3+2*grade
	if used()+amount > stat(4):
		status = "Se necesitan %d U libres en la bodega" % amount
		return
	item.progress += dt/(1.0+grade*.75)
	if item.progress >= 1:
		var resource: int = SALVAGE_MATERIALS[int(item.sprite)%SALVAGE_MATERIALS.size()]
		cargo[resource] += amount
		destroy_wreck(salvage_target)
		status = "Recuperadas %d U de %s" % [amount,RES[resource]]


func draw_explosions(center: Vector2, player_only: bool) -> void:
	for blast in explosions:
		if player_only and not blast.player: continue
		var at: Vector2 = center if player_only else blast.p
		var t: float = blast.age/.7
		var radius: float = maxf(5,blast.size*t)
		draw_circle(at,radius,Color(1,.31,.05,.4*(1-t)))
		draw_arc(at,radius,0,TAU,36,Color(1,.66,.17,1-t),3)
		for i in range(9):
			var spark := Vector2.RIGHT.rotated(i*TAU/9)*radius*(.65+.1*(i%3))
			draw_line(at+spark*.82,at+spark,Color(1,.85,.3,1-t),2)

func make_npc(role: String, ship: int, at: Vector2) -> Dictionary:
	var npc := {"role":role,"ship":ship,"p":at,"v":Vector2.ZERO,"angle":0.0,
		"hp":int(specs[ship][2]),"cooldown":0.0,"trace":0.0,"end":at,"cargo":0,"work":0.0,"rock":-1}
	npcs.append(npc)
	return npc

func reset_traffic() -> void:
	npcs.clear()
	trader = {}
	npc_target = {}
	traffic_time = 0
	station_raid_until = 0
	next_trader = 8
	neutral_attack = -100
	make_npc("Minero",2,Vector2(230,-140))
	make_npc("Patrulla",4,Vector2(-290,220))
	make_npc("Pirata",3,Vector2(780,-360))

func npc_hit(npc: Dictionary, amount: int, by_player: bool) -> void:
	if npc.hp <= 0 or amount <= 0: return
	npc.hp = maxi(0,npc.hp-amount)
	if npc.hp == 0: wreck_ship(npc.p,npc.ship)
	if by_player:
		attack_position = npc.p
		if npc.role in ["Trader","Minero","Escolta"]:
			var patrol := npcs[1]
			if patrol.hp > 0 and patrol.p.distance_to(npc.p) < 720 and ray_rock(patrol.p,npc.p).x < 0:
				neutral_attack = traffic_time

func fire_npc(npc: Dictionary, at: Vector2, victim: Dictionary) -> void:
	if npc.cooldown > 0 or npc.p.distance_to(at) > 310: return
	var block := ray_rock(npc.p,at)
	if block.x >= 0: return
	npc.cooldown = .48
	npc.trace = .10
	npc.end = at
	var debris := ray_wreck(npc.p,at,1)
	if debris.x >= 0:
		npc.end = npc.p.lerp(at,debris.y)
		destroy_wreck(int(debris.x))
		return
	if victim.is_empty():
		hp -= 9
		if hp <= 0: destroyed()
	else:
		npc_hit(victim,12,false)

func steer_npc(npc: Dictionary, goal: Vector2, speed: float, dt: float, mining_rock: int) -> void:
	var offset: Vector2 = goal-npc.p
	var desired := offset.limit_length(speed)
	var ahead: Vector2 = npc.p + desired.normalized()*100
	var obstacle := ray_rock(npc.p,ahead)
	if obstacle.x >= 0 and int(obstacle.x) != mining_rock:
		var rock: Dictionary = rocks[int(obstacle.x)]
		var side: Vector2 = (npc.p-rock.p).normalized()
		desired = (desired.normalized().orthogonal()+side*.7).normalized()*speed
	npc.v = npc.v.move_toward(desired,80*dt)
	npc.p += npc.v*dt
	var facing: Vector2 = npc.end-npc.p if npc.trace > 0 else offset
	if facing.length_squared() > 4:
		npc.angle = rotate_toward(npc.angle,facing.angle()+PI/2,1.7*dt)

func update_traffic(dt: float) -> void:
	traffic_time += dt
	if traffic_time >= next_trader:
		if not trader.is_empty():
			for i in range(npcs.size()-1,-1,-1):
				if npcs[i].role in ["Trader","Escolta"]: npcs.remove_at(i)
			trader = {}
			next_trader = traffic_time + randf_range(20,42)
		else:
			var ship: int = [2,5,9].pick_random()
			trader = make_npc("Trader",ship,Vector2(-1100,420))
			if ship == 9:
				make_npc("Escolta",2,trader.p+Vector2(-95,-85))
				make_npc("Escolta",2,trader.p+Vector2(-95,85))
			next_trader = traffic_time + 45
	var miner: Dictionary = npcs[0]
	var pirate: Dictionary = npcs[2]
	var station: Dictionary = stations[0] if sector == 0 else {}
	for npc in npcs:
		if hangar or npc.hp <= 0: continue
		npc.cooldown -= dt
		npc.trace -= dt
		var goal: Vector2 = npc.p
		var speed := 105.0
		var rock_index := -1
		match npc.role:
			"Trader":
				goal = Vector2(4500,420)
				speed = 80
			"Escolta":
				goal = trader.p + Vector2(-95,-85 if npc.p.y < trader.p.y else 85)
				if pirate.hp > 0 and pirate.p.distance_to(trader.p) < 350:
					fire_npc(npc,pirate.p,pirate)
			"Minero":
				if not station.is_empty() and npc.cargo > 0:
					goal = port_center(station,0)
					for port in range(1,station.ports):
						var candidate := port_center(station,port)
						if npc.p.distance_squared_to(candidate) < npc.p.distance_squared_to(goal): goal = candidate
					if npc.p.distance_to(goal) < 20 and npc.v.length() < 32:
						station_reserve += int(npc.cargo)
						npc.cargo = 0
						npc.rock = -1
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
							if npc.work >= 4:
								npc.ore = rock.p
								npc.ore_amount = mini(20-npc.cargo,4+asteroid_size(rock.r)*4)
								rock.hp = 0
								npc.work = 0
			"Pirata":
				var victim: Dictionary = miner if miner.hp > 0 and miner.cargo > 0 and (used() == 0 or npc.p.distance_to(miner.p) < npc.p.distance_to(pos)) else {}
				var at: Vector2 = pos if victim.is_empty() else victim.p
				goal = Vector2(4400,-4300)
				if npc.hp > int(specs[npc.ship][2])*.28:
					goal = Vector2(790,-330)
					if (used() > 0 or not victim.is_empty()) and npc.p.distance_to(at) < 800:
						goal = at+(npc.p-at).normalized()*175
						fire_npc(npc,at,victim)
					elif not station.is_empty():
						var base: Vector2 = station.p
						goal = base+(npc.p-base).normalized()*235
						attack_station(npc,station)
			"Patrulla":
				goal = Vector2(-280,200)+Vector2.from_angle(traffic_time*.13)*340
				if not station.is_empty():
					goal = station.p+Vector2.from_angle(traffic_time*.13)*280
				if not station.is_empty() and pirate.hp > 0 and (traffic_time < station_raid_until or pirate.p.distance_to(station.p) < 465):
					goal = pirate.p+(npc.p-pirate.p).normalized()*155
					fire_npc(npc,pirate.p,pirate)
				elif traffic_time-neutral_attack < 22 and npc.p.distance_to(attack_position) < 720:
					goal = pos+(npc.p-pos).normalized()*165
					fire_npc(npc,pos,{})
				elif pirate.hp > 0 and npc.p.distance_to(pirate.p) < 620 and ray_rock(npc.p,pirate.p).x < 0:
					goal = pirate.p+(npc.p-pirate.p).normalized()*155
					fire_npc(npc,pirate.p,pirate)
				elif bullets.size() > 0 and npc.p.distance_to(pos) < 650:
					goal = pos+(npc.p-pos).normalized()*200
		steer_npc(npc,goal,speed,dt,rock_index)

func attack_station(npc: Dictionary, station: Dictionary) -> void:
	var base: Vector2 = station.p
	if npc.cooldown > 0 or npc.p.distance_to(base) > 310 or ray_rock(npc.p,base).x >= 0: return
	npc.cooldown = .48
	npc.trace = .10
	npc.end = base
	station.hp = maxi(1,station.hp-90)
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
const PORT_LENGTH := 190.0
const PORT_WIDTH := 56.0

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
		stations.append({"name":data[1],"sector":int(data[2]),"p":Vector2(float(data[3]),float(data[4])),
			"size":float(data[5]),"mass":int(data[6]),"hp":int(data[7]),"ports":int(data[8]),"art":art,"soft":ImageTexture.create_from_image(soft)})

func port_axis(port: int) -> Vector2:
	return [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT][port/2]

func port_center(station: Dictionary, port: int) -> Vector2:
	var axis := port_axis(port)
	return station.p + axis * station.size * .66 + axis.orthogonal() * (48 if port%2 == 0 else -48)

func dock_at(index: int, port: int) -> void:
	dock_station = index
	dock_port = port
	pos = port_center(stations[index],port)
	angle = port_axis(port).angle()+PI/2
	dock()

func rescue_dock() -> void:
	if sector != 0:
		sector = 0
		rocks = fields[0]
		fragments = sector_loot[0]
		reset_traffic_on_launch = true
	dock_at(0,0)

func try_dock() -> void:
	if hangar or map_open: return
	for i in range(stations.size()):
		var station := stations[i]
		if station.sector != sector or pos.distance_to(station.p) > 240: continue
		for port in range(station.ports):
			var axis := port_axis(port)
			var offset := pos-port_center(station,port)
			var alignment := absf(forward().dot(axis))
			var half_width := ship_half_width()
			var side_extent := half_width*alignment + stat(3)*.5*sqrt(maxf(0,1-alignment*alignment))
			if alignment < cos(deg_to_rad(12)) or vel.length() > 28: continue
			if absf(offset.dot(axis)) + stat(3)*.5 > PORT_LENGTH*.5: continue
			if absf(offset.dot(axis.orthogonal()))+side_extent > PORT_WIDTH*.5: continue
			dock_at(i,port)
			status = "Atraque completado · "+station.name
			return
	status = "B requiere un puerto cercano: alinea la nave, entra y reduce la velocidad"

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
		if station.sector != sector or pos.distance_to(station.p) > 205: continue
		for shape in station_shapes(station):
			for i in [-1,0,1]:
				var sample: Vector2 = pos+forward()*int(i)*stat(3)*.37
				if not shape.grow(width).has_point(sample): continue
				var speed := vel.length()
				pos = previous
				vel *= -.32
				if speed > 14: hp -= int(speed*.3)
				if hp <= 0: destroyed()
				return true
	return false

func draw_stations() -> void:
	for station in stations:
		if station.sector != sector: continue
		var size := Vector2.ONE*float(station.size)
		draw_texture_rect(station.art,Rect2(station.p-size/2,size),false)
		label(station.p+Vector2(-53,21),station.name,12,Color.TURQUOISE)
		if pos.distance_to(station.p) > 240: continue
		for port in range(station.ports):
			var p := port_center(station,port)
			var dimensions := Vector2(PORT_WIDTH,PORT_LENGTH) if port < 2 or (port >= 4 and port < 6) else Vector2(PORT_LENGTH,PORT_WIDTH)
			var area := Rect2(p-dimensions/2,dimensions)
			draw_rect(area,Color(.03,.26,.14,.52))
			draw_rect(area,Color.PALE_GREEN,false,1.5)
		label(station.p+Vector2(-74,40),"B Atraque · Casco %d" % station.hp,13,Color.PALE_GREEN)

func draw_docked_background(screen: Vector2) -> void:
	if stations.is_empty(): return
	var station := stations[dock_station]
	var size := Vector2.ONE*float(station.size)*2.6
	var center := screen/2+(Vector2(station.p)-pos)*2.6
	draw_texture_rect(station.soft,Rect2(center-size/2,size),false,Color(.54,.64,.74,.86))
	draw_rect(Rect2(Vector2.ZERO,screen),Color(.035,.07,.13,.58))



func _ready() -> void:
	add_child(missile_layer)
	for i in range(1,33):
		var path := "res://environment/debris-%02d.png" % i
		if ResourceLoader.exists(path): wreck_sprites.append(load(path))
	for size in range(1, 6):
		for variant in range(1, 3):
			asteroid_sprites.append(load("res://environment/asteroid-%d-%d.png" % [size, variant]))
	for i in range(17):
		ships.append(load("res://ships/ship%d.png" % i))
		specs.append(FileAccess.get_file_as_string("res://ship-attributes/ship%d.txt" % i).strip_edges().split(","))
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
	dock_at(0,0)
	reset_traffic()
	load_game()

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
		beam = 0
		salvage_length = 0
		salvage_target = -1
		ping = 1000
		bullets.clear()
		clear_missiles()
		explosions.clear()
		reset_traffic()
		status = "Salto al sector %d" % (4107+sector)
		return
	status = "Acércate a una puerta estelar para saltar"

func draw_maps(screen: Vector2) -> void:
	if not hangar:
		var bounds := Rect2(screen.x-136,18,116,116)
		draw_rect(bounds,Color("#151d38"))
		draw_rect(bounds,Color.TURQUOISE,false)
		for i in range(links.size()):
			if (crossed & (1 << i)) == 0 or (sector != links[i].x and sector != links[i].y): continue
			draw_circle(bounds.position+(gate_position(i,sector)/10000.0+Vector2(.5,.5))*bounds.size,3,Color.MEDIUM_PURPLE)
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
	hangar = true
	selected_target = -1
	npc_target = {}
	hp = stat(2)
	vel = Vector2.ZERO
	bullets.clear()
	clear_missiles()
	ping = 1000
	target = -1
	beam = 0

func choose(i: int) -> void:
	if int(specs[i][4]) < used():
		status = "La carga supera la capacidad de esa nave"
		return
	selected = i
	hp = stat(2)
	status = ""

func cycle_target() -> void:
	if hangar: return
	var nearby: Array[Dictionary] = []
	for i in range(rocks.size()):
		if rocks[i].hp > 0: nearby.append({"index":i,"distance":pos.distance_squared_to(rocks[i].p),"npc":false})
	for i in range(npcs.size()):
		if npcs[i].hp > 0: nearby.append({"index":i,"distance":pos.distance_squared_to(npcs[i].p),"npc":true})
	nearby.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distance < b.distance)
	if nearby.is_empty(): return
	var previous := -1
	for i in range(nearby.size()):
		var entry := nearby[i]
		if (entry.npc and not npc_target.is_empty() and is_same(npcs[entry.index],npc_target)) or (not entry.npc and entry.index == selected_target):
			previous = i
			break
	var next := nearby[(previous+1)%nearby.size()]
	selected_target = -1 if next.npc else int(next.index)
	npc_target = npcs[next.index] if next.npc else {}


func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		if event.keycode == KEY_SHIFT and event.location == KEY_LOCATION_LEFT:
			if event.pressed:
				shift_time = Time.get_ticks_msec()
				shift_scroll = false
			else:
				if shift_time >= 0 and not shift_scroll and Time.get_ticks_msec() - shift_time < 350:
					mode = (mode + 1) % MODES.size()
				shift_time = -1
		if not event.pressed:
			return
		match event.keycode:
			KEY_ENTER:
				if reset_traffic_on_launch:
					reset_traffic()
					reset_traffic_on_launch = false
				hangar = false
			KEY_H:
				help_open = not help_open
			KEY_B:
				try_dock()
			KEY_T:
				cycle_target()
			KEY_Y:
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
			KEY_G:
				cross_gate()
			KEY_N:
				if hangar: motor = not motor
			KEY_LEFT, KEY_RIGHT:
				if hangar: choose(posmod(selected + (1 if event.keycode == KEY_RIGHT else -1),17))
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
		if event.button_index == MOUSE_BUTTON_LEFT and hangar:
			for i in range(17):
				if slot(i).has_point(event.position): choose(i)
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var direction := 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1
			if shift_time >= 0:
				shift_scroll = true
				mode = posmod(mode + direction,MODES.size())
			elif not hangar:
				if mode == 2: power = clampi(power + direction * 5,0,100)
				else: zoom = clampf(zoom * pow(1.12,direction),.22,4.2)

func axis(negative: Key, positive: Key) -> int:
	return int(Input.is_key_pressed(positive)) - int(Input.is_key_pressed(negative))

func _physics_process(dt: float) -> void:
	queue_redraw()
	if map_open: return
	update_wrecks(dt)
	if hangar:
		decay_mining(dt, -1)
		return
	angle += axis(KEY_Q,KEY_E) * deg_to_rad(maxf(23,159-stat(3))) * dt
	var f := forward()
	var thrust := float(stat(1)) / stat(0) * (1.35 if motor else 1.0)
	var main := 1.0 if Input.is_key_pressed(KEY_W) else (-.5 if Input.is_key_pressed(KEY_S) else 0.0)
	vel += (f * main + f.rotated(PI/2) * axis(KEY_A,KEY_D) * .25) * thrust * dt
	vel = vel.limit_length(maxf(95,345-stat(3)*1.62))
	var manual_brake := Input.is_key_pressed(KEY_X)
	var translating := Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_D)
	if manual_brake or (coupled and not translating):
		vel = vel.move_toward(Vector2.ZERO,thrust*(1.35 if manual_brake else .65)*dt)
	var previous := pos
	pos += vel * dt
	station_contact(previous)
	if hangar: return
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
			hp -= int(impact*.38)
			rock.hp = maxi(0,rock.hp-int(impact*stat(0)/200))
		if hp <= 0:
			destroyed()
			return
	if ping < 650:
		ping = minf(650,ping+830*dt)
		for rock in rocks:
			if rock.hp > 0 and rock.p.distance_to(ping_origin) <= ping+rock.r: rock.seen = true
	missile_cooldown = maxf(0, missile_cooldown - dt)
	if mode == 1 and Input.is_key_pressed(KEY_SPACE) and missile_cooldown <= 0:
		var missile := MISSILE.instantiate()
		missile.sector = self
		missile.position = pos + f * (stat(3) / 2.0 + 9)
		missile.direction = f
		missile.rotation = angle
		missile.drift = vel
		missile_layer.add_child(missile)
		missile_cooldown = .85
	cooldown -= dt
	if mode == 0 and Input.is_key_pressed(KEY_SPACE) and cooldown <= 0:
		bullets.append({"p":pos+f*stat(3)/2.0,"v":vel+f*920,"f":f,"life":.85})
		cooldown = .075
	for i in range(bullets.size()-1,-1,-1):
		var shot: Dictionary = bullets[i]
		var next: Vector2 = shot.p + shot.v*dt
		var hit := ray_rock(shot.p, next)
		var contact := ray_npc(shot.p,next,hit.y)
		var debris := ray_wreck(shot.p,next,contact.y)
		if debris.x >= 0:
			destroy_wreck(int(debris.x))
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
	if not hangar: update_traffic(dt)
	if hangar: return
	if not npc_target.is_empty() and (npc_target.hp <= 0 or not npcs.has(npc_target)): npc_target = {}
	for i in range(fragments.size()-1,-1,-1):
		var item: Dictionary = fragments[i]
		if pos.distance_to(item.p) <= stat(3)*.32+16 and used()+item.amount <= stat(4):
			cargo[item.resource] += item.amount
			status = "%s: %d U en bodega" % [RES[item.resource],cargo[item.resource]]
			fragments.remove_at(i)

func _process(_dt: float) -> void:
	missile_layer.position = get_viewport_rect().size / 2 - pos * zoom
	missile_layer.scale = Vector2.ONE * zoom

func clear_missiles() -> void:
	for missile in missile_layer.get_children():
		missile_layer.remove_child(missile)
		missile.queue_free()
	missile_cooldown = 0

func missile_impact(at: Vector2, direct: int, damage: int, radius: float, direct_npc: int = -1, direct_wreck: int = -1) -> void:
	var items: Array = wreck_fields[sector]
	for i in range(items.size()-1,-1,-1):
		if i == direct_wreck or at.distance_to(items[i].p) < radius+wreck_radius(items[i]):
			destroy_wreck(i)
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
	wreck_ship(pos,selected,true)
	rescue_dock()
	status = "Nave destruida. Repuesta en el hangar."

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

func update_mining(dt: float, f: Vector2) -> void:
	target = -1
	beam = 0
	if mode != 2 or not Input.is_key_pressed(KEY_SPACE): return
	mining_time += dt
	var start := pos+f*stat(3)/2.0
	var hit := ray_rock(start,start+f*stat(3))
	target = int(hit.x)
	beam = hit.y*stat(3)
	if target < 0: return
	var rock: Dictionary = rocks[target]
	if power == 100:
		drop(rock,1)
		hp -= ceili(stat(2)*.25)
		status = "Sobrecarga: 10% recuperable"
		if hp <= 0: destroyed()
	elif absf(power/100.0-window_center(rock)) <= .10:
		rock.progress += dt/3
		if rock.progress >= 1:
			drop(rock,10)
			status = "Extracción completa"
	else:
		rock.progress = maxf(0,rock.progress-dt*.25)

func asteroid_size(radius: int) -> int:
	return clampi(floori((radius - 12) / 7.0), 0, 4)

func drop(rock: Dictionary, amount: int) -> void:
	rock.hp = 0
	target = -1
	var count := 2 + asteroid_size(rock.r) * 2
	for i in range(count):
		fragments.append({"p":rock.p+Vector2.RIGHT.rotated(i*TAU/count)*rock.r*.65,
			"resource":rock.second if rock.second >= 0 and i%2 == 1 else rock.first,"amount":amount})

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
		for rock in fields[i]: field.append([rock.hp,rock.seen,rock.progress])
		all_fields.append(field)
		var loot: Array = []
		for item in sector_loot[i]: loot.append([item.p.x,item.p.y,item.resource,item.amount])
		all_loot.append(loot)
		var wrecks: Array = []
		for item in wreck_fields[i]: wrecks.append([item.p.x,item.p.y,item.sprite,item.angle,item.progress])
		saved_wrecks.append(wrecks)
	file.store_string(JSON.stringify({"ship":selected,"paint":paint,"mode":mode,"motor":motor,"coupled":coupled,"hangar":hangar,"dock_station":dock_station,"dock_port":dock_port,"station_hp":stations[0].hp,"station_reserve":station_reserve,
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
				wreck_fields[index].append({"p":Vector2(item[0],item[1]),"sprite":int(item[2]),"angle":item[3],"progress":item[4]})
		var saved_field: Array = data.fields[index] if data.has("fields") else (data.field if index == sector else [])
		var loot: Array = data.sector_loot[index] if data.has("sector_loot") else (data.loot if index == sector else [])
		if saved_field.size() == fields[index].size():
			for i in range(saved_field.size()):
				fields[index][i].hp = int(saved_field[i][0])
				fields[index][i].seen = saved_field[i][1]
				fields[index][i].progress = saved_field[i][2]
		for item in loot:
			sector_loot[index].append({"p":Vector2(item[0],item[1]),"resource":int(item[2]),"amount":int(item[3])})
	rocks = fields[sector]
	fragments = sector_loot[sector]
	bullets.clear()
	clear_missiles()
	ping = 1000
	target = -1
	beam = 0
	selected_target = -1
	stations[0].hp = clampi(int(data.get("station_hp",26000)),1,26000)
	station_reserve = maxi(0,int(data.get("station_reserve",0)))
	if hangar:
		var saved_dock := int(data.get("dock_station",-1))
		if saved_dock >= 0 and saved_dock < stations.size() and stations[saved_dock].sector == sector:
			dock_at(saved_dock,clampi(int(data.get("dock_port",0)),0,7))
		else:
			rescue_dock()
	reset_traffic()
	explosions.clear()
	salvage_target = -1
	salvage_length = 0
	status = "Partida cargada"

func label(at: Vector2, value: String, size: int = 15, color: Color = Color.WHITE) -> void:
	draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func slot(i: int) -> Rect2:
	var width := (get_viewport_rect().size.x-40)/9
	return Rect2(20+(i%9)*width,get_viewport_rect().size.y-124+floori(i/9.0)*44,width-4,40)

func sprite(i: int, at: Vector2, height: float, tint: Color) -> void:
	var size := Vector2(height*ships[i].get_width()/ships[i].get_height(),height)
	draw_texture_rect(ships[i],Rect2(at-size/2,size),false,tint)

func _draw() -> void:
	var screen := get_viewport_rect().size
	var center := screen/2
	draw_texture_rect(soft_sky if hangar and soft_sky != null else STAR_FIELD,Rect2(Vector2.ZERO,screen),not hangar)
	if ships.is_empty(): return
	if hangar:
		draw_docked_background(screen)
		for i in range(-5,6):
			draw_line(center+Vector2(i*24,-120),center+Vector2(i*24,120),Color("#283449"))
			draw_line(center+Vector2(-120,i*24),center+Vector2(120,i*24),Color("#283449"))
		sprite(selected,center,160,PAINT[paint])
		for i in range(17):
			var rect := slot(i)
			draw_rect(rect,Color.TURQUOISE if i == selected else Color.DIM_GRAY,false)
			sprite(i,rect.get_center(),30,Color.WHITE)
			label(rect.position+Vector2(4,14),str(i+1),12)
	else:
		draw_set_transform(center-pos*zoom,0,Vector2.ONE*zoom)
		draw_stations()
		for i in range(rocks.size()):
			var rock: Dictionary = rocks[i]
			if rock.hp <= 0 or absf(rock.p.x-pos.x) > center.x/zoom+150 or absf(rock.p.y-pos.y) > center.y/zoom+90: continue
			var texture := asteroid_sprites[asteroid_size(rock.r) * 2 + i % 2]
			var extent: Vector2 = Vector2.ONE * rock.r
			draw_texture_rect(texture, Rect2(rock.p - extent, extent * 2), false)
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
				draw_rect(Rect2(right-Vector2(2,h*(window_center(rock)+.1)),Vector2(10,h*.2)),Color.TURQUOISE,false)
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
				draw_line(npc.p,npc.end,Color.GOLD if npc.role == "Minero" else Color.ORANGE_RED,2)
			draw_set_transform(center+(npc.p-pos)*zoom,npc.angle,Vector2.ONE*zoom)
			sprite(npc.ship,Vector2.ZERO,int(specs[npc.ship][3]),Color.WHITE)
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
		if salvage_length > 0 and mode == 4 and Input.is_key_pressed(KEY_SPACE):
			var origin := pos+forward()*stat(3)/2.0
			var finish := origin+forward()*salvage_length
			draw_line(origin,finish,Color.FOREST_GREEN,5)
			draw_line(origin,finish,Color.PALE_GREEN,2)
		draw_explosions(center,false)
		for item in fragments:
			draw_circle(item.p,5,Color.SLATE_GRAY)
			draw_rect(Rect2(item.p-Vector2(2,2),Vector2(4,4)),Color.TURQUOISE)
		for shot in bullets: draw_line(shot.p,shot.p-shot.f*20,Color.KHAKI,2)
		if ping > 0 and ping < 650:
			draw_arc(ping_origin,ping,0,TAU,96,Color(0.25,0.9,0.8,1-ping/650),2)
		var nose := pos+forward()*stat(3)/2.0
		if beam > 0:
			draw_line(nose,nose+forward()*beam,Color.GOLD,5)
			draw_line(nose,nose+forward()*beam,Color.WHITE,2)
		draw_set_transform(center,angle,Vector2.ONE*zoom)
		if Input.is_key_pressed(KEY_W):
			var tail := stat(3)/2.0
			var flame := 10.0+fmod(Time.get_ticks_msec()/35.0,8.0)
			draw_rect(Rect2(-3,tail-2,6,flame),Color.ORANGE_RED)
			draw_rect(Rect2(-1,tail-2,2,flame*.75),Color.GOLD)
		sprite(selected,Vector2.ZERO,stat(3),PAINT[paint])
		draw_set_transform(Vector2.ZERO)
	if hangar: draw_explosions(center,true)
	label(Vector2(20,34),"HANGAR ORBITAL / GODOT 0.0.23" if hangar else "SECTOR %d / 10.000 × 10.000" % (4107+sector),23,Color.TURQUOISE)
	label(Vector2(20,62),"H Controles   M Mapa estelar")
	label(Vector2(20,86),"Nave %d   Masa %d   Empuje %d   Casco %d/%d   Bodega %d/%d U" % [selected+1,stat(0),stat(1),hp,stat(2),used(),stat(4)])
	if hangar:
		label(Vector2(20,137),stations[dock_station].name+"  ·  Puerto "+str(dock_port+1)+"  ·  Enter despegar",15,Color.PALE_GREEN)
		label(Vector2(20,158),"Reserva minera de la estación: %d U" % station_reserve,15,Color.PALE_GREEN)
		var ship_class := "Mediana" if stat(3) < 90 else ("Grande" if stat(3) < 125 else "Muy grande")
		label(Vector2(20,110),"%s | Slots: Arm. %d  Def. %d  Util. %d  Motor %d" %
			[ship_class,stat(5),stat(6),stat(7),stat(8)],15,Color.TURQUOISE)
		label(Vector2(20,screen.y-246),"Inventario del jugador",16,Color.TURQUOISE)
		for i in range(RES.size()):
			label(Vector2(20+(i%2)*195,screen.y-226+floori(i/2.0)*19),
				"%s  %d U" % [RES[i],inventory[i]],13)
	else:
		label(Vector2(20,182),"Coupled [C]" if coupled else "Decoupled [C]",15,Color.TURQUOISE)
		label(Vector2(20,110),"%s   Vel %d   %s" % [MODES[mode],int(vel.length()),"Potencia %d%%" % power if mode == 2 else ""])
		if mode == 1 and shift_time < 0:
			label(Vector2(20,134),"Misil listo" if missile_cooldown <= 0 else "Recargando misil %.1f s" % missile_cooldown,15,Color.GOLD)
		if shift_time >= 0: label(Vector2(20,134)," / ".join(MODES),15,Color.TURQUOISE)
	label(Vector2(20,screen.y-18),status,15,Color.TURQUOISE)
	if not hangar and selected_target >= 0:
		label(Vector2(20,158),"Objetivo: asteroide a %d" % pos.distance_to(rocks[selected_target].p),15,Color.GOLD)
	if not hangar and not npc_target.is_empty():
		label(Vector2(20,158),"Objetivo: %s a %d" % [npc_target.role,pos.distance_to(npc_target.p)],15,Color.GOLD)
	if not hangar and not trader.is_empty() and trader.hp > 0:
		var delta: Vector2 = (trader.p-pos)*zoom
		var edge := maxf(absf(delta.x)/(center.x-35),absf(delta.y)/(center.y-35))
		if edge > 1:
			var tip := center+delta/edge
			var direction := delta.normalized()
			var side := direction.orthogonal()
			draw_colored_polygon(PackedVector2Array([tip+direction*11,tip-direction*7+side*8,tip-direction*7-side*8]),Color.TURQUOISE)
	draw_maps(screen)
	if help_open:
		var panel := Rect2(center-Vector2(265,174),Vector2(530,348))
		draw_rect(panel,Color("#151d38"))
		draw_rect(panel,Color.TURQUOISE,false)
		var lines := ["CONTROLES   |   H Cerrar",
			"Enter Despegar   B Atracar   U Descargar",
			"W/S Empuje   A/D Lateral   Q/E Giro   X Freno",
			"C Alternar Coupled / Decoupled",
			"Tab Ping   T Siguiente objetivo   Y Deseleccionar",
			"Mayús izq Modo   Mantener + rueda Elegir modo",
			"Espacio Disparar, minar o recuperar   Rueda Zoom",
			"Minería: rueda u O/L para ajustar potencia",
			"Hangar: clic/flechas Nave   P Color   N Motor",
			"F5 Guardar   F9 Cargar","M Mapa estelar   G Saltar por puerta"]
		for i in range(lines.size()):
			label(panel.position+Vector2(20,30+i*28),lines[i],15,Color.TURQUOISE if i == 0 else Color.WHITE)
