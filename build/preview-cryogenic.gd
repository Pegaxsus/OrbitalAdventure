extends SceneTree
class PreviewGame extends "res://Godot/game.gd":
    func save_path() -> String: return "user://cryo-preview.json"
func _initialize() -> void: call_deferred("preview")
func preview() -> void:
    var game := PreviewGame.new()
    root.add_child(game)
    game.set_physics_process(false)
    game.hangar = false
    game.selected = 41
    game.hp = game.stat(2)
    for i in range(100):
        if game.sector_specs[i].ice:
            game.enter_sector(i)
            break
    game.cryo_seconds = 420
    game.cryo_sector = game.sector
    game.pos = Vector2.ZERO
    game.zoom = 2
    game.show_sector_stats = true
    for npc in game.npcs: npc.cryo_seconds = 420.0
    game.queue_redraw()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://lore/maps/criogenia-godot-0.1.16.png")
    quit()
