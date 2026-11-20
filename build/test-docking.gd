extends SceneTree
class TestGame extends "res://Godot/game.gd":
    func save_path() -> String: return "user://docking-regression.json"
var failures: Array[String] = []
var manual := 0
var assisted := 0
func check(ok: bool, text: String) -> void:
    if not ok: failures.append(text)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var game := TestGame.new()
    root.add_child(game)
    game.set_physics_process(false)
    for station in game.stations: check(station.mask.get_size() == station.art.get_image().get_size(),"native station mask preserved")
    for ship in range(46):
        game.selected = ship
        for index in range(game.stations.size()):
            var station: Dictionary = game.stations[index]
            game.sector = station.sector
            var ports := game.docking_ports(station)
            check(not ports.is_empty(),"no port ship %d station %d" % [ship,index])
            for port in ports:
                var axis: Vector2 = game.port_axis(port,station)
                for reversed in [false,true]:
                    game.hangar = false
                    game.pos = game.port_center(station,port)
                    game.vel = Vector2.ZERO
                    game.angle = axis.angle()+PI/2+(PI if reversed else 0)
                    check(game.dock_coverage(Vector2.ZERO,axis,game.port_dimensions(port,station)) >= .89999,"coverage")
                    check(not game.station_contact(game.pos-Vector2.ONE),"collision ship %d station %d port %d reverse %s" % [ship,index,port,reversed])
                    game.try_dock()
                    check(game.hangar and game.dock_station == index and game.dock_port == port,"manual ship %d station %d port %d" % [ship,index,port])
                    manual += 1
            if ports.is_empty(): continue
            var port: int = ports[0]
            var axis: Vector2 = game.port_axis(port,station)
            game.hangar = false
            var center: Vector2 = game.port_center(station,port)
            var outward: Vector2 = axis if axis.dot(center-station.p) >= 0 else -axis
            game.pos = center+outward*25
            game.vel = Vector2.ZERO
            game.angle = axis.angle()+PI/2+deg_to_rad(20)
            game.auto_station = -1
            game.auto_ready = 0
            for step in range(300):
                game.update_auto_dock(.1,true)
                if game.hangar: break
                var previous: Vector2 = game.pos
                game.pos += game.vel*.1
                game.station_contact(previous)
            check(game.hangar and game.dock_station == index,"auto ship %d station %d" % [ship,index])
            assisted += 1
    game.selected = 41
    check(int(game.specs[41][11]) == 3 and game.uses_capital_port(),"Ocaso class stays Battleship")
    game.sector = game.stations[0].sector
    game.hangar = false
    game.dock_at(0,0)
    check(game.hangar and game.dock_port >= game.CAPITAL_PORT,"old normal dock remapped")
    # A custom normal port wide enough must remain usable by Ocaso.
    var original: Dictionary = game.stations[0]
    var custom: Dictionary = original.duplicate()
    custom.erase("dock_compatibility")
    custom.dock_mounts = {0:{"size":Vector2(200,100),"offset":Vector2(0,-600),"angle":0.0}}
    custom.ports = 1
    check(game.docking_ports(custom) == [0],"wider custom normal port")
    custom.erase("dock_compatibility")
    custom.ports = 0
    custom.capital_ports = 0
    game.stations[0] = custom
    game.hangar = false
    game.dock_at(0,0)
    check(not game.hangar,"no compatible port handled")
    game.stations[0] = original
    print("DOCKING_REGRESSION ", "PASS" if failures.is_empty() else failures.slice(0,30), " manual=",manual," auto=",assisted)
    game.queue_free()
    quit(0 if failures.is_empty() else 1)
