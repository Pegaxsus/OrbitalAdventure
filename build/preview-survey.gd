extends SceneTree
class PreviewGame extends "res://Godot/game.gd":
    func save_path() -> String: return "user://survey-preview.json"
func _initialize() -> void: call_deferred("preview")
func capture(path: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(path)
func preview() -> void:
    var game := PreviewGame.new()
    root.add_child(game)
    game.set_physics_process(false)
    game.hangar = false
    game.enter_sector(29)
    game.pos = Vector2(800,500)
    game.zoom = .8
    game.queue_redraw()
    await capture("res://lore/maps/umbral-0.1.17.png")
    var large: Dictionary = game.fields[29][620]
    game.pos = large.p+Vector2(large.r+80,0)
    game.zoom = .8
    game.queue_redraw()
    await capture("res://lore/maps/gigante-0.1.17.png")
    game.module_types.assign([13])
    game.module_locations.assign([game.utility_location(0,game.selected)])
    game.survey.finish_scan(game)
    game.queue_redraw()
    await capture("res://lore/maps/espectrometro-godot-0.1.17.png")
    game.survey.open = false
    for local in [11,8]:
        game.enter_sector(local)
        game.pos = Vector2.ZERO
        game.zoom = .65
        game.queue_redraw()
        await capture("res://lore/maps/capas-%d-0.1.17.png" % local)
    quit()
