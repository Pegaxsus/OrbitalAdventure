extends SceneTree
class TestGame extends "res://Godot/game.gd":
    func save_path() -> String: return "user://cryogenic-regression.json"
var failures: Array[String] = []
func check(ok: bool, text: String) -> void:
    if not ok: failures.append(text)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var game := TestGame.new()
    root.add_child(game)
    game.set_physics_process(false)
    var cold := -1
    var count := 0
    for i in range(100):
        if game.sector_specs[i].ice:
            cold = i
            count += 1
            check(game.cryogenic_sector(i),"ice profile")
        else: check(not game.cryogenic_sector(i),"only ice")
    check(count == 17,"17 ice sectors")
    game.enter_sector(cold)
    game.hangar = false
    game.module_types.clear()
    game.module_locations.clear()
    var base_speed: float = game.player_cruise_speed()/.9
    for minute in range(10):
        game.cryo_seconds = minute*60.0
        var expected := minf(.8,.1+.1*minute)
        check(is_equal_approx(game.player_cryo_slowdown(),expected),"minute %d" % minute)
        check(is_equal_approx(game.player_cruise_speed(),base_speed*(1-expected)),"speed")
    check(is_equal_approx(game.cryo_slowdown(59.99),.1) and is_equal_approx(game.cryo_slowdown(60),.2),"minute boundary")
    game.module_types.append(12)
    game.module_locations.append(0)
    check(game.player_cryo_slowdown() > 0,"inventory is not immunity")
    game.module_locations[0] = game.utility_location(0,game.selected)
    check(game.player_cryo_slowdown() == 0,"equipped immunity")
    game.module_locations[0] = 0
    check(is_equal_approx(game.player_cryo_slowdown(),.8),"unequip restores effect")
    game.cryo_seconds = 120
    game.save_game()
    game.cryo_seconds = 0
    game.load_game()
    check(game.cryo_seconds == 120 and game.module_types.has(12),"save exposure and module")
    game.hangar = false
    game.reset_traffic()
    game.next_trader = 99999
    game.next_raid = 99999
    for npc in game.npcs:
        npc.cryo_seconds = 420.0
        game.steer_npc(npc,npc.p+Vector2(1000,0),100,1,-1)
        check(npc.v.length() <= 20.001,"NPC speed cap")
        npc.cryo_protected = true
        check(game.npc_cryo_slowdown(npc) == 0,"NPC protection")
    var fresh: Dictionary = game.make_npc("Patrulla",4,Vector2(3000,3000))
    check(is_equal_approx(game.npc_cryo_slowdown(fresh),.1),"new NPC starts at base")
    game.enter_sector(0)
    check(game.cryo_seconds == 0 and game.player_cryo_slowdown() == 0,"leave removes cold")
    game.enter_sector(cold)
    check(is_equal_approx(game.player_cryo_slowdown(),.1),"reenter starts fresh")
    var edge: int = game.route_edge(cold,0)
    var goal: Vector2 = game.gate_position(edge,cold)
    game.freight_ship = {}
    game.freight = {"sector":cold,"destination":0,"kind":2,"amount":1,"hp":100,"x":goal.x+300,"y":goal.y+100,"ftl_wait":0.0,"cryo_seconds":420.0}
    var start := Vector2(game.freight.x,game.freight.y)
    game.update_freight(.1)
    check(absf(start.distance_to(Vector2(game.freight.x,game.freight.y))-1.9) < .002,"freight speed")
    game.freight.x = goal.x
    game.freight.y = goal.y
    game.freight.ftl_wait = 0.0
    game.update_freight(.1)
    check(game.freight.sector != cold and game.freight.cryo_seconds == 0,"freight exit reset")
    game.cryo_seconds = 420
    game.pos = goal
    game.cross_gate()
    check(game.sector != cold and game.cryo_seconds == 0,"gate resets exposure")
    game.enter_sector(cold)
    game.market = 2
    game.dock_station = 0
    game.credits = 1800
    game.object_quantities[12] = 1
    var old_stock: int = game.module_stock[12]
    game.trade(12,true)
    check(game.credits == 0 and game.module_stock[12] == old_stock-1,"purchase")
    check(game.new_station_modules()[11] == 0 and game.new_station_modules()[12] == 2,"market stock")
    game.hangar = false
    game.cryo_seconds = 420
    game.cryo_sector = cold
    game.queue_redraw()
    await process_frame
    await process_frame
    print("CRYOGENIC_REGRESSION ","PASS" if failures.is_empty() else failures)
    game.queue_free()
    quit(0 if failures.is_empty() else 1)
