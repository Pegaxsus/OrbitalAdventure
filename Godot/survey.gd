extends RefCounted

var material_art: Dictionary = {}
var layers: Dictionary = {}
var open := false
var totals: Dictionary = {}
var report_sector := ""

func initialize(game) -> void:
	for line in FileAccess.get_file_as_string("res://data/asteroid-materials.txt").strip_edges().split("\n").slice(1):
		var row = line.strip_edges().split(",")
		var path = "res://assets/asteroids/materials/"+row[2]
		if ResourceLoader.exists(path):
			var texture: Texture2D = load(path)
			var image := texture.get_image()
			var cropped := image.get_region(image.get_used_rect())
			var factor := 256.0/maxi(cropped.get_width(),cropped.get_height())
			cropped.resize(maxi(1,int(cropped.get_width()*factor)),maxi(1,int(cropped.get_height()*factor)),Image.INTERPOLATE_LANCZOS)
			material_art[int(row[0])] = ImageTexture.create_from_image(cropped)
	var profiles = {}
	for profile in game.sector_backgrounds.values(): profiles[profile.id] = profile
	for line in FileAccess.get_file_as_string("res://data/background-layers.txt").strip_edges().split("\n").slice(1):
		var row = line.strip_edges().split(",")
		if not profiles.has(row[1]): continue
		if not layers.has(row[0]): layers[row[0]] = []
		layers[row[0]].append({"profile":profiles[row[1]],"offset":Vector2(float(row[2]),float(row[3])),"scale":float(row[4]),"parallax":float(row[5]),"angle":deg_to_rad(float(row[6])),"opacity":float(row[7])})

func draw_background(game, center: Vector2) -> void:
	var background = game.sector_backgrounds.get(4107+game.sector,{})
	if background.is_empty(): return
	var scale = sqrt(game.zoom)
	for layer in layers.get(background.id,[]):
		var profile = layer.profile
		var size = profile.size*scale*layer.scale
		var at = center+(background.anchor+layer.offset-game.pos)*background.parallax*layer.parallax*scale
		game.draw_set_transform(at,layer.angle)
		game.draw_texture_rect(profile.texture,Rect2(-size/2,size),false,Color(1,1,1,background.opacity*layer.opacity))
	game.draw_set_transform(Vector2.ZERO)

func add_giants(field: Array, sector: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 93017+sector*174013
	for n in range(2+sector%3):
		var index = 620+n*4
		var radius = rng.randi_range(150,240)
		var point = Vector2.ZERO
		for attempt in range(100):
			point = Vector2(rng.randi_range(2700,4400)*(1 if n%2 == 0 else -1),rng.randi_range(2600,4400)*(1 if n < 2 else -1))
			var clear = true
			for i in range(field.size()):
				if i != index and point.distance_to(field[i].p) < radius+field[i].r+20: clear = false; break
			if clear: break
		field[index].p = point
		field[index].r = radius

func pieces(rock: Dictionary) -> int:
	return 24+2*floori((rock.r-150)/20.0) if rock.r >= 150 else 2+2*clampi(floori((rock.r-12)/7.0),0,4)

func clear_gate_approaches(game) -> void:
	for local in range(game.fields.size()):
		for edge in range(game.links.size()):
			if local not in [game.links[edge].x,game.links[edge].y]: continue
			var gate = game.gate_position(edge,local)
			for rock in game.fields[local]:
				if rock.p.distance_to(gate) < rock.r+300:
					rock.hp = 0
					rock.mined = false

func finish_scan(game) -> void:
	if game.module_count(13) <= 0: return
	totals = sector_totals(game.rocks)
	report_sector = game.sector_name(game.sector)
	open = true

func sector_totals(rocks: Array) -> Dictionary:
	var result = {}
	for rock in rocks:
		if rock.hp <= 0: continue
		var count = pieces(rock)
		var first = count*10 if rock.second < 0 else count*5
		result[rock.first] = int(result.get(rock.first,0))+first
		if rock.second >= 0: result[rock.second] = int(result.get(rock.second,0))+count*5
		if int(rock.get("special_amount",0)) > 0:
			result[rock.special_kind] = int(result.get(rock.special_kind,0))+int(rock.special_amount)
	return result

func close_rect(screen: Vector2) -> Rect2:
	return Rect2(screen/2+Vector2(263,-225),Vector2(100,30))

func draw(game, screen: Vector2) -> void:
	if not open: return
	var at = screen/2-Vector2(380,240)
	game.draw_rect(Rect2(at,Vector2(760,480)),Color("#08111f"))
	game.draw_rect(Rect2(at,Vector2(760,480)),Color.TURQUOISE,false)
	game.label(at+Vector2(18,32),"ESPECTRÓMETRO · "+report_sector,20,Color.TURQUOISE)
	game.menu_button(close_rect(screen),"Cerrar")
	game.label(at+Vector2(18,64),"Reservas restantes · sin coordenadas · extracción ideal",14)
	var keys = totals.keys()
	keys.sort()
	if keys.is_empty(): game.label(at+Vector2(18,110),"No quedan materiales en los asteroides del sector.",16)
	for i in range(keys.size()):
		var key = keys[i]
		var p = at+Vector2(20+(i/12)*370,98+(i%12)*29)
		if material_art.has(key): game.draw_texture_rect(material_art[key],Rect2(p-Vector2(0,17),Vector2(22,22)),false)
		game.label(p+Vector2(29,0),game.RES[key],15)
		game.label(p+Vector2(258,0),str(totals[key])+" U",15,Color.PALE_GREEN)
	game.label(at+Vector2(18,462),"Incluye trazas especiales. TAB normal no revela su ubicación. Esc cierra.",13,Color.TURQUOISE)
