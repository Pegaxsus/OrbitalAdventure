extends SceneTree
class TestGame extends "res://Godot/game.gd":
    func save_path() -> String: return "user://sector-stats-regression.json"
var failures: Array[String] = []
func check(ok: bool, text: String) -> void:
    if not ok: failures.append(text)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var game := TestGame.new()
    root.add_child(game)
    game.set_physics_process(false)
    check(not game.show_sector_stats,"off by default")
    game.console_text = "sector_st"
    game.complete_console()
    check(game.console_text == "sector_stats","complete command")
    game.console_text = "sector_stats "
    game.completion_index = -1
    game.complete_console()
    check(game.console_text == "sector_stats 0","complete zero")
    game.complete_console()
    check(game.console_text == "sector_stats 1","cycle one")
    game.console_command()
    check(game.show_sector_stats,"enabled")
    for local in range(game.sector_specs.size()):
        game.sector = local
        var rows := game.sector_stats_rows()
        var degree := 0
        for link in game.links:
            if local in [link.x,link.y]: degree += 1
        check(rows[0] == "Nombre: "+game.sector_name(local),"name")
        check(rows[1] == "Conexiones (%d):" % degree and rows.size() == degree+4,"connections")
        var alive := 0
        for npc in game.npcs:
            if npc.hp > 0: alive += 1
        check(rows[-2] == "NPCs: %d" % alive,"live NPCs")
        check(rows[-1] == "Fondo: "+str(game.sector_backgrounds[4107+local].id),"background")
    game.console_text = "sector_stats 2"
    game.console_command()
    check(game.show_sector_stats,"invalid state preserved")
    game.queue_redraw()
    await process_frame
    await process_frame
    game.console_text = "sector_stats 0"
    game.console_command()
    check(not game.show_sector_stats,"disabled")
    print("SECTOR_STATS_REGRESSION ","PASS" if failures.is_empty() else failures)
    game.queue_free()
    quit(0 if failures.is_empty() else 1)
