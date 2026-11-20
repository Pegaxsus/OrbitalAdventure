extends SceneTree

class TestGame extends "res://Godot/game.gd":
    func save_path() -> String:
        return "user://cluster-regression.json"

var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
    if not ok: failures.append(message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    if FileAccess.file_exists("user://cluster-regression.json"): DirAccess.remove_absolute("user://cluster-regression.json")
    var game := TestGame.new()
    root.add_child(game)
    game.set_process(false)
    check(game.sector_specs.size() == 100 and game.links.size() == 116,"map counts")
    check(game.stations.size() == 16,"stations")
    var ice := 0
    var station_count := 0
    var entries := 0
    for index in range(100):
        var degree := 0
        for link in game.links:
            if link.x == index or link.y == index: degree += 1
        check(degree > 0 and degree <= 4,"gate degree %d" % index)
        if index >= 9 and game.sector_specs[index].station: station_count += 1
        if game.sector_specs[index].ice:
            ice += 1
            var icy := 0
            for rock in game.fields[index]:
                if rock.first <= 1:
                    icy += 1
                    check(rock.second <= 1,"mixed ice")
                else: check(rock.second == -1 or rock.second >= 2,"mixed minerals")
            check(icy == 512,"ice count")
    check(ice == 17 and station_count == 7,"cluster flags")
    for edge in range(10,116):
        var link: Vector2i = game.links[edge]
        if link.x < 9 or link.y < 9:
            entries += 1
            check(link.x == 3 or link.y == 3,"4110 entrance")
    check(entries == 2,"entrance count")
    game.sector = 3
    game.hangar = false
    game.ftl_arrival_age = 1
    var nine := -1
    var ten := -1
    for edge in range(116): game.mark_crossed(edge)
    for index in range(100):
        var distance := game.jump_distance(index)
        check(distance < 999,"connectivity")
        if distance == 9: nine = index
        if distance == 10: ten = index
    for ship in range(46):
        game.selected = ship
        check(game.ftl_range() == (9 if ship in [8,21,22,33,44,45] else 3),"range %d" % ship)
    game.selected = 44
    game.module_types.assign([10])
    game.module_locations.assign([game.slot_location(2,44,0)])
    check(nine >= 0 and ten >= 0 and game.can_ftl(nine) and not game.can_ftl(ten),"FTL boundary")
    game.request_ftl(nine)
    game.confirm_ftl()
    check(game.ftl_cooldown == 300 and game.player_shield().lock == 60,"FTL consequences")
    game.crossed = 0
    game.extra_crossings.clear()
    game.sector = 99
    game.mark_crossed(115)
    var stored := game.saved_crossings()
    game.extra_crossings.clear()
    game.restore_crossings(stored)
    check(game.crossed_link(115) and not game.crossed_link(51),"high crossing")
    check(game.resolve_sector(game.sector_name(99)) == 99,"named teleport")
    game.rocks = game.fields[99]
    game.fragments = game.sector_loot[99]
    game.hp = 100
    game.save_game()
    game.sector = 0
    game.load_game()
    check(game.sector == 99 and game.crossed_link(115),"high sector save/load")
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_path()))
    data.sector = 0
    data.field = data.fields[0]
    data.fields = data.fields.slice(0,9)
    data.sector_loot = data.sector_loot.slice(0,9)
    data.wrecks = data.wrecks.slice(0,9)
    data.extra_stations = data.extra_stations.slice(0,7)
    data.module_drops = data.module_drops.slice(0,9)
    data.erase("crossed_links")
    data.crossed = 1023
    var file := FileAccess.open(game.save_path(),FileAccess.WRITE)
    file.store_string(JSON.stringify(data))
    file.close()
    game.load_game()
    check(game.sector == 0 and game.fields.size() == 100 and game.crossed_link(9) and not game.crossed_link(115),"legacy migration")
    var route := 9
    for step in range(100):
        if route == 73: break
        var edge := game.route_edge(route,73)
        check(edge >= 0,"freight route")
        if edge < 0: break
        route = game.links[edge].y if game.links[edge].x == route else game.links[edge].x
    check(route == 73,"freight arrival")
    print("CLUSTER_REGRESSION ","PASS" if failures.is_empty() else failures)
    game.queue_free()
    quit(0 if failures.is_empty() else 1)
