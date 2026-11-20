extends SceneTree
class TestGame extends "res://Godot/game.gd":
    func save_path() -> String: return "user://industry-regression.json"
var failures: Array[String] = []
func check(ok: bool, text: String) -> void:
    if not ok: failures.append(text)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    if FileAccess.file_exists("user://industry-regression.json"): DirAccess.remove_absolute("user://industry-regression.json")
    var game := TestGame.new()
    root.add_child(game)
    game.set_process(false)
    check(game.RES.size() == 88 and game.industry.recipes.size() == 65,"catalogs")
    for field in game.fields:
        var count := 0
        for rock in field:
            check(rock.first not in game.SPECIAL_ORES and rock.second not in game.SPECIAL_ORES,"ordinary composition")
            if int(rock.get("special_amount",0)) > 0:
                count += 1
                check(rock.hp > 0 and rock.special_amount <= 3 and not rock.seen and not rock.special_seen,"hidden active deposit")
        check(count >= 3 and count <= 7,"deposits per sector")
    for station in game.stations:
        check(station.modules[11] == 0,"detector unavailable")
    check(game.module_types.count(11) == 0 and game.module_stock[11] == 0 and game.nacar_modules[11] == 0,"no detector")
    game.hangar = true
    for i in range(65):
        var recipe: Dictionary = game.industry.recipes[i]
        game.inventory.fill(0)
        game.industry.remainders.fill(0)
        var before := game.inventory.duplicate()
        check(not game.industry.craft(game,i,1) and game.inventory == before,"atomic insufficient")
        for pair in recipe.inputs: game.inventory[pair.x] += pair.y*10
        check(game.industry.craft(game,i,10),"batch recipe %d" % i)
        for pair in recipe.inputs: check(game.inventory[pair.x] == 0,"consumed inputs")
        for pair in recipe.outputs: check(game.inventory[pair.x]*10000+game.industry.remainders[pair.x] == game.industry.output_units(game.dock_station,recipe,pair.y,10),"produced outputs")
    game.dock_station = 0
    game.inventory.fill(0)
    game.industry.remainders.fill(0)
    game.inventory[5] = 10
    check(game.industry.craft(game,5,1) and game.inventory[26] == 7 and game.industry.remainders[26] == 6000,"copper 7.6 at 80%")
    game.industry.efficiencies[0] = Vector2i(10000,10000)
    game.inventory[5] = 10
    game.inventory[26] = 0
    game.industry.remainders[26] = 0
    check(game.industry.craft(game,5,1) and game.inventory[26] == 9 and game.industry.remainders[26] == 5000,"copper 9.5 at 100%")
    game.industry.efficiencies[0] = Vector2i(8000,8000)
    game.inventory[5] = 100
    game.inventory[26] = 0
    game.industry.remainders[26] = 0
    for i in range(10): game.industry.craft(game,5,1)
    check(game.inventory[26] == 76 and game.industry.remainders[26] == 0,"batch-independent fractions")
    game.inventory.fill(0)
    game.industry.remainders.fill(0)
    for pair in game.industry.recipes[52].inputs: game.inventory[pair.x] = pair.y*3
    game.industry.craft(game,52,1)
    check(game.inventory[75] == 1 and game.industry.remainders[75] == 0,"manufacturing has no loss")
    game.industry.craft(game,52,1)
    check(game.inventory[75] == 2 and game.industry.remainders[75] == 0,"manufacturing whole outputs")
    game.inventory.fill(0)
    game.industry.remainders.fill(0)
    game.inventory[0] = 20
    check(game.industry.craft(game,0,2) and game.industry.craft(game,21,1),"water processing")
    check(game.inventory[21] == 6 and game.industry.remainders[21] == 2000 and game.inventory[42] == 1 and game.industry.remainders[42] == 0 and game.inventory[43] == 8 and game.industry.remainders[43] == 0,"refining at 80%, processing at 100%")
    game.industry.efficiencies[0] = Vector2i(8000,0)
    for stage in ["Procesamiento","Fabricacion","Ensamblaje"]: check(game.industry.efficiency(0,stage) == 10000,"only refining can have losses")
    game.industry.efficiencies[0] = Vector2i(8000,10000)
    var fuels := 0
    var ice := 0
    for index in range(100):
        for rock in game.generate_field(index):
            if rock.first in [71,72]: fuels += 1
            if game.sector_specs[index].ice and rock.first < 2: ice += 1
    check(fuels > 0 and fuels < 640 and ice == 17*512,"scarce fuels and ice ratio")
    check(game.industry.stock(20)[71] == 0 and game.industry.stock(20)[72] == 0,"rare fuels not sold by default")
    game.hangar = false
    check(not game.industry.craft(game,0,1),"no remote crafting")
    var chosen: Dictionary = {}
    for rock in game.rocks:
        if int(rock.get("special_amount",0)) > 0: chosen = rock; break
    check(not chosen.is_empty(),"deposit found")
    game.selected = 0
    game.module_types.clear()
    game.module_locations.clear()
    game.ping = 0
    game.ping_origin = chosen.p
    game._physics_process(.1)
    check(chosen.seen and not chosen.special_seen,"normal scan hides specials")
    game.module_types.assign([11])
    game.module_locations.assign([game.slot_location(2,0,0)])
    game.ping = 0
    game._physics_process(.1)
    check(chosen.special_seen,"detector rescans known asteroid")
    game.module_types.clear()
    game.module_locations.clear()
    var kind: int = chosen.special_kind
    var amount: int = chosen.special_amount
    var fragments_before := game.fragments.size()
    game.drop(chosen,10)
    check(chosen.special_amount == 0 and game.fragments[fragments_before].resource == kind and game.fragments[fragments_before].amount == amount,"special mining")
    chosen.hp = game.ROCK_HP
    game.drop(chosen,10)
    var special_drops := 0
    for fragment in game.fragments:
        if fragment.resource in game.SPECIAL_ORES: special_drops += fragment.amount
    check(special_drops == amount,"no repeated special reward")
    for field in game.fields:
        for rock in field: rock.special_amount = 0
    game.update_asteroid_respawn(300)
    for field in game.fields:
        for rock in field: check(int(rock.get("special_amount",0)) == 0,"respawn cannot replenish specials")
    game.industry.remainders[26] = 6000
    game.inventory[70] = 5
    game.cargo[20] = 2
    game.save_game()
    game.load_game()
    check(game.inventory[70] == 5 and game.cargo[20] == 2 and game.industry.remainders[26] == 6000,"expanded save")
    var new_deposits := 0
    for rock in game.rocks:
        if int(rock.get("special_amount",0)) > 0: new_deposits += 1
    check(new_deposits >= 3,"load refreshes deposits")
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_path()))
    data.erase("industry_remainders")
    data.inventory = data.inventory.slice(0,71)
    data.cargo = data.cargo.slice(0,71)
    var previous := FileAccess.open(game.save_path(),FileAccess.WRITE)
    previous.store_string(JSON.stringify(data)); previous.close()
    game.load_game()
    check(game.inventory.size() == 88 and game.inventory[70] == 5 and game.inventory[87] == 0 and game.industry.remainders[26] == 0,"0.1.10 migration")
    data.inventory = [1,2,3,4,5,6,7,8,9,10]
    data.cargo = [1,0,0,0,0,0,0,0,0,0]
    data.mineral_stock = [20,20,20,20,20,20,20,20,20,20]
    data.nacar_stock = data.mineral_stock
    data.module_stock = [2,2,2,2,2,2,2,2,2,2,2]
    data.nacar_modules = data.module_stock
    var file := FileAccess.open(game.save_path(),FileAccess.WRITE)
    file.store_string(JSON.stringify(data)); file.close()
    game.load_game()
    check(game.inventory.size() == 88 and game.inventory[9] == 10 and game.inventory[70] == 0 and game.cargo[0] == 1 and game.industry.remainders[26] == 0,"legacy inventory prefix")
    check(game.nacar_modules[11] == 0 and game.module_stock[11] == 0,"legacy detector absent")
    print("INDUSTRY_REGRESSION ","PASS" if failures.is_empty() else failures)
    game.queue_free()
    quit(0 if failures.is_empty() else 1)
