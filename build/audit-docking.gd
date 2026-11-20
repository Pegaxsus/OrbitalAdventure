extends SceneTree
class AuditGame extends "res://Godot/game.gd":
    func save_path() -> String: return "user://dock-audit.json"
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var game := AuditGame.new()
    root.add_child(game)
    game.set_physics_process(false)
    var failures: Array = []
    for ship in range(46):
        game.selected = ship
        for index in range(game.stations.size()):
            var station: Dictionary = game.stations[index]
            game.sector = station.sector
            var candidates := game.docking_ports(station)
            var best := 0.0
            var clean := 0
            for port in candidates:
                var axis: Vector2 = game.port_axis(port,station)
                game.angle = axis.angle()+PI/2
                game.pos = game.port_center(station,port)
                var coverage := game.dock_coverage(Vector2.ZERO,axis,game.port_dimensions(port,station))
                best = maxf(best,coverage)
                if coverage >= .89999:
                    game.vel = Vector2.ZERO
                    if not game.station_contact(game.pos-Vector2.ONE): clean += 1
            if best < .89999 or clean == 0:
                failures.append({"ship":ship,"name":game.specs[ship][9],"station":index,"ports":candidates,"best":best,"collision_free":clean})
    print("DOCK_AUDIT ",JSON.stringify(failures))
    var file := FileAccess.open("res://build/.docking-audit.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(failures,"\t"))
    game.queue_free()
    quit()
