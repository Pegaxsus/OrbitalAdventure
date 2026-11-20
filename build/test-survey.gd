extends SceneTree
class TestGame extends "res://Godot/game.gd":
    func save_path() -> String: return "user://survey-regression.json"
var failures: Array[String] = []
func check(ok: bool, text: String) -> void:
    if not ok: failures.append(text)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    if FileAccess.file_exists("user://survey-regression.json"): DirAccess.remove_absolute("user://survey-regression.json")
    var game := TestGame.new()
    root.add_child(game)
    game.set_physics_process(false)
    check(game.stations.size() == 16 and game.stations[15].sector == 29 and game.stations[15].name == "Estación Umbral","E7 station")
    check(game.sector_specs[29].station,"station flag")
    check(game.stations[15].modules[13] == 2,"spectrometer market")
    check(game.survey.material_art.size() == 23,"all ore sprites")
    for profile in game.survey.layers:
        check(game.survey.layers[profile].size() == 3,"three layers "+profile)
    var giants := 0
    for local in range(100):
        var large := 0
        for rock in game.fields[local]:
            if rock.r >= 150:
                large += 1
                check(rock.r <= 240 and absf(rock.p.x)+rock.r < 5000 and absf(rock.p.y)+rock.r < 5000,"giant bounds")
                check(game.survey.pieces(rock) >= 24,"giant yield")
        check(large == 2+local%3,"giant frequency")
        giants += large
    check(giants == 299,"299 giants")
    for edge in range(game.links.size()):
        for local in [game.links[edge].x,game.links[edge].y]:
            var gate: Vector2 = game.gate_position(edge,local)
            var margin := 5000-maxf(absf(gate.x),absf(gate.y))-67
            check(margin >= 200 and margin <= 500,"gate margin")
            for rock in game.fields[local]:
                if rock.hp > 0: check(rock.p.distance_to(gate) >= rock.r+300,"gate clear")
    var sample: Array = [
        {"p":Vector2(1000,1000),"r":12,"hp":2400,"first":2,"second":5,"special_kind":19,"special_amount":3,"special_seen":false},
        {"p":Vector2(2000,2000),"r":150,"hp":2400,"first":2,"second":-1},
        {"p":Vector2(3000,3000),"r":240,"hp":0,"first":71,"second":-1}]
    var sums: Dictionary = game.survey.sector_totals(sample)
    check(sums.size() == 3 and sums[2] == 250 and sums[5] == 10 and sums[19] == 3,"exact aggregate")
    game.rocks = sample
    game.module_types.assign([13])
    game.module_locations.assign([0])
    game.survey.finish_scan(game)
    check(not game.survey.open,"inventory does not activate")
    game.module_locations[0] = game.utility_location(0,game.selected)
    game.survey.finish_scan(game)
    check(game.survey.open and game.survey.totals == sums,"equipped activates")
    check(not sample[0].special_seen,"no special location reveal")
    var close := InputEventKey.new()
    close.keycode = KEY_ESCAPE
    close.pressed = true
    game._input(close)
    check(not game.survey.open,"close report")
    game.market = 2
    game.dock_station = 15
    game.credits = 2600
    game.object_quantities[13] = 1
    game.trade(13,true)
    check(game.credits == 0 and game.stations[15].modules[13] == 1,"buy spectrometer")
    game.rocks = game.fields[game.sector]
    game.save_game()
    game.load_game()
    check(game.module_types.has(13) and game.stations[15].modules[13] == 1,"persist station and module")
    var file := FileAccess.open(game.save_path(),FileAccess.READ)
    var old_save: Dictionary = JSON.parse_string(file.get_as_text())
    file.close()
    old_save.erase("geology_version")
    old_save.fields[29][620][3] = 0
    old_save.fields[29][620][4] = 0
    file = FileAccess.open(game.save_path(),FileAccess.WRITE)
    file.store_string(JSON.stringify(old_save))
    file.close()
    game.load_game()
    check(game.fields[29][620].p == game.generate_field(29)[620].p,"legacy giant position migration")
    print("SURVEY_REGRESSION ","PASS giants=299 gates=232 materials=23" if failures.is_empty() else failures)
    game.queue_free()
    quit(0 if failures.is_empty() else 1)
