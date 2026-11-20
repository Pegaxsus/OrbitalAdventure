extends RefCounted

var materials: Array[Dictionary] = []
var recipes: Array[Dictionary] = []
var names: Array[String] = []
var prices: Array[int] = []
const SCALE := 10000
const RECOVERY := 9500
var remainders: Array[int] = []
var efficiencies: Dictionary = {}
var open := false
var tab := 0
var page := 0
var selected := 0
var message := "Descarga la bodega con U. Fabricación por lotes en estación."
const SIZE := Vector2(900,500)

func _init() -> void:
    for line in FileAccess.get_file_as_string("res://data/materials.txt").strip_edges().split("\n").slice(1):
        var row := line.strip_edges().split(",")
        materials.append({"id":int(row[0]),"key":row[1],"name":row[2],"category":row[3],"stage":row[4],"rarity":row[6]})
        names.append(row[2])
        prices.append(int(row[5]))
    remainders.resize(materials.size())
    remainders.fill(0)
    for line in FileAccess.get_file_as_string("res://attributes/station-industry.txt").strip_edges().split("\n").slice(1):
        var row := line.strip_edges().split(",")
        efficiencies[int(row[0])] = Vector2i(clampi(int(row[1]),0,100)*100,clampi(int(row[2]),0,100)*100)
    for line in FileAccess.get_file_as_string("res://data/recipes.txt").strip_edges().split("\n").slice(1):
        var row := line.strip_edges().split(",")
        recipes.append({"name":row[2],"stage":row[3],"inputs":pairs(row[4]),"outputs":pairs(row[5])})

func pairs(text: String) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for entry in text.split("|"):
        var parts := entry.split(":")
        result.append(Vector2i(int(parts[0]),int(parts[1])))
    return result

func stock(amount: int) -> Array[int]:
    var result: Array[int] = []
    for item in materials: result.append(amount if item.stage == "bruto" and item.rarity == "comun" else 0)
    return result

func extend(values: Array, fill: int = 0) -> Array[int]:
    var result: Array[int] = []
    for i in range(names.size()): result.append(maxi(0,int(values[i])) if i < values.size() else fill)
    return result

func efficiency(station: int, stage: String) -> int:
    if stage != "Refinado": return SCALE
    var rates: Vector2i = efficiencies.get(station,Vector2i(8000,8000))
    return rates.x if stage == "Refinado" else rates.y

func output_units(station: int, recipe: Dictionary, quantity: int, batches: int = 1) -> int:
    var recovery := RECOVERY if recipe.stage == "Refinado" else SCALE
    return quantity*batches*recovery*efficiency(station,recipe.stage)/SCALE

func amount_text(scaled: int) -> String:
    var whole := str(scaled/SCALE)
    var fraction := scaled%SCALE
    if fraction == 0: return whole
    return whole+","+("%04d" % fraction).trim_suffix("0").trim_suffix("0").trim_suffix("0")

func load_remainders(values: Variant) -> void:
    remainders.fill(0)
    if not values is Array: return
    for i in range(mini(values.size(),remainders.size())): remainders[i] = clampi(int(values[i]),0,SCALE-1)

func craft(game, recipe_id: int, batches: int) -> bool:
    if not game.hangar or recipe_id < 0 or recipe_id >= recipes.size() or batches < 1 or batches > 10: return false
    var recipe: Dictionary = recipes[recipe_id]
    if efficiency(game.dock_station,recipe.stage) <= 0:
        message = "La estación no dispone de este servicio."
        return false
    for pair in recipe.inputs:
        if game.inventory[pair.x] < pair.y*batches:
            message = "Falta %s: necesitas %d U." % [names[pair.x],pair.y*batches]
            return false
    for pair in recipe.outputs:
        var total := remainders[pair.x]+output_units(game.dock_station,recipe,pair.y,batches)
        if game.inventory[pair.x] > 999999999-total/SCALE:
            message = "Límite de almacenamiento alcanzado."
            return false
    for pair in recipe.inputs: game.inventory[pair.x] -= pair.y*batches
    var delivered: Array[String] = []
    for pair in recipe.outputs:
        var produced := output_units(game.dock_station,recipe,pair.y,batches)
        var total := remainders[pair.x]+produced
        game.inventory[pair.x] += total/SCALE
        remainders[pair.x] = total%SCALE
        delivered.append(amount_text(produced)+" U "+names[pair.x])
    message = "Producido: "+" + ".join(delivered)+" · fracciones conservadas"
    return true

func input(game, event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ESCAPE: open = false
        elif event.keycode == KEY_U: game.unload_cargo()
    if not event is InputEventMouseButton or not event.pressed: return
    var at: Vector2 = (game.get_viewport_rect().size-SIZE)/2
    var point: Vector2 = event.position-at
    var count := recipes.size() if tab == 0 else materials.size()
    if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
        page = clampi(page+(1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1),0,(count-1)/10)
        return
    if event.button_index != MOUSE_BUTTON_LEFT: return
    if Rect2(770,10,110,34).has_point(point): open = false
    elif Rect2(20,53,150,30).has_point(point): tab = 0; page = 0
    elif Rect2(180,53,150,30).has_point(point): tab = 1; page = 0
    elif Rect2(20,440,100,30).has_point(point): page = maxi(0,page-1)
    elif Rect2(280,440,100,30).has_point(point): page = mini((count-1)/10,page+1)
    elif tab == 0:
        for i in range(10):
            var index := page*10+i
            if index < recipes.size() and Rect2(20,95+i*33,330,29).has_point(point): selected = index
        if Rect2(400,399,190,34).has_point(point): craft(game,selected,1)
        elif Rect2(610,399,190,34).has_point(point): craft(game,selected,10)

func draw(game, center: Vector2) -> void:
    var at: Vector2 = game.draw_menu_panel(center,SIZE,"INDUSTRIA · REFINADO Y FABRICACIÓN",message)
    game.menu_button(Rect2(at+Vector2(770,10),Vector2(110,34)),"Cerrar")
    game.menu_button(Rect2(at+Vector2(20,53),Vector2(150,30)),"Recetas",tab == 0)
    game.menu_button(Rect2(at+Vector2(180,53),Vector2(150,30)),"Materiales",tab == 1)
    var count := recipes.size() if tab == 0 else materials.size()
    for i in range(10):
        var index := page*10+i
        if index >= count: break
        var y := 95+i*33
        if tab == 0:
            game.menu_button(Rect2(at+Vector2(20,y),Vector2(330,29)),recipes[index].name,index == selected,true)
        else:
            var item: Dictionary = materials[index]
            game.label(at+Vector2(20,y+20),item.name,15)
            game.label(at+Vector2(360,y+20),amount_text(game.inventory[index]*SCALE+remainders[index])+" U",15,Color.PALE_GREEN)
            game.label(at+Vector2(510,y+20),"%s · %s" % [item.category,item.stage],14,Color.TURQUOISE)
    game.menu_button(Rect2(at+Vector2(20,440),Vector2(100,30)),"Anterior")
    game.label(at+Vector2(140,461),"Página %d / %d" % [page+1,(count-1)/10+1],14)
    game.menu_button(Rect2(at+Vector2(280,440),Vector2(100,30)),"Siguiente")
    game.label(at+Vector2(400,461),"Se utilizan unidades completas; el resto se conserva.",12)
    if tab != 0: return
    var recipe: Dictionary = recipes[selected]
    game.label(at+Vector2(400,80),recipe.name,19,Color.TURQUOISE)
    game.label(at+Vector2(400,108),recipe.stage+" · cantidades por lote",14)
    var rate := efficiency(game.dock_station,recipe.stage)
    game.label(at+Vector2(400,128),"Recuperación 95 %% · Estación %s %%" % amount_text(rate*100) if recipe.stage == "Refinado" else "Eficiencia de estación: %s %%" % amount_text(rate*100),12,Color.TURQUOISE)
    var y := 152
    game.label(at+Vector2(400,y),"REQUIERE",15,Color.TURQUOISE)
    for pair in recipe.inputs:
        y += 24
        game.label(at+Vector2(400,y),"%d × %s  (tienes %d)" % [pair.y,names[pair.x],game.inventory[pair.x]],14,Color.PALE_GREEN if game.inventory[pair.x] >= pair.y else Color.SALMON)
    y += 35
    game.label(at+Vector2(400,y),"PRODUCE",15,Color.TURQUOISE)
    for pair in recipe.outputs:
        y += 24
        game.label(at+Vector2(400,y),"%s × %s (teórico %s)" % [amount_text(output_units(game.dock_station,recipe,pair.y)),names[pair.x],amount_text(pair.y*(RECOVERY if recipe.stage == "Refinado" else SCALE))],14,Color.PALE_GREEN)
    game.label(at+Vector2(400,385),"Las fracciones se acumulan en Materiales.",12)
    var action := "Refinar" if recipe.stage == "Refinado" else ("Procesar" if recipe.stage == "Procesamiento" else "Fabricar")
    game.menu_button(Rect2(at+Vector2(400,399),Vector2(190,34)),action+" 1 lote")
    game.menu_button(Rect2(at+Vector2(610,399),Vector2(190,34)),action+" 10 lotes")
